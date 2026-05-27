#!/bin/bash
set -e

cd "$(dirname "$0")/.."

IMAGE_NAME="${IMAGE_NAME:-php-crud-app}"
CONTAINER_NAME="${CONTAINER_NAME:-php-crud}"
ENV_FILE="${ENV_FILE:-.env}"

if [ ! -f "${ENV_FILE}" ]; then
    echo "Missing ${ENV_FILE}. Create it from the example:"
    echo "  cp .env.example .env"
    exit 1
fi

set -a
# shellcheck disable=SC1090
. "${ENV_FILE}"
set +a

PORT="${PORT:-8080}"
HOST_HTTP_PORT="${HOST_HTTP_PORT:-${PORT}}"

echo "Using ${ENV_FILE}"
echo "Publishing ${HOST_HTTP_PORT}:${PORT}"

docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true

docker run -d \
    --name "${CONTAINER_NAME}" \
    --env-file "${ENV_FILE}" \
    -v "$(pwd)/${ENV_FILE}:/run/config/.env:ro" \
    -p "${HOST_HTTP_PORT}:${PORT}" \
    "${IMAGE_NAME}"

echo ""
echo "Health check: curl http://127.0.0.1:${HOST_HTTP_PORT}/health"
echo "App URL:      http://<vm-public-ip>:${HOST_HTTP_PORT}"
echo "Logs:         docker logs -f ${CONTAINER_NAME}"
