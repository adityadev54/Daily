using System.Net.Http.Headers;
using System.Text.Json;
using MealKit.Core.Settings;
using MealKit.Services.Ai;
using MealKit.Services.Database;
using MealKit.Services.Database.Migrations;
using Microsoft.Extensions.Options;
using Npgsql;

var builder = WebApplication.CreateBuilder(args);

builder.Services.Configure<DatabaseSettings>(builder.Configuration.GetSection("Database"));
builder.Services.Configure<OpenRouterSettings>(builder.Configuration.GetSection("OpenRouter"));

builder.Services.AddSingleton(sp =>
{
	var options = sp.GetRequiredService<IOptions<DatabaseSettings>>().Value;
	if (string.IsNullOrWhiteSpace(options.ConnectionString))
	{
		throw new InvalidOperationException("Database connection string is missing. Update Database:ConnectionString in appsettings.");
	}

	return NpgsqlDataSource.Create(options.ConnectionString);
});

builder.Services.AddSingleton<MealPlanRepository>();
builder.Services.AddSingleton<ISqlMigration, CreateMealPlansTableMigration>();
builder.Services.AddSingleton<SqlMigrationRunner>();

builder.Services.AddHttpClient<AiMealPlannerService>((sp, client) =>
{
	var settings = sp.GetRequiredService<IOptions<OpenRouterSettings>>().Value;
	var baseUrl = settings.BaseUrl.EndsWith('/') ? settings.BaseUrl : settings.BaseUrl + "/";
	client.BaseAddress = new Uri(baseUrl);
	client.Timeout = settings.TimeoutSeconds <= 0
		? System.Threading.Timeout.InfiniteTimeSpan
		: TimeSpan.FromSeconds(settings.TimeoutSeconds);
	client.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
});

builder.Services.AddControllers().AddJsonOptions(options =>
{
	options.JsonSerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase;
	options.JsonSerializerOptions.DefaultIgnoreCondition = System.Text.Json.Serialization.JsonIgnoreCondition.WhenWritingNull;
});

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

var migrationRunner = app.Services.GetRequiredService<SqlMigrationRunner>();
await migrationRunner.RunAsync();

if (app.Environment.IsDevelopment())
{
	app.UseSwagger();
	app.UseSwaggerUI();
}

app.MapControllers();

app.MapGet("/", () => "Meal Kit API is alive. Ready to cook.");

await app.RunAsync();
