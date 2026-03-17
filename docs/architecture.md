# Rigel Architecture

## Core Pipeline

Rigel should be understood as a daily market-data pipeline with an AI recommendation layer on top.

1. `rigel-jd-collector` queries JD Union/OpenAPI for raw JD product samples
2. raw titles and prices are stored as platform records
3. `rigel-build-engine` maps raw samples into canonical part models
4. `rigel-build-engine` aggregates daily model prices
5. `rigel-build-engine` accepts UI parameters, organizes the structured catalog, and requests AI API analysis
6. `rigel-console` exposes the result

## Service Boundaries

- `rigel-jd-collector` owns JD Union/OpenAPI integration details and persistence.
- `rigel-build-engine` owns canonical model mapping, daily price aggregation, and AI analysis request assembly.
- `rigel-build-engine` keeps only minimal hard checks that should not be delegated to AI.
  - current intent: CPU/mainboard platform and mainboard/RAM type class
- `rigel-build-engine` currently owns the aggregation layer and the AI analysis request/response layer.
- `rigel-console` is a thin API/UI shell and should not own pricing or compatibility logic.

## Current Design Principle

The project is not currently optimizing for a heavy expert-system build engine.
The project is optimizing for a reliable daily price catalog that AI can use.

That means the most important structured output is:

- date
- platform
- canonical model
- sample count
- avg price
- median price
- p25
- p75

## Phase 1 Output

Phase 1 should be able to answer this question reliably:

- given `6000 RMB` and `gaming`, what parts does AI recommend based on today's aggregated JD price catalog?

The current active scope uses JD as the primary collection source.
