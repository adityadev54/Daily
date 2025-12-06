namespace MealKit.Core.Settings;

public class OpenRouterSettings
{
    public string BaseUrl { get; set; } = "https://openrouter.ai/api/v1";
    public string Model { get; set; } = "mistralai/mistral-7b-instruct:free";
    public string ApiKey { get; set; } = string.Empty;
    public int TimeoutSeconds { get; set; } = 0;
    public bool UseFallbackPlan { get; set; } = true;
}
