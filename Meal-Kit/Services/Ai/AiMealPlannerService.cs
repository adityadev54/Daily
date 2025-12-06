using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using MealKit.Core.Settings;
using MealKit.Models;
using MealKit.Requests;
using Microsoft.Extensions.Options;

namespace MealKit.Services.Ai;

/// <summary>
/// Talks to OpenRouter models to craft the AI-powered meal plans and helpers.
/// </summary>
public class AiMealPlannerService
{
    private const int MaxOutputTokens = 2200;
    private static readonly string[] MealTypes = new[] { "Breakfast", "Lunch", "Dinner" };

    private static readonly object ResponseFormat = new
    {
        type = "json_schema",
        json_schema = new
        {
            name = "meal_plan",
            schema = new
            {
                type = "object",
                additionalProperties = false,
                required = new[] { "title", "days", "meta", "shopping", "budget", "prep", "pantry", "tips" },
                properties = new
                {
                    title = new { type = "string" },
                    days = new
                    {
                        type = "array",
                        minItems = 7,
                        maxItems = 7,
                        items = new
                        {
                            type = "object",
                            additionalProperties = false,
                            required = new[] { "day", "meals", "snacks", "hydrationReminder", "movementReminder" },
                            properties = new
                            {
                                day = new { type = "string" },
                                meals = new
                                {
                                    type = "array",
                                    minItems = 3,
                                    maxItems = 3,
                                    items = new
                                    {
                                        type = "object",
                                        additionalProperties = false,
                                        required = new[] { "type", "name", "description", "ingredients", "instructions", "nutrition" },
                                        properties = new
                                        {
                                            type = new { type = "string", @enum = MealTypes },
                                            name = new { type = "string" },
                                            description = new { type = "string" },
                                            ingredients = new
                                            {
                                                type = "array",
                                                items = new { type = "string" },
                                                minItems = 3,
                                                maxItems = 6
                                            },
                                            instructions = new
                                            {
                                                type = "array",
                                                items = new { type = "string" },
                                                minItems = 2,
                                                maxItems = 4
                                            },
                                            nutrition = new
                                            {
                                                type = "object",
                                                additionalProperties = false,
                                                required = new[] { "calories", "protein", "carbs", "fat", "micros" },
                                                properties = new
                                                {
                                                    calories = new { type = "number" },
                                                    protein = new { type = "number" },
                                                    carbs = new { type = "number" },
                                                    fat = new { type = "number" },
                                                    micros = new
                                                    {
                                                        type = "object",
                                                        minProperties = 1,
                                                        additionalProperties = new { type = "number" }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                },
                                snacks = new
                                {
                                    type = "array",
                                    items = new { type = "string" },
                                    minItems = 1,
                                    maxItems = 4
                                },
                                hydrationReminder = new { type = "string" },
                                movementReminder = new { type = "string" }
                            }
                        }
                    },
                    meta = new
                    {
                        type = "object",
                        additionalProperties = false,
                        required = new[] { "summary", "primaryFocus", "dailyHighlights", "weeklyTotals" },
                        properties = new
                        {
                            summary = new { type = "string" },
                            primaryFocus = new { type = "string" },
                            dailyHighlights = new
                            {
                                type = "object",
                                minProperties = 7,
                                additionalProperties = new { type = "string" }
                            },
                            weeklyTotals = new
                            {
                                type = "object",
                                additionalProperties = false,
                                required = new[] { "calories", "protein", "carbs", "fat", "micros" },
                                properties = new
                                {
                                    calories = new { type = "number" },
                                    protein = new { type = "number" },
                                    carbs = new { type = "number" },
                                    fat = new { type = "number" },
                                    micros = new
                                    {
                                        type = "object",
                                        minProperties = 3,
                                        additionalProperties = new { type = "number" }
                                    }
                                }
                            }
                        }
                    },
                    shopping = new
                    {
                        type = "object",
                        additionalProperties = false,
                        required = new[] { "items", "pantryChecks", "batchCookingIdeas" },
                        properties = new
                        {
                            items = new
                            {
                                type = "array",
                                minItems = 12,
                                maxItems = 40,
                                items = new
                                {
                                    type = "object",
                                    additionalProperties = false,
                                    required = new[] { "name", "category", "quantity", "optional" },
                                    properties = new
                                    {
                                        name = new { type = "string" },
                                        category = new { type = "string" },
                                        quantity = new { type = "string" },
                                        optional = new { type = "boolean" }
                                    }
                                }
                            },
                            pantryChecks = new
                            {
                                type = "array",
                                items = new { type = "string" },
                                minItems = 3,
                                maxItems = 5
                            },
                            batchCookingIdeas = new
                            {
                                type = "array",
                                items = new { type = "string" },
                                minItems = 2,
                                maxItems = 3
                            }
                        }
                    },
                    budget = new
                    {
                        type = "object",
                        additionalProperties = false,
                        required = new[] { "estimatedTotal", "categoryTotals", "savingsTip" },
                        properties = new
                        {
                            estimatedTotal = new { type = "number" },
                            categoryTotals = new
                            {
                                type = "object",
                                minProperties = 3,
                                additionalProperties = new { type = "number" }
                            },
                            savingsTip = new { type = "string" }
                        }
                    },
                    prep = new
                    {
                        type = "object",
                        additionalProperties = false,
                        required = new[] { "weekendPrep", "dailyQuickPrep", "leftoverIdeas" },
                        properties = new
                        {
                            weekendPrep = new
                            {
                                type = "array",
                                items = new { type = "string" },
                                minItems = 3,
                                maxItems = 4
                            },
                            dailyQuickPrep = new
                            {
                                type = "array",
                                items = new { type = "string" },
                                minItems = 2,
                                maxItems = 4
                            },
                            leftoverIdeas = new
                            {
                                type = "array",
                                items = new { type = "string" },
                                minItems = 2,
                                maxItems = 4
                            }
                        }
                    },
                    pantry = new
                    {
                        type = "object",
                        additionalProperties = false,
                        required = new[] { "pantryItems", "lowStockAlerts", "ingredientSwaps" },
                        properties = new
                        {
                            pantryItems = new
                            {
                                type = "array",
                                items = new { type = "string" },
                                minItems = 5,
                                maxItems = 10
                            },
                            lowStockAlerts = new
                            {
                                type = "array",
                                items = new { type = "string" },
                                minItems = 2,
                                maxItems = 5
                            },
                            ingredientSwaps = new
                            {
                                type = "array",
                                items = new { type = "string" },
                                minItems = 2,
                                maxItems = 5
                            }
                        }
                    },
                    tips = new
                    {
                        type = "array",
                        items = new { type = "string" },
                        minItems = 3,
                        maxItems = 6
                    }
                }
            }
        }
    };

    private static readonly MealTemplate[] BreakfastTemplates =
    {
        new(
            "Garden Veggie Scramble",
            "Egg scramble with seasonal vegetables and herbs.",
            new[] { "Eggs", "Spinach", "Cherry tomatoes", "Fresh herbs", "Whole grain toast" },
            new[] { "Saute spinach and tomatoes with olive oil.", "Whisk eggs with herbs and cook until just set.", "Serve with toasted whole grain bread." },
            420, 28, 38, 18
        ),
        new(
            "Protein Oat Bowl",
            "Warm oats topped with nut butter and fruit.",
            new[] { "Rolled oats", "Almond milk", "Chia seeds", "Banana", "Almond butter" },
            new[] { "Simmer oats with almond milk until creamy.", "Stir in chia seeds for extra fiber.", "Top with sliced banana and almond butter." },
            390, 17, 52, 14
        ),
        new(
            "Greek Yogurt Parfait",
            "Creamy yogurt layered with fruit and crunch.",
            new[] { "Plain Greek yogurt", "Mixed berries", "Granola", "Honey", "Pumpkin seeds" },
            new[] { "Layer yogurt and berries in a glass.", "Sprinkle granola and pumpkin seeds between layers.", "Finish with a light drizzle of honey." },
            360, 24, 42, 11
        )
    };

    private static readonly MealTemplate[] LunchTemplates =
    {
        new(
            "Roasted Veggie Grain Bowl",
            "Foundation of grains topped with hearty roasted vegetables.",
            new[] { "Quinoa", "Roasted sweet potato", "Chickpeas", "Kale", "Lemon tahini sauce" },
            new[] { "Cook quinoa until fluffy.", "Roast sweet potato and chickpeas with spices.", "Massage kale with lemon tahini sauce and assemble the bowl." },
            540, 22, 68, 18
        ),
        new(
            "Mediterranean Pita Stack",
            "Layered pita with hummus and crisp produce.",
            new[] { "Whole wheat pita", "Hummus", "Cucumber", "Cherry tomatoes", "Feta", "Olives" },
            new[] { "Warm pita and spread with hummus.", "Top with chopped cucumber, tomatoes, olives, and feta.", "Finish with a squeeze of lemon." },
            480, 20, 54, 18
        ),
        new(
            "Hearty Lentil Soup",
            "Comforting soup packed with legumes and vegetables.",
            new[] { "Green lentils", "Carrots", "Celery", "Vegetable broth", "Bay leaf" },
            new[] { "Saute aromatics in olive oil.", "Add lentils, broth, and bay leaf then simmer until tender.", "Season to taste and serve with a squeeze of lemon." },
            410, 24, 48, 10
        )
    };

    private static readonly MealTemplate[] DinnerTemplates =
    {
        new(
            "Tofu Stir-Fry",
            "Quick stir-fry with colorful vegetables and tofu.",
            new[] { "Firm tofu", "Broccoli florets", "Bell peppers", "Snap peas", "Brown rice", "Soy-ginger sauce" },
            new[] { "Press and cube tofu then sear until golden.", "Stir-fry vegetables until crisp-tender.", "Toss with sauce and serve over cooked brown rice." },
            560, 32, 62, 18
        ),
        new(
            "Stuffed Portobello Caps",
            "Portobello mushrooms filled with quinoa and greens.",
            new[] { "Portobello caps", "Quinoa", "Spinach", "Sun-dried tomatoes", "Goat cheese" },
            new[] { "Roast the mushroom caps until tender.", "Combine cooked quinoa with sauteed spinach and tomatoes.", "Fill caps, crumble goat cheese on top, and bake briefly." },
            500, 24, 44, 22
        ),
        new(
            "Coconut Chickpea Curry",
            "Comforting curry finished with coconut milk and lime.",
            new[] { "Chickpeas", "Coconut milk", "Diced tomatoes", "Spinach", "Brown basmati rice" },
            new[] { "Simmer aromatics with curry spices.", "Add chickpeas, tomatoes, and coconut milk then cook until thickened.", "Fold in spinach and serve over rice." },
            540, 18, 66, 20
        )
    };

    private static readonly JsonSerializerOptions SerializerOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        PropertyNameCaseInsensitive = true,
        WriteIndented = false,
        NumberHandling = JsonNumberHandling.AllowReadingFromString,
        Converters = { new FlexibleStringConverter(), new FlexibleDecimalDictionaryConverter() }
    };

    private readonly HttpClient _httpClient;
    private readonly OpenRouterSettings _settings;
    private readonly ILogger<AiMealPlannerService> _logger;

    public AiMealPlannerService(HttpClient httpClient, IOptions<OpenRouterSettings> openRouterOptions, ILogger<AiMealPlannerService> logger)
    {
        _httpClient = httpClient;
        _settings = openRouterOptions.Value;
        _logger = logger;
    }

    public async Task<MealPlanDocument?> GeneratePlanAsync(GenerateMealPlanRequest request, CancellationToken cancellationToken)
    {
        EnsureApiKey();

        var envelope = new
        {
            model = _settings.Model,
            response_format = ResponseFormat,
            temperature = 0.6,
            max_output_tokens = MaxOutputTokens,
            messages = new object[]
            {
                new { role = "system", content = BuildSystemPrompt() },
                new { role = "user", content = BuildUserPrompt(request) }
            }
        };

        using var httpRequest = new HttpRequestMessage(HttpMethod.Post, "chat/completions")
        {
            Content = JsonContent.Create(envelope)
        };

        httpRequest.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", _settings.ApiKey);
        httpRequest.Headers.Add("HTTP-Referer", "https://github.com/meal-kit");
        httpRequest.Headers.Add("X-Title", "Meal Kit Planner");

        _logger.LogInformation("Requesting OpenRouter model {Model}", _settings.Model);

        try
        {
            using var response = await _httpClient.SendAsync(httpRequest, cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                var body = await response.Content.ReadAsStringAsync(cancellationToken);
                _logger.LogWarning("OpenRouter returned {Status}: {Body}", response.StatusCode, body);
                return CreateFallbackPlan(request, $"OpenRouter status {response.StatusCode}");
            }

            var mediaType = response.Content.Headers.ContentType?.MediaType ?? string.Empty;
            var responseBody = await response.Content.ReadAsStringAsync(cancellationToken);

            if (!mediaType.Contains("json", StringComparison.OrdinalIgnoreCase))
            {
                _logger.LogWarning("OpenRouter returned non-JSON content type {ContentType}: {Preview}", mediaType, Preview(responseBody));
                return CreateFallbackPlan(request, "Non JSON response");
            }

            OpenRouterCompletion? completion;
            try
            {
                completion = JsonSerializer.Deserialize<OpenRouterCompletion>(responseBody, SerializerOptions);
            }
            catch (JsonException ex)
            {
                _logger.LogWarning(ex, "Unable to parse OpenRouter response: {Preview}", Preview(responseBody));
                return CreateFallbackPlan(request, "Parse failure");
            }

            if (completion?.Choices is null || completion.Choices.Length == 0)
            {
                return CreateFallbackPlan(request, "Missing choices");
            }

            var rawContent = completion.Choices[0].Message.Content;
            if (string.IsNullOrWhiteSpace(rawContent))
            {
                return CreateFallbackPlan(request, "Empty content");
            }

            try
            {
                var draft = JsonSerializer.Deserialize<AiMealPlanDraft>(rawContent, SerializerOptions);
                if (draft is null)
                {
                    return CreateFallbackPlan(request, "Null draft");
                }

                _logger.LogInformation("AI meal plan preview: {Preview}", Preview(rawContent));

                return MapDraftToDocument(draft, request);
            }
            catch (JsonException ex)
            {
                _logger.LogWarning(ex, "Unable to parse AI meal plan payload");
                return CreateFallbackPlan(request, "Draft parse failure");
            }
        }
        catch (TaskCanceledException ex) when (!cancellationToken.IsCancellationRequested)
        {
            var timeout = _settings.TimeoutSeconds <= 0 ? "infinite" : $"{_settings.TimeoutSeconds} seconds";
            _logger.LogWarning(ex, "OpenRouter request timed out after {Timeout}.", timeout);
            return CreateFallbackPlan(request, "Timeout");
        }
        catch (HttpRequestException ex)
        {
            _logger.LogWarning(ex, "OpenRouter request failed");
            return CreateFallbackPlan(request, "Network failure");
        }
    }

    private static string Preview(string? content)
    {
        if (string.IsNullOrWhiteSpace(content))
        {
            return string.Empty;
        }

        var trimmed = content.Trim();
        return trimmed.Length <= 200 ? trimmed : trimmed[..200] + "…";
    }

    private MealPlanDocument? CreateFallbackPlan(GenerateMealPlanRequest request, string reason)
    {
        if (!_settings.UseFallbackPlan)
        {
            _logger.LogWarning("Skipping fallback meal plan ({Reason}) because it is disabled.", reason);
            return null;
        }

        _logger.LogInformation("Generating fallback meal plan ({Reason}).", reason);

        var created = DateTime.UtcNow;
        var startDate = request.StartDate;
        var planTitle = string.IsNullOrWhiteSpace(request.Title)
            ? $"{request.FitnessGoal} 7-Day Meal Plan"
            : request.Title;

        var plan = new MealPlanDocument
        {
            Id = Guid.NewGuid(),
            Title = planTitle,
            StartDate = startDate,
            TimeZoneId = request.TimeZoneId,
            Preferences = request.ToPreferences(),
            Days = new List<MealDay>(),
            Meta = new MealPlanMeta
            {
                Summary = $"Balanced vegetarian schedule focused on {request.NutritionFocus} to support {request.FitnessGoal.ToLowerInvariant()} goals.",
                PrimaryFocus = request.FitnessGoal,
                DailyHighlights = new Dictionary<string, string>(),
                WeeklyTotals = new MealNutrition
                {
                    Calories = 7 * 1850,
                    Protein = 7 * 90,
                    Carbs = 7 * 210,
                    Fat = 7 * 60,
                    Micros = new Dictionary<string, double>
                    {
                        { "fiber", 7 * 28 },
                        { "iron", 7 * 18 }
                    }
                }
            },
            Shopping = new ShoppingPlanner
            {
                Items = new List<ShoppingItem>(),
                PantryChecks = new List<string>(),
                BatchCookingIdeas = new List<string>()
            },
            Budget = new BudgetPlanner
            {
                EstimatedTotal = request.WeeklyBudget,
                CategoryTotals = new Dictionary<string, decimal>(),
                SavingsTip = "Buy frozen vegetables and bulk grains to stretch the budget."
            },
            Prep = new PrepScheduler
            {
                WeekendPrep = new List<string>(),
                DailyQuickPrep = new List<string>(),
                LeftoverIdeas = new List<string>()
            },
            Pantry = new PantrySnapshot
            {
                PantryItems = new List<string>(),
                LowStockAlerts = new List<string>(),
                IngredientSwaps = new List<string>()
            },
            CookingTips = new List<string>(),
            CreatedAt = created,
            UpdatedAt = created
        };

        if (request.FavoriteIngredients?.Count > 0)
        {
            plan.Pantry.PantryItems.AddRange(request.FavoriteIngredients);
        }
        else
        {
            plan.Pantry.PantryItems.AddRange(new[] { "Olive oil", "Mixed herbs", "Rolled oats" });
        }

        plan.Pantry.LowStockAlerts.AddRange(new[]
        {
            "Check olive oil level",
            "Restock garlic powder"
        });

        plan.Pantry.IngredientSwaps.AddRange(new[]
        {
            "Swap quinoa for brown rice when desired",
            "Use black beans instead of chickpeas for variety"
        });

        var budget = Math.Max(request.WeeklyBudget, 75);
        plan.Budget.CategoryTotals["produce"] = Math.Round(budget * 0.4m, 2);
        plan.Budget.CategoryTotals["pantry"] = Math.Round(budget * 0.25m, 2);
        plan.Budget.CategoryTotals["protein"] = Math.Round(budget * 0.2m, 2);
        plan.Budget.CategoryTotals["other"] = Math.Round(budget * 0.15m, 2);

        plan.Prep.WeekendPrep.AddRange(new[]
        {
            "Roast trays of chickpeas and sweet potatoes for bowls.",
            "Cook quinoa and brown rice for quick reheats.",
            "Blend a citrus herb dressing for salads."
        });

        plan.Prep.DailyQuickPrep.AddRange(new[]
        {
            "Set oats to soak overnight for ready breakfasts.",
            "Pre-chop vegetables after dinner for the next day."
        });

        plan.Prep.LeftoverIdeas.AddRange(new[]
        {
            "Turn extra quinoa into a breakfast parfait with berries.",
            "Blend leftover roasted vegetables into soup."
        });

        plan.CookingTips.AddRange(new[]
        {
            "Group chopping tasks to cover several meals at once.",
            "Season with fresh herbs and citrus to keep flavors bright.",
            "Store snack portions in clear containers for easy grabs."
        });

        var snacks = BuildSnacks(request);
        var allIngredients = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        for (var dayIndex = 0; dayIndex < 7; dayIndex++)
        {
            var mealDay = new MealDay
            {
                Day = startDate.AddDays(dayIndex).ToString("dddd", CultureInfo.InvariantCulture),
                Meals = new List<PlannedMeal>(),
                Snacks = new List<string>(snacks),
                HydrationReminder = $"Aim for {request.HydrationGoal} spread across the day.",
                MovementReminder = "Take a 20-minute walk or gentle stretch session."
            };

            for (var mealIndex = 0; mealIndex < MealTypes.Length; mealIndex++)
            {
                var meal = BuildFallbackMeal(MealTypes[mealIndex], dayIndex, request);
                mealDay.Meals.Add(meal);
                foreach (var ingredient in meal.Ingredients)
                {
                    allIngredients.Add(ingredient);
                }
            }

            plan.Days.Add(mealDay);
            plan.Meta.DailyHighlights[mealDay.Day] = $"Focus on {request.NutritionFocus.ToLowerInvariant()} with balanced {MealTypes[dayIndex % MealTypes.Length].ToLowerInvariant()} choices.";
        }

        plan.Shopping.Items = allIngredients
            .Select(ingredient => new ShoppingItem
            {
                Name = ingredient,
                Category = InferCategory(ingredient),
                Quantity = "As needed",
                Optional = false
            })
            .Take(40)
            .ToList();

        plan.Shopping.PantryChecks = plan.Pantry.PantryItems.Take(5).ToList();
        plan.Shopping.BatchCookingIdeas.AddRange(new[]
        {
            "Batch roast vegetables for two days of lunches.",
            "Cook double portions of grains for quick dinners.",
            "Prepare smoothie packs to blend in the morning."
        });

        return plan;
    }

    private static PlannedMeal BuildFallbackMeal(string mealType, int dayIndex, GenerateMealPlanRequest request)
    {
        var templates = mealType switch
        {
            "Breakfast" => BreakfastTemplates,
            "Lunch" => LunchTemplates,
            _ => DinnerTemplates
        };

        var template = templates[dayIndex % templates.Length];
        var description = $"{template.Description} Supports {request.FitnessGoal.ToLowerInvariant()} goals with a {request.NutritionFocus.ToLowerInvariant()} focus.";

        return new PlannedMeal
        {
            Type = mealType,
            Name = template.Name,
            Description = description,
            Ingredients = template.Ingredients.ToList(),
            Instructions = template.Instructions.ToList(),
            Nutrition = new MealNutrition
            {
                Calories = template.Calories,
                Protein = template.Protein,
                Carbs = template.Carbs,
                Fat = template.Fat,
                Micros = new Dictionary<string, double>
                {
                    { "fiber", mealType.Equals("Lunch", StringComparison.OrdinalIgnoreCase) ? 10 : 7 },
                    { "vitamin_c", mealType.Equals("Breakfast", StringComparison.OrdinalIgnoreCase) ? 60 : 25 },
                    { "iron", 5 }
                }
            }
        };
    }

    private static List<string> BuildSnacks(GenerateMealPlanRequest request)
    {
        if (request.SnackPreferences is { Count: > 0 } &&
            request.SnackPreferences.All(snack => !string.Equals(snack, "any", StringComparison.OrdinalIgnoreCase)))
        {
            return new List<string>(request.SnackPreferences);
        }

        return new List<string>
        {
            "Fresh fruit cup",
            "Roasted chickpeas",
            "Veggie sticks with hummus"
        };
    }

    private static string InferCategory(string ingredient)
    {
        var text = ingredient.ToLowerInvariant();
        if (text.Contains("spinach") || text.Contains("kale") || text.Contains("broccoli") || text.Contains("berries") || text.Contains("tomato"))
        {
            return "Produce";
        }

        if (text.Contains("tofu") || text.Contains("chickpea") || text.Contains("lentil") || text.Contains("yogurt") || text.Contains("cheese"))
        {
            return "Protein";
        }

        if (text.Contains("rice") || text.Contains("quinoa") || text.Contains("oat") || text.Contains("pita") || text.Contains("bread"))
        {
            return "Grains";
        }

        if (text.Contains("sauce") || text.Contains("oil") || text.Contains("spice") || text.Contains("seed"))
        {
            return "Pantry";
        }

        return "Pantry";
    }

    private sealed record MealTemplate(
        string Name,
        string Description,
        string[] Ingredients,
        string[] Instructions,
        double Calories,
        double Protein,
        double Carbs,
        double Fat);

    private void EnsureApiKey()
    {
        if (!string.IsNullOrWhiteSpace(_settings.ApiKey))
        {
            return;
        }

        var fallback = Environment.GetEnvironmentVariable("OPENROUTER_API_KEY");
        if (!string.IsNullOrWhiteSpace(fallback))
        {
            _settings.ApiKey = fallback;
            return;
        }

        throw new InvalidOperationException("OpenRouter API key is missing. Set OpenRouter:ApiKey or OPENROUTER_API_KEY.");
    }

    private static string BuildSystemPrompt()
    {
        var sb = new StringBuilder();
        sb.AppendLine("You create weekly meal plans for families.");
        sb.AppendLine("Always respond with valid JSON that matches the schema we describe.");
        sb.AppendLine("The JSON keys must be camelCase.");
        sb.AppendLine("Include the following blocks: title, summary, days, meta, shopping, budget, prep, pantry, tips.");
        sb.AppendLine("Limit days to exactly 7 and meals per day to breakfast, lunch, dinner.");
        sb.AppendLine("Each meal has type, name, description, <=6 ingredients, <=4 instructions, and nutrition.");
        sb.AppendLine("Nutrition includes calories, protein, carbs, fat, and up to 4 micros.");
    sb.AppendLine("Do not leave any array empty. Invent fitting meals, snacks, and highlights when details are missing.");
    sb.AppendLine("Day labels must be weekday names derived from the user's startDate, not numbers.");
    sb.AppendLine("Meta.summary and meta.dailyHighlights must describe the focus for the week and each day.");
        sb.AppendLine("Shopping contains items with name, category, quantity, optional flag plus pantryChecks (<=5) and batchCookingIdeas (<=3).");
        sb.AppendLine("Budget contains estimatedTotal, categoryTotals (<=5), savingsTip.");
        sb.AppendLine("Prep contains weekendPrep (<=4), dailyQuickPrep (<=4), leftoverIdeas (<=4).");
        sb.AppendLine("Pantry contains pantryItems (<=10), lowStockAlerts (<=5), ingredientSwaps (<=5).");
        sb.AppendLine("Keep text concise and omit any unrelated commentary.");
        sb.AppendLine("Respect the provided timeZoneId when proposing schedules or reminders.");
        sb.AppendLine("User metrics arrive in pounds for weight and feet/inches for height; convert if you need metric outputs.");
        return sb.ToString();
    }

    private static string BuildUserPrompt(GenerateMealPlanRequest request)
    {
        var payload = JsonSerializer.Serialize(request, SerializerOptions);
        return $"Craft a 7 day meal plan using these preferences: {payload}. Ensure every day includes breakfast, lunch, and dinner with detailed nutrition and instructions. Fill meta, shopping, budget, prep, pantry, and tips with meaningful guidance.";
    }

    private static MealPlanDocument MapDraftToDocument(AiMealPlanDraft draft, GenerateMealPlanRequest request)
    {
        var document = new MealPlanDocument
        {
            Title = string.IsNullOrWhiteSpace(request.Title) ? draft.Title : request.Title,
            StartDate = request.StartDate,
            TimeZoneId = request.TimeZoneId,
            Preferences = request.ToPreferences(),
            Days = draft.Days ?? new List<MealDay>(),
            Meta = draft.Meta ?? new MealPlanMeta(),
            Shopping = draft.Shopping ?? new ShoppingPlanner(),
            Budget = draft.Budget ?? new BudgetPlanner(),
            Prep = draft.Prep ?? new PrepScheduler(),
            Pantry = draft.Pantry ?? new PantrySnapshot(),
            CookingTips = draft.Tips ?? new List<string>(),
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        NormalizePlan(document, request);
        return document;
    }

    private static void NormalizePlan(MealPlanDocument plan, GenerateMealPlanRequest request)
    {
        plan.Days ??= new List<MealDay>();
        var start = request.StartDate == default ? DateTime.UtcNow.Date : request.StartDate;

        for (var i = 0; i < plan.Days.Count; i++)
        {
            var day = plan.Days[i] ?? new MealDay();
            plan.Days[i] = day;

            if (string.IsNullOrWhiteSpace(day.Day) || int.TryParse(day.Day, out _))
            {
                day.Day = start.AddDays(i).ToString("dddd", CultureInfo.InvariantCulture);
            }

            day.Meals ??= new List<PlannedMeal>();
            day.Snacks ??= new List<string>();

            foreach (var meal in day.Meals)
            {
                meal.Ingredients ??= new List<string>();
                meal.Instructions ??= new List<string>();
                meal.Nutrition ??= new MealNutrition();
                meal.Nutrition.Micros ??= new Dictionary<string, double>();
            }
        }

        plan.Meta ??= new MealPlanMeta();
        var focus = string.IsNullOrWhiteSpace(request.NutritionFocus)
            ? "balanced nutrition"
            : request.NutritionFocus;
        var fitnessGoal = string.IsNullOrWhiteSpace(request.FitnessGoal)
            ? "overall wellness"
            : request.FitnessGoal;
        if (string.IsNullOrWhiteSpace(plan.Meta.Summary))
        {
            plan.Meta.Summary = $"Weekly plan centered on {focus} supporting {fitnessGoal.ToLowerInvariant()} goals.";
        }

        if (string.IsNullOrWhiteSpace(plan.Meta.PrimaryFocus))
        {
            plan.Meta.PrimaryFocus = fitnessGoal;
        }

        plan.Meta.DailyHighlights ??= new Dictionary<string, string>();
        for (var i = 0; i < plan.Days.Count; i++)
        {
            var day = plan.Days[i];
            if (!plan.Meta.DailyHighlights.ContainsKey(day.Day))
            {
                plan.Meta.DailyHighlights[day.Day] = $"Focus on {focus.ToLowerInvariant()} with balanced meals.";
            }
        }

        plan.Meta.WeeklyTotals ??= new MealNutrition();
        plan.Meta.WeeklyTotals.Micros ??= new Dictionary<string, double>();

        plan.Shopping ??= new ShoppingPlanner();
        plan.Shopping.Items ??= new List<ShoppingItem>();
        plan.Shopping.PantryChecks ??= new List<string>();
        plan.Shopping.BatchCookingIdeas ??= new List<string>();

        plan.Budget ??= new BudgetPlanner();
        plan.Budget.CategoryTotals ??= new Dictionary<string, decimal>();
        if (string.IsNullOrWhiteSpace(plan.Budget.SavingsTip))
        {
            plan.Budget.SavingsTip = "Plan meals around seasonal produce to stretch the budget.";
        }

        plan.Prep ??= new PrepScheduler();
        plan.Prep.WeekendPrep ??= new List<string>();
        plan.Prep.DailyQuickPrep ??= new List<string>();
        plan.Prep.LeftoverIdeas ??= new List<string>();

        plan.Pantry ??= new PantrySnapshot();
        plan.Pantry.PantryItems ??= new List<string>();
        plan.Pantry.LowStockAlerts ??= new List<string>();
        plan.Pantry.IngredientSwaps ??= new List<string>();

        plan.CookingTips ??= new List<string>();
    }

    private sealed record OpenRouterCompletion(OpenRouterChoice[] Choices);

    private sealed record OpenRouterChoice(OpenRouterMessage Message);

    private sealed record OpenRouterMessage(string Content);

    private sealed class AiMealPlanDraft
    {
        public string Title { get; set; } = "Weekly Meal Plan";

        public MealPlanMeta? Meta { get; set; }

        public List<MealDay>? Days { get; set; }

        public ShoppingPlanner? Shopping { get; set; }

        public BudgetPlanner? Budget { get; set; }

        public PrepScheduler? Prep { get; set; }

        public PantrySnapshot? Pantry { get; set; }

        public List<string>? Tips { get; set; }
    }

    private sealed class FlexibleStringConverter : JsonConverter<string>
    {
        public override string Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
        {
            if (reader.TokenType == JsonTokenType.String)
            {
                return reader.GetString() ?? string.Empty;
            }

            if (reader.TokenType == JsonTokenType.Number)
            {
                if (reader.TryGetInt64(out var intValue))
                {
                    return intValue.ToString(CultureInfo.InvariantCulture);
                }

                if (reader.TryGetDecimal(out var decimalValue))
                {
                    return decimalValue.ToString(CultureInfo.InvariantCulture);
                }

                var doubleValue = reader.GetDouble();
                return doubleValue.ToString(CultureInfo.InvariantCulture);
            }

            if (reader.TokenType == JsonTokenType.True || reader.TokenType == JsonTokenType.False)
            {
                return reader.GetBoolean() ? "true" : "false";
            }

            if (reader.TokenType == JsonTokenType.Null)
            {
                return string.Empty;
            }

            using var json = JsonDocument.ParseValue(ref reader);
            return json.RootElement.GetRawText();
        }

        public override void Write(Utf8JsonWriter writer, string value, JsonSerializerOptions options)
        {
            writer.WriteStringValue(value);
        }
    }

    private sealed class FlexibleDecimalDictionaryConverter : JsonConverter<Dictionary<string, decimal>>
    {
        public override Dictionary<string, decimal> Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
        {
            if (reader.TokenType == JsonTokenType.Null)
            {
                return new Dictionary<string, decimal>(StringComparer.OrdinalIgnoreCase);
            }

            if (reader.TokenType != JsonTokenType.StartObject)
            {
                using var skip = JsonDocument.ParseValue(ref reader);
                return new Dictionary<string, decimal>(StringComparer.OrdinalIgnoreCase);
            }

            var result = new Dictionary<string, decimal>(StringComparer.OrdinalIgnoreCase);

            while (reader.Read())
            {
                if (reader.TokenType == JsonTokenType.EndObject)
                {
                    break;
                }

                if (reader.TokenType != JsonTokenType.PropertyName)
                {
                    continue;
                }

                var key = reader.GetString() ?? string.Empty;
                reader.Read();

                decimal value = 0m;
                switch (reader.TokenType)
                {
                    case JsonTokenType.Number:
                        value = reader.GetDecimal();
                        break;
                    case JsonTokenType.String:
                        var text = reader.GetString();
                        if (!string.IsNullOrWhiteSpace(text) && decimal.TryParse(text, NumberStyles.Any, CultureInfo.InvariantCulture, out var parsed))
                        {
                            value = parsed;
                        }
                        break;
                    case JsonTokenType.Null:
                        value = 0m;
                        break;
                    default:
                        using (JsonDocument.ParseValue(ref reader))
                        {
                        }
                        continue;
                }

                result[key] = value;
            }

            return result;
        }

        public override void Write(Utf8JsonWriter writer, Dictionary<string, decimal> value, JsonSerializerOptions options)
        {
            writer.WriteStartObject();
            foreach (var pair in value)
            {
                writer.WritePropertyName(pair.Key);
                writer.WriteNumberValue(pair.Value);
            }

            writer.WriteEndObject();
        }
    }
}
