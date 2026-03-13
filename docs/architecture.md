# Rigel Architecture

## Core Pipeline

Rigel should be understood as a daily market-data pipeline with an AI recommendation layer on top.

1. collectors fetch raw JD and Goofish product samples
2. raw titles and prices are stored as platform records
3. `rigel-build-engine` maps raw samples into canonical part models
4. `rigel-build-engine` aggregates daily model prices
5. `rigel-ai-advisor` receives `budget + use case + canonical price catalog`
6. `rigel-console` exposes the result

## Service Boundaries

- Collectors own external platform integration details and login/session handling.
- `rigel-build-engine` owns canonical model mapping and daily price aggregation.
- `rigel-build-engine` keeps only minimal hard checks that should not be delegated to AI.
  - current intent: CPU/mainboard platform and mainboard/RAM type class
- `rigel-ai-advisor` is the main recommendation-expression layer.
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

- given `6000 RMB` and `gaming`, what parts does AI recommend based on today's aggregated JD and Goofish price catalog?

`rigel-goofish-collector` remains reference-only in phase 1.
Its output should enrich the catalog, not directly override the main JD new-part baseline.
