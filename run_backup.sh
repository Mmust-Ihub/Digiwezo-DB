#!/bin/bash

: "Take the database backups periodically."

PROJECT_ROOT=$(cd -P -- "$(dirname "${BASH_SOURCE[0]}")/" && pwd -P)
BACKUP_DIR="/var/backups"

if [[ -f "${PROJECT_ROOT}/common.sh" ]]; then
	source "${PROJECT_ROOT}/common.sh"
else
	echo "No common.sh file found in ${PROJECT_ROOT}. Exiting ..."
	exit 1
fi

mkdir -p "$BACKUP_DIR"

docker run --rm \
	--network "${NETWORK}" \
	-v "${BACKUP_DIR}:/backups" \
	-v "${PROJECT_ROOT}/.env:/scripts/.env" \
	-v "${PROJECT_ROOT}/digiwezo_backup.sh:/scripts/digiwezo_backup.sh" \
	mongo:latest \
	/bin/bash /scripts/digiwezo_backup.sh

# Sync the data with AWS S3 bucket
log "Starting S3 sync process..."

BUCKET="${S3_BUCKET_NAME}"
S3_PATH="s3://${BUCKET}/backups"
AWS_REGION="${AWS_REGION:-us-central-1}"

log "Syncing to ${S3_PATH} (Region: ${AWS_REGION})"


docker run --rm \
    -v "${BACKUP_DIR}:/backups" \
    -e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
    -e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
    -e AWS_DEFAULT_REGION="${AWS_REGION}" \
    amazon/aws-cli:latest \
    s3 sync /backups "${S3_PATH}" \
        --storage-class STANDARD_IA \
        --only-show-errors \
        --exclude ".*" \
        --exclude "*.log" \
		2>&1 | tee -a /var/log/s3_sync.log


SYNC_EXIT_CODE=$?

if [ ${SYNC_EXIT_CODE} -eq 0 ]; then
	log "Successfully synced backups to ${S3_PATH}"

else
	error "S3 sync failed with exit code: ${SYNC_EXIT_CODE}"
	error "Check logs at: /var/log/s3_sync.log"
	exit 1
fi

# --- Remove unused volumes ---
echo "y" | docker volume prune # Remove used volumes
echo "y" | docker image prune # Remove dangling images.
