#! /bin/bash

: "This file is intended to centrally hold all common utilities and functions common in other scripts."

set -eEuo pipefail

# ---- Configs -----
PROJECT_ROOT=$(cd -P -- "$(dirname "${BASH_SOURCE[0]}")/" && pwd -P)

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

command_exists() {
	command -v "$1" >/dev/null 2>&1
}

if [[ ! -f "${PROJECT_ROOT}/.env" ]]; then
	error "${PROJECT_ROOT}/.env does not exists. Exiting ..."
	exit 1
fi

source "${PROJECT_ROOT}/.env"