#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
# Tests use temporary fixtures; no mutation of the business checkout.
node --test tool/agent_indexes/generator.test.js tool/agent_indexes/availability.test.js tool/ci_contracts.test.js
