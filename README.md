# Rigel Core

`rigel-core` is the source-of-truth repository for workspace-level documentation,
shared constraints, Docker Compose orchestration, and database bootstrap files.

The workspace root `/Users/mac-mini/work/private/rigel` is not a Git repository.
All core docs and shared operational files now live in this repository.

## Current Product Direction

The project is now centered on one short pipeline:

1. query JD Union data once per day
2. normalize raw product titles into canonical part models
3. aggregate daily prices per canonical model
4. let `rigel-build-engine` accept UI parameters, organize current hardware information, and request AI API analysis
5. return a readable build recommendation through `rigel-console`

The main product output is not a crawler dashboard and not a heavy rule engine.
The main product output is a daily usable part-price catalog that AI can consume.

## Workspace Layout

```text
rigel/
├── rigel-core/
│   ├── README.md
│   ├── AGENTS.md
│   ├── .env.example
│   ├── docker-compose.yml
│   ├── db/
│   │   └── init/
│   │       └── 001_init.sql
│   ├── docs/
│   │   ├── architecture.md
│   │   └── database-schema.md
│   └── 电脑配置平台项目方案文档.md
├── rigel-build-engine/
├── rigel-console/
└── rigel-jd-collector/
```

## Module Responsibilities

- `rigel-jd-collector`: call JD Union/OpenAPI, query raw JD product samples, and write daily price snapshots.
- `rigel-build-engine`: accept UI parameters from `rigel-console`, organize hardware information, request AI API analysis, and keep only minimal hard compatibility checks.
- `rigel-console`: minimal API/UI entry point for triggering collection and viewing results.

## What Matters Most

The core daily data product should look like this:

- raw samples:
  - `Gloway 32GB (16GBx2) DDR5 6000 ...` + `price`
  - `Kingston 32GB (16GBx2) DDR5 6000 ...` + `price`
- canonical output:
  - `DDR5 6000 32G` -> average or median daily price

Example target catalog:

- `DDR5 6000 32G -> 2250`
- `DDR4 5000 32G -> 1600`
- `i7-14700K -> 1000`

That catalog is what later gets sent to AI together with user intent such as `6000 budget` and `gaming`.

## Current Scope

Current implementation work is being re-aligned toward:

- daily JD Union price collection
- canonical model normalization
- per-model daily aggregation
- build-engine-owned AI analysis output
- only minimal hard checks in `rigel-build-engine`

Heavier compatibility/scoring logic and larger admin surfaces are secondary to this core flow.

## Strong Constraints

The following rules are hard constraints for this workspace:

1. `rigel-core` is the shared source of truth for workspace-level docs, constraints, Compose files, and bootstrap SQL.
2. Every module repository must follow [AGENTS.md](/Users/mac-mini/work/private/rigel/rigel-core/AGENTS.md) in `rigel-core` before applying local conventions.
3. If code, logic, interfaces, configuration, architecture, or runtime behavior changes, the affected documentation must be updated in the same turn.
4. At minimum, update the impacted module README. If the change affects shared architecture, shared workflow, shared data model, deployment, or workspace conventions, also update `rigel-core`.
5. Documentation is part of delivery. A code change is not considered complete until the relevant docs are aligned.
6. After local verification, every repository that actually changed must be committed and pushed to its remote. Do not create empty commits.
7. Backend services should use Go whenever practical. `rigel-jd-collector` must use Go.
8. External platform integrations must stay behind local clients or adapters. Unverified third-party capabilities must be marked `TODO` or `MOCK`.
9. Current product focus is `daily price collection -> canonical model normalization -> aggregated price catalog -> AI recommendation`. Work that does not support this flow is secondary.

## How To Start

1. Enter `rigel-core`.
2. Copy `.env.example` to `.env`.
3. Keep shared runtime files such as `.env` in `rigel-core`.
4. Start infrastructure and services:

```bash
cd /Users/mac-mini/work/private/rigel/rigel-core
docker compose up --build
```

3. Health endpoints:

- `http://localhost:18081/healthz` JD collector
- `http://localhost:18082/healthz` build engine
- `http://localhost:18084/healthz` console

## Current Notes

- External platform integrations remain behind local adapters and should not be treated as stable official APIs unless verified.
- `docker-compose.yml` and `.env` are now expected to be managed from `rigel-core`.
