using System.Threading;
using System.Threading.Tasks;
using Npgsql;

namespace MealKit.Services.Database.Migrations;

public class CreateMealPlansTableMigration : ISqlMigration
{
    public string Id => "20241029_create_meal_plans";

    public string Description => "Create meal_plans table for storing AI generated plans.";

    public async Task ApplyAsync(NpgsqlDataSource dataSource, CancellationToken cancellationToken)
    {
        await using var connection = await dataSource.OpenConnectionAsync(cancellationToken);
        var command = new NpgsqlCommand(@"
            create table if not exists meal_plans
            (
                id uuid primary key,
                title text not null,
                start_date date not null,
                time_zone_id text not null,
                primary_focus text not null default '',
                estimated_budget numeric(10,2) not null default 0,
                payload jsonb not null,
                created_at timestamptz not null,
                updated_at timestamptz not null
            );

            create index if not exists idx_meal_plans_created_at on meal_plans (created_at desc);
        ", connection);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }
}
