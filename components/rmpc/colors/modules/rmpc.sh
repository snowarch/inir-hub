#!/usr/bin/env bash
# Colour module: runs when iNiR applies a palette and refreshes the rmpc theme (render.sh does the work).
set -euo pipefail
source "${INIR_COLOR_RUNTIME:?run by iNiR: scripts/colors/apply-targets.sh rmpc}"
COLOR_MODULE_ID="rmpc"

if bash "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/render.sh"; then
  log_module "rmpc theme refreshed"
else
  log_module "rmpc theme could not be written"
fi
exit 0
