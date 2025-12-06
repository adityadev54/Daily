using System.Text.Json;
using MealKit.Models;
using Npgsql;
using NpgsqlTypes;

namespace MealKit.Services.Database;

/// <summary>
/// Handles Supabase/Postgres access so controllers stay clean and focused on flow.
/// </summary>
public class MealPlanRepository
{
    private static readonly JsonSerializerOptions SerializerOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        DefaultIgnoreCondition = System.Text.Json.Serialization.JsonIgnoreCondition.WhenWritingNull,
        WriteIndented = false
    };

    private readonly NpgsqlDataSource _dataSource;

    public MealPlanRepository(NpgsqlDataSource dataSource)
    {
        _dataSource = dataSource;
    }

    public async Task<List<MealPlanDocument>> GetAsync(CancellationToken cancellationToken)
    {
        const string sql = "select id, payload from meal_plans order by created_at desc";

        await using var connection = await _dataSource.OpenConnectionAsync(cancellationToken);
        await using var command = new NpgsqlCommand(sql, connection);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);

        var plans = new List<MealPlanDocument>();

        while (await reader.ReadAsync(cancellationToken))
        {
            var id = reader.GetGuid(0);
            var payload = reader.GetFieldValue<string>(1);
            var doc = JsonSerializer.Deserialize<MealPlanDocument>(payload, SerializerOptions);
            if (doc is null)
            {
                continue;
            }

            doc.Id = id;
            plans.Add(doc);
        }

        return plans;
    }

    public async Task<MealPlanDocument?> GetAsync(Guid id, CancellationToken cancellationToken)
    {
        const string sql = "select payload from meal_plans where id = @id limit 1";

        await using var connection = await _dataSource.OpenConnectionAsync(cancellationToken);
        await using var command = new NpgsqlCommand(sql, connection);
        command.Parameters.AddWithValue("@id", id);

        var payload = await command.ExecuteScalarAsync(cancellationToken) as string;
        if (payload is null)
        {
            return null;
        }

        var doc = JsonSerializer.Deserialize<MealPlanDocument>(payload, SerializerOptions);
        if (doc is null)
        {
            return null;
        }

        doc.Id = id;
        return doc;
    }

    public async Task InsertAsync(MealPlanDocument document, CancellationToken cancellationToken)
    {
        document.Id = document.Id == Guid.Empty ? Guid.NewGuid() : document.Id;
        document.CreatedAt = DateTime.UtcNow;
        document.UpdatedAt = document.CreatedAt;
        document.Meta ??= new MealPlanMeta();
        document.Budget ??= new BudgetPlanner();

        var payload = JsonSerializer.Serialize(document, SerializerOptions);

        const string sql = @"
            insert into meal_plans
            (id, title, start_date, time_zone_id, primary_focus, estimated_budget, payload, created_at, updated_at)
            values
            (@id, @title, @startDate, @timeZoneId, @primaryFocus, @estimatedBudget, @payload, @createdAt, @updatedAt);
        ";

        await using var connection = await _dataSource.OpenConnectionAsync(cancellationToken);
        await using var command = new NpgsqlCommand(sql, connection);
        command.Parameters.AddWithValue("@id", document.Id);
        command.Parameters.AddWithValue("@title", document.Title);
        command.Parameters.AddWithValue("@startDate", document.StartDate);
        command.Parameters.AddWithValue("@timeZoneId", document.TimeZoneId);
        command.Parameters.AddWithValue("@primaryFocus", document.Meta.PrimaryFocus ?? string.Empty);
        command.Parameters.AddWithValue("@estimatedBudget", document.Budget.EstimatedTotal);
        command.Parameters.AddWithValue("@createdAt", document.CreatedAt);
        command.Parameters.AddWithValue("@updatedAt", document.UpdatedAt);
        command.Parameters.Add("@payload", NpgsqlDbType.Jsonb).Value = payload;

        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    public async Task<bool> UpdateAsync(Guid id, Action<MealPlanDocument> apply, CancellationToken cancellationToken)
    {
        var existing = await GetAsync(id, cancellationToken);
        if (existing is null)
        {
            return false;
        }

        apply(existing);
        existing.UpdatedAt = DateTime.UtcNow;
        existing.Meta ??= new MealPlanMeta();
        existing.Budget ??= new BudgetPlanner();

        var payload = JsonSerializer.Serialize(existing, SerializerOptions);

        const string sql = @"
            update meal_plans
            set title = @title,
                start_date = @startDate,
                time_zone_id = @timeZoneId,
                primary_focus = @primaryFocus,
                estimated_budget = @estimatedBudget,
                payload = @payload,
                updated_at = @updatedAt
            where id = @id;
        ";

        await using var connection = await _dataSource.OpenConnectionAsync(cancellationToken);
        await using var command = new NpgsqlCommand(sql, connection);
        command.Parameters.AddWithValue("@id", existing.Id);
        command.Parameters.AddWithValue("@title", existing.Title);
        command.Parameters.AddWithValue("@startDate", existing.StartDate);
        command.Parameters.AddWithValue("@timeZoneId", existing.TimeZoneId);
        command.Parameters.AddWithValue("@primaryFocus", existing.Meta.PrimaryFocus ?? string.Empty);
        command.Parameters.AddWithValue("@estimatedBudget", existing.Budget.EstimatedTotal);
        command.Parameters.AddWithValue("@updatedAt", existing.UpdatedAt);
        command.Parameters.Add("@payload", NpgsqlDbType.Jsonb).Value = payload;

        var rows = await command.ExecuteNonQueryAsync(cancellationToken);
        return rows > 0;
    }

    public async Task<bool> DeleteAsync(Guid id, CancellationToken cancellationToken)
    {
        const string sql = "delete from meal_plans where id = @id";

        await using var connection = await _dataSource.OpenConnectionAsync(cancellationToken);
        await using var command = new NpgsqlCommand(sql, connection);
        command.Parameters.AddWithValue("@id", id);

        var rows = await command.ExecuteNonQueryAsync(cancellationToken);
        return rows > 0;
    }
}
