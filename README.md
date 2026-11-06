# 🎵 CD Manager

Application web auto-hebergée pour gerer une collection de supports physiques
(CD, vinyles, cassettes, MiniDisc). Pensée pour tourner sur un NAS, en mono-utilisateur.

> Demo : https://cd.dechamps.eu

## Fonctionnalites
- Import Discogs : import complet et idempotent (pas de doublons).
- Ajout par EAN / scan : scan au telephone, interrogation MusicBrainz.
- Recherche et filtres : par artiste, titre, format.
- Wantlist : liste d'envies a part.
- Exports : CSV, JSON et PDF (catalogue imprimable).
- Sauvegarde automatique : cron quotidien de la base.
- HTTPS-ready : scan derriere reverse proxy TLS.

## Stack
Python 3.12, FastAPI, Uvicorn, SQLAlchemy async (SQLite), Jinja2 + HTMX, ReportLab, Pillow, Docker

## Installation
    git clone https://github.com/made2001/cd-manager.git
    cd cd-manager
    ./setup.sh
    docker compose up -d --build

Puis ouvrir http://IP-DU-NAS:8090

## Configuration (.env)
- DISCOGS_TOKEN : token API Discogs
- PASSWORD : mot de passe de connexion
- SECRET_KEY : signature des sessions

## Sauvegarde
Service backup (alpine + cron) : copie de la base chaque nuit a 03:00 vers /volume1/Datas/backup-cd.

## Tests
    pip install -r requirements.txt -r requirements-dev.txt && pytest -v

## Securite
.env et data/ exclus de Git. Auth par mot de passe + sessions signees. Aucune donnee stockee chez un tiers.

## Licence
MIT
