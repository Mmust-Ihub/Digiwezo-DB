#!/bin/bash
# ------------ Example Usage: ./restore_backup.sh "/home/city/backups/digiwezo_backup_20251114_170801.tar.gz"

PROJECT_ROOT=$(cd -P -- "$(dirname "${BASH_SOURCE[0]}")/" && pwd -P)

if [[ -f "${PROJECT_ROOT}/common.sh" ]]; then
	source "${PROJECT_ROOT}/common.sh"
else
	echo "No common.sh file found in ${PROJECT_ROOT}. Exiting ..."
	exit 1
fi

BACKUP_FILE=$1
RESTORE_DIR="/tmp/restore"

if [ -z "${BACKUP_FILE}" ]; then
	error "Usage: $0 <backup_file.tar.gz>"
	exit 1
fi

if [[ ! -f "${BACKUP_FILE}" ]]; then
	error "Error: Backup file '${BACKUP_FILE}' not found"
	exit 1
fi

log "=========================================="
log "MongoDB Restore Process"
log "=========================================="

# Clean up any previous restore directory
if [ -d "${RESTORE_DIR}" ]; then
	log "Cleaning up previous restore directory..."
	rm -rf "${RESTORE_DIR}"
fi

# Extract backup
log "Extracting backup..."
mkdir -p "${RESTORE_DIR}"
tar -xzf "${BACKUP_FILE}" -C "${RESTORE_DIR}"

# Get the backup directory name
BACKUP_DIR=$(ls "${RESTORE_DIR}" | head -1)

if [ -z "${BACKUP_DIR}" ]; then
	error "Error: Could not find backup directory after extraction"
	rm -rf "${RESTORE_DIR}"
	exit 1
fi

# Perform restore
log "Starting restore process..."
docker run --rm \
	--network "${NETWORK}" \
	-v "${RESTORE_DIR}:/restore" \
	-e MONGO_INITDB_ROOT_USERNAME="${MONGO_INITDB_ROOT_USERNAME}" \
	-e MONGO_INITDB_ROOT_PASSWORD="${MONGO_INITDB_ROOT_PASSWORD}" \
	-e MONGO_PRIMARY_HOST="${MONGO_PRIMARY_HOST:-mongod1}" \
	-e MONGO_PORT="${MONGO_PORT:-27017}" \
	-e MONGO_AUTH_DB="${MONGO_AUTH_DB:-admin}" \
	-e BACKUP_DIR="${BACKUP_DIR}" \
	mongo:latest \
	/bin/bash -c '
        mongorestore \
            --uri="mongodb://${MONGO_INITDB_ROOT_USERNAME}:${MONGO_INITDB_ROOT_PASSWORD}@${MONGO_PRIMARY_HOST}:${MONGO_PORT}/?authSource=${MONGO_AUTH_DB}&replicaSet=dbrs" \
            --nsExclude="admin.*" \
			--nsExclude="config.*" \
			--nsExclude="local.*" \
            --gzip \
            --drop \
            --preserveUUID \
            --numInsertionWorkersPerCollection=4 \
            "/restore/${BACKUP_DIR}"
    '

RESTORE_STATUS=$?

# Cleanup
if [ $RESTORE_STATUS -eq 0 ]; then
	log "=========================================="
	log "Restore completed successfully!"
	log "=========================================="
	rm -rf "${RESTORE_DIR}"
	exit 0
else
	error "=========================================="
	error "Restore failed!"
	error "=========================================="
	error "Restore directory preserved at: ${RESTORE_DIR}"
	error "Check the error messages above for details"
	exit 1
fi
