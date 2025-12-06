using MealKit.Models;

namespace MealKit.Responses;

public record MealPlanSummaryResponse(
    string Id,
    string Title,
    DateTime StartDate,
    string PrimaryFocus,
    decimal EstimatedBudget,
    int DayCount
)
{
    public static MealPlanSummaryResponse FromDocument(MealPlanDocument doc)
    {
        return new MealPlanSummaryResponse(
            doc.Id.ToString(),
            string.IsNullOrWhiteSpace(doc.Title) ? "Weekly Meal Plan" : doc.Title,
            doc.StartDate,
            doc.Meta?.PrimaryFocus ?? string.Empty,
            doc.Budget?.EstimatedTotal ?? 0,
            doc.Days.Count
        );
    }
}
