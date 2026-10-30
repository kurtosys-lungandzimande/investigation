# TeamCity + Octopus Onboarding - Postgres Test

## Run locally with Docker

```bash
docker context use desktop-linux
docker compose up --build
```

## Test endpoints

```bash
curl http://localhost:8000/health
curl http://localhost:8000/db-check
```
