namespace MealKit.Models;

/// <summary>
/// Represents a weekly meal plan that we store and share over the API.
/// The document stays flexible enough for AI generated content while remaining easy to query.
/// </summary>
public class MealPlanDocument
{
    public Guid Id { get; set; }

    public string Title { get; set; } = string.Empty;

    public DateTime StartDate { get; set; } = DateTime.UtcNow.Date;

    public string TimeZoneId { get; set; } = "UTC";

    public MealPreferences Preferences { get; set; } = new();

    public List<MealDay> Days { get; set; } = new();

    public MealPlanMeta Meta { get; set; } = new();

    public ShoppingPlanner Shopping { get; set; } = new();

    public BudgetPlanner Budget { get; set; } = new();

    public PrepScheduler Prep { get; set; } = new();

    public PantrySnapshot Pantry { get; set; } = new();

    public List<string> CookingTips { get; set; } = new();

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}

public class MealPreferences
{
    public string AgeRange { get; set; } = string.Empty;

    public string Gender { get; set; } = string.Empty;

    public double WeightInLbs { get; set; }

    public int HeightFeet { get; set; }

    public int HeightInches { get; set; }

    public string TimeZoneId { get; set; } = "UTC";

    public string FitnessGoal { get; set; } = string.Empty;

    public string DietaryPreference { get; set; } = string.Empty;

    public string NutritionFocus { get; set; } = string.Empty;

    public List<string> Allergies { get; set; } = new();

    public List<string> CuisinePreferences { get; set; } = new();

    public int MealsPerDay { get; set; } = 3;

    public decimal WeeklyBudget { get; set; }

    public string CookingSkillLevel { get; set; } = string.Empty;

    public string TimeAvailability { get; set; } = string.Empty;

    public List<string> HealthConditions { get; set; } = new();

    public List<string> FoodsToAvoid { get; set; } = new();

    public List<string> FavoriteIngredients { get; set; } = new();

    public List<string> DislikedIngredients { get; set; } = new();

    public List<string> SnackPreferences { get; set; } = new();

    public string HydrationGoal { get; set; } = string.Empty;

    public List<string> SupplementPreferences { get; set; } = new();

    public string EatingSchedule { get; set; } = string.Empty;

    public string CulturalNotes { get; set; } = string.Empty;

    public string SeasonalFocus { get; set; } = string.Empty;

    public string LifestyleNotes { get; set; } = string.Empty;
}

public class MealDay
{
    public string Day { get; set; } = string.Empty;

    public List<PlannedMeal> Meals { get; set; } = new();

    public List<string> Snacks { get; set; } = new();

    public string HydrationReminder { get; set; } = string.Empty;

    public string MovementReminder { get; set; } = string.Empty;
}

public class PlannedMeal
{
    public string Type { get; set; } = string.Empty;

    public string Name { get; set; } = string.Empty;

    public string Description { get; set; } = string.Empty;

    public List<string> Ingredients { get; set; } = new();

    public List<string> Instructions { get; set; } = new();

    public MealNutrition Nutrition { get; set; } = new();
}

public class MealNutrition
{
    public double Calories { get; set; }

    public double Protein { get; set; }

    public double Carbs { get; set; }

    public double Fat { get; set; }

    public Dictionary<string, double> Micros { get; set; } = new();
}

public class MealPlanMeta
{
    public string Summary { get; set; } = string.Empty;

    public string PrimaryFocus { get; set; } = string.Empty;

    public Dictionary<string, string> DailyHighlights { get; set; } = new();

    public MealNutrition WeeklyTotals { get; set; } = new();
}

public class ShoppingPlanner
{
    public List<ShoppingItem> Items { get; set; } = new();

    public List<string> PantryChecks { get; set; } = new();

    public List<string> BatchCookingIdeas { get; set; } = new();
}

public class ShoppingItem
{
    public string Name { get; set; } = string.Empty;

    public string Category { get; set; } = string.Empty;

    public string Quantity { get; set; } = string.Empty;

    public bool Optional { get; set; }
}

public class BudgetPlanner
{
    public decimal EstimatedTotal { get; set; }

    public Dictionary<string, decimal> CategoryTotals { get; set; } = new();

    public string SavingsTip { get; set; } = string.Empty;
}

public class PrepScheduler
{
    public List<string> WeekendPrep { get; set; } = new();

    public List<string> DailyQuickPrep { get; set; } = new();

    public List<string> LeftoverIdeas { get; set; } = new();
}

public class PantrySnapshot
{
    public List<string> PantryItems { get; set; } = new();

    public List<string> LowStockAlerts { get; set; } = new();

    public List<string> IngredientSwaps { get; set; } = new();
}
