# 🎵 CD Manager
Application web auto-hébergée pour gérer une collection de supports physiques
(CD, vinyles, cassettes, MiniDisc). Import Discogs, ajout par EAN/scan,
recherche, wantlist, exports CSV/JSON/PDF. Mono-utilisateur, pensée pour NAS.

## Stack
Python 3.12 + FastAPI · HTMX + Jinja2 · SQLite (SQLAlchemy async) · Docker

## Installation
1. `./setup.sh` (génère .env : token Discogs, mot de passe, SECRET_KEY)
2. `docker compose up -d --build`
3. Ouvrir `http://IP-DU-NAS:8090`

## Import Discogs
Menu "Import Discogs" → username → lancer. Idempotent (pas de doublons).
~25-30 min pour 1200 références (rate limit ~1 req/s).

## Scan téléphone
Nécessite HTTPS (reverse proxy NAS ou Tailscale).

## Tests
`pip install -r requirements.txt -r requirements-dev.txt && pytest -v`

## Sécurité
`.env` et `data/` sont exclus de Git via `.gitignore`. Ne jamais les pousser.
