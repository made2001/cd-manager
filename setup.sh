#!/bin/bash
set -e
echo "🎵 Setup CD Manager"
mkdir -p data/covers
SECRET_KEY=$(openssl rand -hex 32)
read -sp "Mot de passe admin : " ADMIN_PASSWORD
echo
read -sp "Confirmer : " ADMIN_PASSWORD2
echo
if [ "$ADMIN_PASSWORD" != "$ADMIN_PASSWORD2" ]; then echo "❌ Mismatch"; exit 1; fi
read -p "Token Discogs : " DISCOGS_TOKEN
read -p "Email (User-Agent API) : " EMAIL
cat > .env <<ENV_EOF
DISCOGS_TOKEN=${DISCOGS_TOKEN}
DISCOGS_USER_AGENT=CDManager/1.0 (${EMAIL})
SECRET_KEY=${SECRET_KEY}
ADMIN_PASSWORD=${ADMIN_PASSWORD}
MUSICBRAINZ_USER_AGENT=CDManager/1.0 (${EMAIL})
ENV_EOF
chmod 600 .env
echo "✅ .env généré. Lance : docker compose up -d --build"
