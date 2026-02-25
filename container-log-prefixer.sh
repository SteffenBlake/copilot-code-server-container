#!/usr/bin/env bash
set -euo pipefail

svc="${1:-unknown}"
# Prefix every incoming line with: [svc]
# Timestamp is added by s6-log, so this only adds [servicename].
sed -u "s/^/[${svc}] /"
