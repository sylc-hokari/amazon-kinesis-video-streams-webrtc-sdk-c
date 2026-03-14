#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  scripts/sync-rpi-sysroot.sh <pi-host> [destination]

Examples:
  scripts/sync-rpi-sysroot.sh raspberrypi.local
  scripts/sync-rpi-sysroot.sh pi@192.168.1.50 /tmp/rpi-sysroot

Environment variables:
  SYSROOT_DIR   Destination directory. Default: ./sysroots/rpi-zero-2w
  SYSROOT_PORT  SSH port. Default: 22
  SYSROOT_SUDO  Remote sudo command. Default: sudo

This script pulls the minimum Raspberry Pi OS sysroot needed for arm64
cross builds from the target device by using rsync over SSH.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

if [[ $# -lt 1 || $# -gt 2 ]]; then
    usage >&2
    exit 1
fi

if ! command -v rsync >/dev/null 2>&1; then
    echo "rsync is required" >&2
    exit 1
fi

if ! command -v ssh >/dev/null 2>&1; then
    echo "ssh is required" >&2
    exit 1
fi

REMOTE_HOST="$1"
DEST_DIR="${2:-${SYSROOT_DIR:-$(pwd)/sysroots/rpi-zero-2w}}"
SSH_PORT="${SYSROOT_PORT:-22}"
REMOTE_SUDO="${SYSROOT_SUDO:-sudo}"

mkdir -p "${DEST_DIR}"

RSYNC_RSH=(ssh -p "${SSH_PORT}")
RSYNC_COMMON_ARGS=(
    --archive
    --hard-links
    --numeric-ids
    --delete
    --delete-excluded
    --info=progress2
    --safe-links
)

sync_path() {
    local remote_path="$1"
    local local_path="${DEST_DIR}${remote_path}"
    local remote_type

    remote_type="$(ssh -p "${SSH_PORT}" "${REMOTE_HOST}" "${REMOTE_SUDO} sh -c 'if [ -d \"${remote_path}\" ]; then echo dir; elif [ -f \"${remote_path}\" ]; then echo file; fi'")"

    if [[ "${remote_type}" == "dir" ]]; then
        mkdir -p "${local_path}"
        rsync \
            "${RSYNC_COMMON_ARGS[@]}" \
            --rsync-path="${REMOTE_SUDO} rsync" \
            -e "${RSYNC_RSH[*]}" \
            "${REMOTE_HOST}:${remote_path}/" \
            "${local_path}/"
    elif [[ "${remote_type}" == "file" ]]; then
        mkdir -p "$(dirname "${local_path}")"
        rsync \
            "${RSYNC_COMMON_ARGS[@]}" \
            --rsync-path="${REMOTE_SUDO} rsync" \
            -e "${RSYNC_RSH[*]}" \
            "${REMOTE_HOST}:${remote_path}" \
            "${local_path}"
    else
        echo "Skipping unsupported path: ${remote_path}"
    fi
}

remote_path_exists() {
    local remote_path="$1"
    ssh -p "${SSH_PORT}" "${REMOTE_HOST}" "${REMOTE_SUDO} test -e '${remote_path}'"
}

echo "Syncing Raspberry Pi sysroot from ${REMOTE_HOST} to ${DEST_DIR}"

for path in \
    /lib \
    /usr \
    /opt/vc \
    /etc/alternatives \
    /etc/ld.so.conf \
    /etc/ld.so.conf.d; do
    if remote_path_exists "${path}"; then
        sync_path "${path}"
    else
        echo "Skipping missing path: ${path}"
    fi
done

echo "Done"
