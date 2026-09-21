#!/usr/bin/env bash
# Push dist/recently-added-media-card.js to a local HA instance for manual testing.
#
# Requires: HA config share mapped as a Windows drive letter (see HA_DRIVE below),
# accessible from WSL via cmd.exe (no /mnt/<letter> auto-mount for network drives).
#
# After running, bump the resource URL's ?v= param in HA UI
# (Settings -> Dashboards -> Resources) to the printed value and hard-refresh.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="dist/recently-added-media-card.js"
HA_DRIVE="Z:"
HA_CARD_FILE="recently-added-media-card.js"

# Two copies must stay in sync: the HACS-managed path and the root /local/ path,
# depending on which resource URL the dashboard actually references.
DESTS=(
  "www\\community\\recently-added-media-card\\${HA_CARD_FILE}"
  "www\\${HA_CARD_FILE}"
)

if [[ ! -f "$REPO_DIR/$SRC" ]]; then
  echo "error: $SRC not found in $REPO_DIR" >&2
  exit 1
fi

WSL_UNC_SRC="\\\\wsl.localhost\\Ubuntu${REPO_DIR//\//\\}\\${SRC//\//\\}"
LOCAL_SIZE=$(wc -c < "$REPO_DIR/$SRC")

for DEST_REL in "${DESTS[@]}"; do
  DST="${HA_DRIVE}\\${DEST_REL}"
  echo "copying $SRC -> $DST"
  cmd.exe /c copy /Y "$WSL_UNC_SRC" "$DST"

  REMOTE_SIZE=$(cmd.exe /c dir /-c "$DST" 2>/dev/null | tr -d '\r' | grep -oE '[0-9]+ '"${HA_CARD_FILE}"'$' | grep -oE '^[0-9]+')

  if [[ "$LOCAL_SIZE" != "$REMOTE_SIZE" ]]; then
    echo "warning: size mismatch for $DST (local=$LOCAL_SIZE remote=$REMOTE_SIZE)" >&2
    exit 1
  fi

  echo "verified: $REMOTE_SIZE bytes"
done

NEWV=$(date +%s)
echo
echo "Next step: in HA -> Settings -> Dashboards -> Resources, set the"
echo "recently-added-media-card.js resource URL's ?v= param to: $NEWV"
echo "then hard-refresh the browser."
