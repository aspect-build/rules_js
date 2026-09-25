#!/usr/bin/env bash
# Measure grouping-on shallow retained bytes for chain250 vs chain500.
# Both measurements have grouping enabled. Fresh server per dump.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../../.." && pwd)"
cd "${ROOT}"

FLAG="--@rules_runfiles_group//runfiles_group:enabled"
SMALL="//js/private/test/runfiles_group/stress:chain250_lib249"
LARGE="//js/private/test/runfiles_group/stress:chain500_lib499"
OUT="${TEST_UNDECLARED_OUTPUTS_DIR:-${TMPDIR:-/tmp}}/rules_js_grouping_heap"
mkdir -p "${OUT}"

dump_one() {
  local label="$1"
  local dest="$2"
  bazel shutdown >/dev/null 2>&1 || true
  local cquery_out
  cquery_out="$(mktemp)"
  bazel cquery "${FLAG}" "${label}" >"${cquery_out}" 2>&1
  local config
  config="$(sed -n 's/.*(\([0-9a-f]*\))$/\1/p' "${cquery_out}" | head -1)"
  if [[ -z "${config}" ]]; then
    echo "could not determine configuration of ${label}:" >&2
    cat "${cquery_out}" >&2
    exit 1
  fi
  bazel dump "--memory=shallow,summary,noconfig:configured_target:${label}@${config}" >"${dest}" 2>&1
  rm -f "${cquery_out}"
}

dump_one "${SMALL}" "${OUT}/chain250.txt"
dump_one "${LARGE}" "${OUT}/chain500.txt"
python3 "${ROOT}/js/private/test/runfiles_group/stress/heap_budget.py" \
  "${OUT}/chain250.txt" "${OUT}/chain500.txt" --max-growth 1.3
echo "dumps: ${OUT}/chain250.txt ${OUT}/chain500.txt"
