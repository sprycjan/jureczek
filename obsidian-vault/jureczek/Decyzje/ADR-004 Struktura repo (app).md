---
tags: [jureczek, adr]
status: przyjęta
data: 2026-10-25
---
# ADR-004: Struktura repozytorium

```
jureczek/
├── app/              # projekt Flutter (pubspec.yaml tutaj)
└── obsidian-vault/   # notatki projektowe (ten vault)
```

## Uzasadnienie
W przyszłości może dojść np. `backend/` (synchronizacja), więc podział od początku nic nie kosztuje.

## Git
Repozytorium założone 2026-10-27 w katalogu głównym (ostatecznie na GitHubie, nie lokalnym GitLabie): `origin` = https://github.com/sprycjan/jureczek, gałąź `main`.
Główny `.gitignore`: `.DS_Store`, `.claude/settings.local.json`, `obsidian-vault/**/.obsidian/workspace*.json`. Standardowe wpisy Fluttera są w `app/.gitignore`, łącznie z `env/*.json` (token Mapbox nie trafia do repo).

Powiązane: [[Backlog]]
