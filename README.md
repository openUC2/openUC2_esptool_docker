# UC2 ESP2 Auto-Flasher

One-shot Docker setup that checks the SHA-256 hash of the firmware on the attached ESP32 and flashes `esp32_uc2_3.bin` from the youseetoo repository **only if it’s different**.

---

## Files

| File                  | Purpose                                                |
|-----------------------|--------------------------------------------------------|
| `Dockerfile`          | Python 3.11 slim + git + esptool                       |
| `flash_if_needed.sh`  | Clone / pull repo, compare hashes, flash if required   |
| `docker-compose.yml`  | Convenience wrapper                                    |

---

## Quick start

```bash
# build image
docker compose build

# run one-off flash check
docker compose run --rm esp32-flash
````

The container exits when finished.

---

## Changing the serial port

Set **`ESPPORT`** at runtime or edit `docker-compose.yml`.

| Platform | Typical device paths                                |
| -------- | --------------------------------------------------- |
| Linux    | `/dev/ttyUSB0`, `/dev/ttyUSB1`                      |
| macOS    | `/dev/cu.SLAB_USBtoUART`, `/dev/tty.usbserial-1420` |
| Windows  | `COM3`, `COM4` (use `//./COM3` syntax)              |

Examples:

```bash
# macOS example
ESPPORT=/dev/cu.SLAB_USBtoUART docker compose run --rm esp32-flash

# custom baud and flash offset
ESPPORT=/dev/ttyUSB1 BAUD=921600 FLASH_OFFSET=0x1000 docker compose run --rm esp32-flash
```

---

## What happens inside

1. Clone (or pull) `https://github.com/youseetoo/youseetoo.github.io`
2. Compute SHA-256 for `static/firmware_build/esp32_uc2_3.bin`
3. Read the same-length block from the ESP32 flash (`FLASH_OFFSET`, default `0x0`) and hash it
4. Flash image only when hashes differ (`esptool.py write_flash`)

---

## Notes

* `devices` + `privileged: true` in `docker-compose.yml` grant USB access.
  Adjust or add udev rules as needed on Linux.
* Ensure `FLASH_OFFSET` matches the linker address used to build your firmware.
* Container is non-restarting (`restart: "no"`). Remove the key if orchestrator warnings appear.


