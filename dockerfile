# Dockerfile
FROM python:3.11-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends git && \
    pip install --no-cache-dir esptool && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
COPY flash_if_needed.sh /usr/local/bin/flash_if_needed.sh
RUN chmod +x /usr/local/bin/flash_if_needed.sh

ENTRYPOINT ["/usr/local/bin/flash_if_needed.sh"]

