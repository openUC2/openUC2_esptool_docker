# flash_if_needed.sh
#!/usr/bin/env bash
set -euo pipefail

PORT="${ESPPORT:-/dev/ttyUSB0}"
BAUD="${BAUD:-460800}"
FLASH_ADDR="${FLASH_OFFSET:-0x0}"   # change if your image expects another offset

REPO_URL="https://github.com/youseetoo/youseetoo.github.io"
BIN_PATH="static/firmware_build/esp32_uc2_3.bin"
WORKDIR="/tmp/uc2_fw"

# clone (or update) repository
if [[ ! -d "$WORKDIR/.git" ]]; then
  git clone --depth 1 "$REPO_URL" "$WORKDIR"
else
  git -C "$WORKDIR" pull --ff-only
fi

REMOTE_BIN="$WORKDIR/$BIN_PATH"
REMOTE_HASH=$(sha256sum "$REMOTE_BIN" | awk '{print $1}')

# read current firmware region (same size as remote image)
SIZE=$(stat --printf="%s" "$REMOTE_BIN")
TMP_CURRENT=$(mktemp)

echo "Reading $SIZE bytes from device @ $FLASH_ADDR ..."
esptool.py --port "$PORT" --baud "$BAUD" read_flash "$FLASH_ADDR" "$SIZE" "$TMP_CURRENT" >/dev/null

CURRENT_HASH=$(sha256sum "$TMP_CURRENT" | awk '{print $1}')
rm -f "$TMP_CURRENT"

echo "Remote firmware hash : $REMOTE_HASH"
echo "Device firmware hash : $CURRENT_HASH"

if [[ "$REMOTE_HASH" != "$CURRENT_HASH" ]]; then
  echo "Hashes differ – flashing new firmware..."
  esptool.py --port "$PORT" --baud "$BAUD" write_flash --flash_size detect "$FLASH_ADDR" "$REMOTE_BIN"
  echo "Flash complete."
else
  echo "Firmware already up-to-date – no action taken."
fi

