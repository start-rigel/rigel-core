# Database Schema

This document describes the current schema direction for Rigel.

## Primary Data Shape

The most important records in the system are:

- raw platform products
- raw price snapshots
- canonical parts / canonical models
- raw-to-canonical mappings
- daily aggregated market summaries

The schema should support this daily flow:

1. store raw JD Union product samples
2. append price snapshots
3. map raw products to canonical part models
4. aggregate per-day prices per canonical model
5. provide an AI-ready price catalog

## Ownership

- `rigel-jd-collector`: queries JD Union/OpenAPI and writes `products`, `price_snapshots`, `jobs`
- `rigel-build-engine`: owns canonical `parts`, `product_part_mapping`, `part_market_summary`
- `rigel-build-engine`: also owns AI request payload generation from structured catalog data and recommendation response assembly
- `rigel-console`: orchestrates through service APIs

## Table Intent

- `parts`: canonical hardware part catalog and canonical model keys
- `products`: raw platform product records from JD
- `product_part_mapping`: normalized mapping from raw product to canonical part/model
- `price_snapshots`: append-only captured price history
- `part_market_summary`: daily aggregated market data by canonical part and platform
- `jobs`: collection and processing task records

## Current Direction Change

Compared with the earlier design, the center of gravity is now:

- less emphasis on rich spec modeling
- less emphasis on complex scoring profiles
- more emphasis on daily per-model price aggregation
- more emphasis on AI-ready catalog output

Legacy build-request/result tables may still exist in the bootstrap SQL, but they are no longer part of the active module responsibility.
