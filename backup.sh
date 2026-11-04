#!/bin/bash
BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30
mkdir -p "$BACKUP_DIR"
tar -czf "$BACKUP_DIR/backup_${DATE}.tar.gz" -C /data .
find "$BACKUP_DIR" -name "backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete
echo "[$(date)] Backup OK"
