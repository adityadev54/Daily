using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using Npgsql;

namespace MealKit.Services.Database.Migrations;

public class SqlMigrationRunner
{
    private const string CheckpointTable = "schema_migrations";

    private readonly NpgsqlDataSource _dataSource;
    private readonly IEnumerable<ISqlMigration> _migrations;
    private readonly ILogger<SqlMigrationRunner> _logger;

    public SqlMigrationRunner(NpgsqlDataSource dataSource, IEnumerable<ISqlMigration> migrations, ILogger<SqlMigrationRunner> logger)
    {
        _dataSource = dataSource;
        _migrations = migrations;
        _logger = logger;
    }

    public async Task RunAsync(CancellationToken cancellationToken = default)
    {
        if (_migrations is null || !_migrations.Any())
        {
            return;
        }

        await EnsureCheckpointTableAsync(cancellationToken);

        await using var connection = await _dataSource.OpenConnectionAsync(cancellationToken);
        var applied = new HashSet<string>();

        var selectCommand = new NpgsqlCommand($"select id from {CheckpointTable};", connection);
        await using (var reader = await selectCommand.ExecuteReaderAsync(cancellationToken))
        {
            while (await reader.ReadAsync(cancellationToken))
            {
                applied.Add(reader.GetString(0));
            }
        }

        foreach (var migration in _migrations.OrderBy(m => m.Id))
        {
            if (applied.Contains(migration.Id))
            {
                continue;
            }

            _logger.LogInformation("Running migration {MigrationId}: {Description}", migration.Id, migration.Description);
            await migration.ApplyAsync(_dataSource, cancellationToken);

            var insertCommand = new NpgsqlCommand($"insert into {CheckpointTable} (id, description, applied_at) values (@id, @description, now());", connection);
            insertCommand.Parameters.AddWithValue("@id", migration.Id);
            insertCommand.Parameters.AddWithValue("@description", migration.Description);
            await insertCommand.ExecuteNonQueryAsync(cancellationToken);
            _logger.LogInformation("Migration {MigrationId} complete", migration.Id);
        }
    }

    private async Task EnsureCheckpointTableAsync(CancellationToken cancellationToken)
    {
        await using var connection = await _dataSource.OpenConnectionAsync(cancellationToken);
        var command = new NpgsqlCommand($@"
            create table if not exists {CheckpointTable}
            (
                id text primary key,
                description text not null,
                applied_at timestamptz not null
            );
        ", connection);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }
}
