using System.Threading;
using System.Threading.Tasks;
using Npgsql;

namespace MealKit.Services.Database.Migrations;

public interface ISqlMigration
{
    string Id { get; }

    string Description { get; }

    Task ApplyAsync(NpgsqlDataSource dataSource, CancellationToken cancellationToken);
}
