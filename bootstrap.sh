et -e
echo "🎵 Génération de CD Manager..."

# --- Dossiers ---
mkdir -p app/routers app/services app/templates/partials app/static/css tests data/covers

# --- .gitignore ---
cat > .gitignore <<'EOF'
.env
data/
__pycache__/
*.py[cod]
venv/
.venv/
.pytest_cache/
*.log
.DS_Store
EOF

# --- requirements.txt ---
cat > requirements.txt <<'EOF'
fastapi==0.115.0
uvicorn[standard]==0.30.0
sqlalchemy==2.0.35
aiosqlite==0.20.0
httpx==0.27.0
python-multipart==0.0.9
bcrypt==4.2.0
itsdangerous==2.2.0
jinja2==3.1.4
pydantic-settings==2.5.0
reportlab==4.2.4
Pillow==10.4.0
EOF

# --- requirements-dev.txt ---
cat > requirements-dev.txt <<'EOF'
pytest==8.3.0
pytest-asyncio==0.24.0
respx==0.21.1
EOF

# --- pytest.ini ---
cat > pytest.ini <<'EOF'
[pytest]
asyncio_mode = auto
testpaths = tests
filterwarnings =
    ignore::DeprecationWarning
EOF

# --- docker-compose.yml ---
cat > docker-compose.yml <<'EOF'
version: "3.8"
services:
  cd-manager:
    build: .
    container_name: cd-manager
    restart: unless-stopped
    ports:
      - "8090:8000"
    volumes:
      - ./data:/app/data
    env_file:
      - .env
    environment:
      - TZ=Europe/Brussels
  backup:
    image: alpine:3.19
    container_name: cd-manager-backup
    restart: unless-stopped
    volumes:
      - ./data:/data:ro
      - /volume1/homes/matthieu/backups:/backups
      - ./backup.sh:/backup.sh:ro
    entrypoint: sh
    command: -c "echo '0 3 * * * /backup.sh' | crontab - && crond -f"
EOF

# --- Dockerfile ---
cat > Dockerfile <<'EOF'
FROM python:3.12-slim
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends gcc && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app/ ./app/
RUN mkdir -p /app/data/covers
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

# --- backup.sh ---
cat > backup.sh <<'EOF'
#!/bin/bash
BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30
mkdir -p "$BACKUP_DIR"
tar -czf "$BACKUP_DIR/backup_${DATE}.tar.gz" -C /data .
find "$BACKUP_DIR" -name "backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete
echo "[$(date)] Backup OK"
EOF

echo "✅ Fichiers racine générés"
echo "→ La génération des fichiers Python et templates continue dans bootstrap-2.sh"
