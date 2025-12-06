using MealKit.Models;

namespace MealKit.Requests;

/// <summary>
/// Allow clients to adjust details after AI generation.
/// </summary>
public class UpdateMealPlanRequest
{
    public string Title { get; set; } = string.Empty;

    public DateTime? StartDate { get; set; }

    public string? TimeZoneId { get; set; }

    public List<MealDay>? Days { get; set; }

    public MealPlanMeta? Meta { get; set; }

    public ShoppingPlanner? Shopping { get; set; }

    public BudgetPlanner? Budget { get; set; }

    public PrepScheduler? Prep { get; set; }

    public PantrySnapshot? Pantry { get; set; }

    public List<string>? CookingTips { get; set; }
}
