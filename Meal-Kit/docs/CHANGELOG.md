# Changelog

All notable changes to **Meal Kit** are documented in this file. The project follows [Semantic Versioning](https://semver.org/).

## [0.2.0] - 2025-10-30
- Enforced a strict JSON schema for OpenRouter responses and normalize AI output to guarantee fully populated meal plans.
- Added flexible JSON converters plus `UseFallbackPlan` toggle to control hardcoded plans and improved diagnostics.
- Updated prompts and request pipeline to deliver consistent daily highlights, shopping lists, and metadata.

## [0.1.0] - 2025-10-29
- Initial release with ASP.NET Core API, Postgres persistence, AI meal generation, and CRUD endpoints.
