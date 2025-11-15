#! /bin/bash

PROJECT_ROOT=$(cd -P -- "$(dirname "${BASH_SOURCE[0]}")/" && pwd -P)
CRONJOB="0 */12 * * * $PROJECT_ROOT/run_backup.sh" # Control when db backups are taken.
LOG_FILE="/var/log/mongodb_backup.log"

if [[ -f "${PROJECT_ROOT}/common.sh" ]]; then
   source "${PROJECT_ROOT}/common.sh"
fi

# Create an external network if it doesn't exist
if command_exists "docker"; then
	docker network create "$NETWORK" || { warn "$NETWORK network already exists. Skipping ..."; }
fi

log "Starting the MongoDB cluster ..."
docker compose up -d --build

# Setup a cronjob to take backups
CRONJOB="* * * * * $PROJECT_ROOT/run_backup.sh"
(sudo crontab -l; echo "$CRONJOB >> $LOG_FILE 2>&1") | sudo crontab -
sudo systemctl restart cron || { error "Error restarting cron service ..";}

# Log success.
log "============================"
log "Initialization finished successfull. Everything is now working fine."
log "================================"