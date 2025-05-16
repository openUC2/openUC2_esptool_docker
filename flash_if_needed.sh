# flash_if_needed.sh
#!/usr/bin/env bash
set -euo pipefail

# Set serial port, baud rate, and flash address from environment or use defaults
PORT="${ESPPORT:-/dev/ttyUSB0}"
BAUD="${BAUD:-460800}"
FLASH_ADDR="${FLASH_OFFSET:-0x0}"   # Change if your image expects another offset

# Set repository and paths
REPO_URL="https://github.com/youseetoo/youseetoo.github.io"
BIN_PATH="static/firmware_build/esp32_UC2_3_CAN_HAT_Master.bin"
WORKDIR="/tmp/uc2_fw"
DEFAULT_BIN="/tmp/firmware_build/esp32_UC2_3_CAN_HAT_Master.bin"

# Allow user to supply a custom firmware binary via environment variable
USER_BIN="${FIRMWARE_BIN_PATH:-}"

# Determine which firmware binary to use
if [[ "${UPDATE_FIRMWARE:-false}" == "true" ]]; then
  # If update is requested, clone or update the repository and use the binary from there
  if [[ ! -d "$WORKDIR/.git" ]]; then
    git clone --depth 1 "$REPO_URL" "$WORKDIR"
  else
    git -C "$WORKDIR" pull --ff-only
  fi
  FIRMWARE_BIN="$WORKDIR/$BIN_PATH"
elif [[ -n "$USER_BIN" ]]; then
  # If user supplied a custom binary, use it
  FIRMWARE_BIN="$USER_BIN"
else
  # Otherwise, use the default binary
  FIRMWARE_BIN="$DEFAULT_BIN"
fi

# Check if the firmware binary exists
if [[ ! -f "$FIRMWARE_BIN" ]]; then
  echo "Firmware binary not found: $FIRMWARE_BIN"
  exit 1
fi

# Calculate hash of the firmware binary
REMOTE_HASH=$(sha256sum "$FIRMWARE_BIN" | awk '{print $1}')

# Read current firmware region from device (same size as remote image)
SIZE=$(stat --printf="%s" "$FIRMWARE_BIN")
TMP_CURRENT=$(mktemp)

echo "Reading $SIZE bytes from device @ $FLASH_ADDR ..."
esptool.py --port "$PORT" --baud "$BAUD" read_flash "$FLASH_ADDR" "$SIZE" "$TMP_CURRENT" >/dev/null

CURRENT_HASH=$(sha256sum "$TMP_CURRENT" | awk '{print $1}')
rm -f "$TMP_CURRENT"

echo "Remote firmware hash : $REMOTE_HASH"
echo "Device firmware hash : $CURRENT_HASH"

# Compare hashes and flash if different
if [[ "$REMOTE_HASH" != "$CURRENT_HASH" ]]; then
  echo "Hashes differ – flashing new firmware..."
  esptool.py --port "$PORT" --baud "$BAUD" write_flash --flash_size detect "$FLASH_ADDR" "$FIRMWARE_BIN"
  echo "Flash complete."
else
  echo "Firmware already up-to-date – no action taken."
fi