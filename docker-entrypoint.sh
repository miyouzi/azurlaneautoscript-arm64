#!/usr/bin/env bash
set -euo pipefail

TZ_VALUE="${TZ:-Asia/Shanghai}"
ZONEINFO="/usr/share/zoneinfo/${TZ_VALUE}"

if [ -e "$ZONEINFO" ]; then
  ln -snf "$ZONEINFO" /etc/localtime
  echo "$TZ_VALUE" > /etc/timezone
else
  echo "[WARN] TZ='$TZ_VALUE' not found in /usr/share/zoneinfo. Keep existing timezone." >&2
fi

exec "$@"
