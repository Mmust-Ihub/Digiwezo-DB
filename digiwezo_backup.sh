#! /bin/bash

# Configuration
BACKUP_DIR="/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PREFIX="digiwezo_backup"
BACKUP_NAME="${BACKUP_PREFIX}_${TIMESTAMP}"
RETENTION_DAYS=7 # Keep backups for 7 days

# ----- Colors ----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# --- Helper functions --------
log() {
	echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
	echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

warn() {
	echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

if [[ -f "/scripts/.env" ]]; then
	source "/scripts/.env"
else
	echo "/scripts/.env file not found. Exiting ..."
	exit 1
fi

# Create backup directory if it doesn't exist
mkdir -p "${BACKUP_DIR}/${BACKUP_NAME}"

log "Starting MongoDB backup at $(date)"
log "Backup location: ${BACKUP_DIR}/${BACKUP_NAME}"

# Perform the backup
mongodump \
	--host="${MONGO_SECONDARY_HOST}" \
	--port="${MONGO_PORT:-27017}" \
	--username="${MONGO_INITDB_ROOT_USERNAME}" \
	--password="${MONGO_INITDB_ROOT_PASSWORD}" \
	--authenticationDatabase="${MONGO_AUTH_DB}" \
	--out="${BACKUP_DIR}/${BACKUP_NAME}" \
	--gzip

# Check if backup was successful
if [ $? -eq 0 ]; then
	log "Backup completed successfully at $(date)"

	# Create a compressed archive
	cd "${BACKUP_DIR}"
	tar -czf "${BACKUP_NAME}.tar.gz" "${BACKUP_NAME}"

	# Remove the uncompressed backup directory
	rm -rf "${BACKUP_NAME}"

	log "Backup compressed to ${BACKUP_NAME}.tar.gz"

	# Remove backups older than RETENTION_DAYS
	log "Cleaning up old backups (older than ${RETENTION_DAYS} days)..."
	find "${BACKUP_DIR}" -name "${BACKUP_PREFIX}_*.tar.gz" -type f -mtime +${RETENTION_DAYS} -delete

	# List current backups
	log "Current backups:"
	ls -lh "${BACKUP_DIR}"

else
	error "Backup failed at $(date)"
	exit 1
fi
