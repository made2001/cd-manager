# 🎵 CD Manager

Application web auto-hebergée pour gerer une collection de supports physiques
(CD, vinyles, cassettes, MiniDisc). Pensée pour tourner sur un NAS, en mono-utilisateur.

## Fonctionnalites
- Import Discogs : idempotent et incrementel. La base locale est comparee a la
  collection Discogs via discogs_release_id ; seuls les nouveautes sont importees,
  les deja-presents sont comptes dans "skipped".
- Ajout par EAN / scan : scan au telephone, interrogation MusicBrainz (fallback Discogs).
- Recherche et filtres : par artiste, titre, format.
- Wantlist : liste d envies a part.
- Exports : CSV, JSON et PDF (catalogue imprimable).
- Sauvegarde automatique : cron quotidien de la base.
- HTTPS-ready : scan derriere reverse proxy TLS.

## Stack
Python 3.12, FastAPI, Uvicorn, SQLAlchemy async (SQLite), Jinja2 + HTMX, ReportLab, Pillow, Docker

## Installation
    git clone https://github.com/made2001/cd-manager.git
    cd cd-manager
    cp .env.example .env   # puis renseigner les valeurs
    mkdir -p data/covers
    docker compose up -d --build

Puis ouvrir http://IP-DU-NAS:8090

## Configuration (.env)
- DISCOGS_TOKEN : token API Discogs
- DISCOGS_USER_AGENT / MUSICBRAINZ_USER_AGENT : user-agent declares aux APIs
- ADMIN_PASSWORD : mot de passe de connexion (hash en base au premier demarrage)
- SECRET_KEY : signature des sessions

## Sauvegarde
Service backup (alpine + cron) : copie de la base chaque nuit a 03h00 vers /volume1/Datas/backup-cd.

## Deploiement et notes d infra
- Conteneur en utilisateur non-root (uid 1000). Apres restauration d un backup,
  faire un "chown -R 1000:1000 ./data" sur l hote avant de demarrer, sinon SQLite
  est en lecture seule.
- Rate-limit du login gere cote NPM (pas dans l app) : zone "cdlogin" declaree
  dans nginx/custom/http.conf (contexte http) et appliquee par un bloc
  "location = /login" dans l onglet Advanced du proxy host. Ne pas nommer le
  fichier server_http.conf : seul http.conf est inclus par nginx.conf.
- Le port interne est 8000 ; le NAS expose 8090 (mapping 8090:8000).

## Securite
.env et data/ exclus de Git. Auth par mot de passe + sessions signees (cookie Secure).
Routes export et lookup protegees par auth. JS servi en local (pas de CDN).
Aucune donnee stockee chez un tiers.

## Licence
MIT
