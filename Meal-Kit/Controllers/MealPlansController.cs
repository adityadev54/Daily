using MealKit.Models;
using MealKit.Requests;
using MealKit.Responses;
using MealKit.Services.Ai;
using MealKit.Services.Database;
using Microsoft.AspNetCore.Mvc;

namespace MealKit.Controllers;

[ApiController]
[Route("api/mealplans")]
public class MealPlansController : ControllerBase
{
    private readonly MealPlanRepository _repository;
    private readonly AiMealPlannerService _aiService;
    private readonly ILogger<MealPlansController> _logger;

    public MealPlansController(MealPlanRepository repository, AiMealPlannerService aiService, ILogger<MealPlansController> logger)
    {
        _repository = repository;
        _aiService = aiService;
        _logger = logger;
    }

    [HttpGet]
    public async Task<ActionResult<List<MealPlanSummaryResponse>>> GetAll(CancellationToken cancellationToken)
    {
        var plans = await _repository.GetAsync(cancellationToken);
        var summaries = plans.Select(MealPlanSummaryResponse.FromDocument).ToList();
        return Ok(summaries);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<MealPlanDocument>> GetById(string id, CancellationToken cancellationToken)
    {
        if (!Guid.TryParse(id, out var planId))
        {
            return BadRequest("Invalid meal plan id.");
        }

        var plan = await _repository.GetAsync(planId, cancellationToken);
        if (plan is null)
        {
            return NotFound();
        }

        return Ok(plan);
    }

    [HttpPost("generate")]
    public async Task<ActionResult<MealPlanDocument>> Generate([FromBody] GenerateMealPlanRequest request, CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
        {
            return ValidationProblem(ModelState);
        }

        var plan = await _aiService.GeneratePlanAsync(request, cancellationToken);
        if (plan is null)
        {
            return StatusCode(502, "Unable to build a meal plan right now. Try again shortly.");
        }

        await _repository.InsertAsync(plan, cancellationToken);
        return CreatedAtAction(nameof(GetById), new { id = plan.Id.ToString() }, plan);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(string id, [FromBody] UpdateMealPlanRequest request, CancellationToken cancellationToken)
    {
        if (!Guid.TryParse(id, out var planId))
        {
            return BadRequest("Invalid meal plan id.");
        }

        var updated = await _repository.UpdateAsync(planId, plan =>
        {
            if (!string.IsNullOrWhiteSpace(request.Title))
            {
                plan.Title = request.Title;
            }

            if (request.StartDate.HasValue)
            {
                plan.StartDate = request.StartDate.Value;
            }

            if (!string.IsNullOrWhiteSpace(request.TimeZoneId))
            {
                plan.TimeZoneId = request.TimeZoneId;
                plan.Preferences ??= new MealPreferences();
                plan.Preferences.TimeZoneId = request.TimeZoneId;
            }

            if (request.Days is { Count: > 0 })
            {
                plan.Days = request.Days;
            }

            if (request.Meta is not null)
            {
                plan.Meta = request.Meta;
            }

            if (request.Shopping is not null)
            {
                plan.Shopping = request.Shopping;
            }

            if (request.Budget is not null)
            {
                plan.Budget = request.Budget;
            }

            if (request.Prep is not null)
            {
                plan.Prep = request.Prep;
            }

            if (request.Pantry is not null)
            {
                plan.Pantry = request.Pantry;
            }

            if (request.CookingTips is not null)
            {
                plan.CookingTips = request.CookingTips;
            }
        }, cancellationToken);

        if (!updated)
        {
            return NotFound();
        }

        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(string id, CancellationToken cancellationToken)
    {
        if (!Guid.TryParse(id, out var planId))
        {
            return BadRequest("Invalid meal plan id.");
        }

        var deleted = await _repository.DeleteAsync(planId, cancellationToken);
        if (!deleted)
        {
            return NotFound();
        }

        return NoContent();
    }
}
