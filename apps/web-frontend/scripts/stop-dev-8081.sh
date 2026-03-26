#!/usr/bin/env bash
set -euo pipefail

PORT="${PORT:-8081}"

find_listener_pids() {
  if command -v lsof >/dev/null 2>&1; then
    lsof -t -iTCP:"${PORT}" -sTCP:LISTEN 2>/dev/null | sort -u
    return 0
  fi

  if command -v ss >/dev/null 2>&1; then
    ss -ltnp 2>/dev/null | awk -v port=":${PORT}" '$4 ~ port {print $NF}' | sed -n 's/.*pid=\([0-9]\+\).*/\1/p' | sort -u
    return 0
  fi

  return 1
}

PIDS="$(find_listener_pids || true)"

if [ -z "${PIDS}" ]; then
  echo "No listening process found on port ${PORT}."
  exit 0
fi

echo "Stopping port ${PORT} listener(s): ${PIDS}"
kill ${PIDS} 2>/dev/null || true
sleep 1

REMAINING="$(find_listener_pids || true)"
if [ -n "${REMAINING}" ]; then
  echo "Force stopping remaining listener(s): ${REMAINING}"
  kill -9 ${REMAINING} 2>/dev/null || true
fi

echo "Port ${PORT} is now free."
