#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
APP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd -P)"
PORT="${PORT:-8081}"
LOG_DIR="${APP_DIR}/output"
LOG_FILE="${LOG_DIR}/dev-${PORT}.log"

mkdir -p "${LOG_DIR}"

find_listener_pid() {
  if command -v lsof >/dev/null 2>&1; then
    lsof -t -iTCP:"${PORT}" -sTCP:LISTEN 2>/dev/null | head -n 1
    return 0
  fi

  if command -v ss >/dev/null 2>&1; then
    ss -ltnp 2>/dev/null | awk -v port=":${PORT}" '$4 ~ port {print $NF}' | sed -n 's/.*pid=\([0-9]\+\).*/\1/p' | head -n 1
    return 0
  fi

  return 1
}

PID="$(find_listener_pid || true)"

if [ -n "${PID}" ]; then
  echo "Port ${PORT} is already in use by PID ${PID}."
  echo "If this is the dev server you want, open: http://127.0.0.1:${PORT}"
  exit 0
fi

cd "${APP_DIR}"

echo "Starting dev server on port ${PORT}..."
echo "Live log will stream in this terminal."
echo "URL: http://127.0.0.1:${PORT}"

exec npm run dev -- --port "${PORT}" 2>&1 | tee "${LOG_FILE}"
