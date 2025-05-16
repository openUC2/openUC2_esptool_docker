# Dockerfile
FROM python:3.11-slim

# Install git and esptool
RUN apt-get update && \
    apt-get install -y --no-install-recommends git && \
    pip install --no-cache-dir esptool && \
    rm -rf /var/lib/apt/lists/*

# Clone the repo and keep only the firmware_build folder
RUN git clone --depth 1 https://github.com/youseetoo/youseetoo.github.io /tmp/youseetoo_repo && \
    mv /tmp/youseetoo_repo/static/firmware_build /tmp/firmware_build && \
    rm -rf /tmp/youseetoo_repo

WORKDIR /workspace

# Copy the flashing script into the image
COPY flash_if_needed.sh /usr/local/bin/flash_if_needed.sh
RUN chmod +x /usr/local/bin/flash_if_needed.sh

ENTRYPOINT ["/usr/local/bin/flash_if_needed.sh"]