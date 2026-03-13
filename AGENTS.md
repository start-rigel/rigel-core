# AGENTS.md

## Project
Rigel is a PC build recommendation platform for Chinese users.

## Scope
- `rigel-core` is the canonical repository for shared documentation, shared constraints, Docker Compose, and workspace-level database/bootstrap files.
- All other Rigel repositories should follow this file before applying any module-local conventions.

## Modules
- rigel-core
- rigel-goofish-collector
- rigel-jd-collector
- rigel-jd-browser-collector
- rigel-build-engine
- rigel-ai-advisor
- rigel-console

## Language Rules
- Backend should use Go whenever possible
- rigel-jd-collector must use Go
- rigel-build-engine should use Go
- rigel-ai-advisor should use Go
- rigel-console backend should use Go
- rigel-goofish-collector is allowed to keep the original upstream language if required by ai-goofish-monitor, but must expose clean integration boundaries

## Architecture Rules
- Build compatibility must be decided in rigel-build-engine
- AI is explanation-only
- Goofish data is reference-only in phase 1
- JD is the primary data source in phase 1
- All services must use environment variables
- Prefer simple, testable abstractions
- Keep external platform integrations behind client/adapters

## Tech Stack
- Go for backend services
- PostgreSQL
- Redis
- Docker Compose

## Code Style
- Use clear package boundaries
- Add README for each module
- Add comments for non-trivial logic
- Do not hardcode secrets
- Avoid fake claims about third-party API availability
- Mark unverified integrations as TODO or MOCK

## Delivery Rules
When making changes:
1. Explain modified files
2. Explain the design choice
3. Explain how to run
4. Mark unknown external integrations as TODO or MOCK
5. If code, logic, interfaces, configuration, architecture, or runtime behavior changes, update the affected documentation in the same turn
6. At minimum, update the impacted module README; if the change affects shared architecture, shared workflow, shared data model, deployment, or workspace conventions, also update documentation in `rigel-core`
7. Documentation is part of the delivery; code changes are not complete until the relevant documentation is aligned
8. After code is verified locally, check all 6 repositories and push every repository that actually has changes to its remote
9. Do not create empty commits for repositories with no changes
