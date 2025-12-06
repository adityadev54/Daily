using System.ComponentModel.DataAnnotations;
using MealKit.Models;

namespace MealKit.Requests;

/// <summary>
/// Collects consumer preferences before we ask the AI to craft a plan.
/// </summary>
public class GenerateMealPlanRequest
{
    [Required]
    [Range(10, 110)]
    public int Age { get; set; }

    [Required]
    public string Gender { get; set; } = string.Empty;

    [Required]
    [Range(70, 700)]
    public double WeightInLbs { get; set; }

    [Required]
    [Range(4, 7)]
    public int HeightFeet { get; set; } = 5;

    [Required]
    [Range(0, 11)]
    public int HeightInches { get; set; } = 6;

    [Required]
    public string TimeZoneId { get; set; } = "UTC";

    [Required]
    public string FitnessGoal { get; set; } = string.Empty;

    [Required]
    public string DietaryPreference { get; set; } = string.Empty;

    public string NutritionFocus { get; set; } = string.Empty;

    public List<string> Allergies { get; set; } = new();

    public List<string> CuisinePreferences { get; set; } = new();

    [Range(1, 6)]
    public int MealsPerDay { get; set; } = 3;

    [Range(25, 2000)]
    public decimal WeeklyBudget { get; set; } = 150;

    public string CookingSkillLevel { get; set; } = string.Empty;

    public string TimeAvailability { get; set; } = string.Empty;

    public List<string> HealthConditions { get; set; } = new();

    public List<string> FoodsToAvoid { get; set; } = new();

    public List<string> FavoriteIngredients { get; set; } = new();

    public List<string> DislikedIngredients { get; set; } = new();

    public List<string> SnackPreferences { get; set; } = new();

    public string HydrationGoal { get; set; } = "2L daily";

    public List<string> SupplementPreferences { get; set; } = new();

    public string EatingSchedule { get; set; } = string.Empty;

    public string CulturalNotes { get; set; } = string.Empty;

    public string SeasonalFocus { get; set; } = string.Empty;

    public string LifestyleNotes { get; set; } = string.Empty;

    public DateTime StartDate { get; set; } = DateTime.UtcNow.Date;

    public string Title { get; set; } = string.Empty;

    public MealPreferences ToPreferences()
    {
        return new MealPreferences
        {
            AgeRange = $"{Age} years",
            Gender = Gender,
            WeightInLbs = WeightInLbs,
            HeightFeet = HeightFeet,
            HeightInches = HeightInches,
            TimeZoneId = TimeZoneId,
            FitnessGoal = FitnessGoal,
            DietaryPreference = DietaryPreference,
            NutritionFocus = NutritionFocus,
            Allergies = Allergies,
            CuisinePreferences = CuisinePreferences,
            MealsPerDay = MealsPerDay,
            WeeklyBudget = WeeklyBudget,
            CookingSkillLevel = CookingSkillLevel,
            TimeAvailability = TimeAvailability,
            HealthConditions = HealthConditions,
            FoodsToAvoid = FoodsToAvoid,
            FavoriteIngredients = FavoriteIngredients,
            DislikedIngredients = DislikedIngredients,
            SnackPreferences = SnackPreferences,
            HydrationGoal = HydrationGoal,
            SupplementPreferences = SupplementPreferences,
            EatingSchedule = EatingSchedule,
            CulturalNotes = CulturalNotes,
            SeasonalFocus = SeasonalFocus,
            LifestyleNotes = LifestyleNotes
        };
    }
}
