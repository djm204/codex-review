#!/usr/bin/env bash
#
# tests/run.sh — dependency-free tests for codex-review-loop.sh (pure, network-free paths).
# Run: tests/run.sh
#
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
FIX="$HERE/fixtures"
CODEX="$HERE/../codex-review-loop.sh"

pass=0; fail=0
ok()   { pass=$((pass+1)); printf '  \033[32mok\033[0m   %s\n' "$1"; }
no()   { fail=$((fail+1)); printf '  \033[31mFAIL\033[0m %s\n' "$1"; [ -n "${2:-}" ] && printf '       %s\n' "$2"; }
assert_eq() { [ "$2" = "$3" ] && ok "$1" || no "$1" "expected [$2] got [$3]"; }

echo "codex-review-loop.sh classify"
assert_eq "clean pass detected"      "clean"    "$(bash "$CODEX" classify --input "$FIX/codex-clean.json" | jq -r .status)"
assert_eq "findings detected"        "findings" "$(bash "$CODEX" classify --input "$FIX/codex-findings.json" | jq -r .status)"
assert_eq "finding count (2 inline + 1 review)" "3" "$(bash "$CODEX" classify --input "$FIX/codex-findings.json" | jq -r '.findings | length')"
assert_eq "no new bot activity => working" "working" "$(bash "$CODEX" classify --input "$FIX/codex-working.json" | jq -r .status)"
assert_eq "clean signal wins over stale inline" "clean" "$(bash "$CODEX" classify --input "$FIX/codex-clean-wins.json" | jq -r .status)"
assert_eq "classify reads stdin"     "clean"    "$(bash "$CODEX" classify < "$FIX/codex-clean.json" | jq -r .status)"
assert_eq "Codex review banner is not a finding" "working" "$(bash "$CODEX" classify --input "$FIX/codex-banner-only.json" | jq -r .status)"
assert_eq "banner-only => zero findings" "0" "$(bash "$CODEX" classify --input "$FIX/codex-banner-only.json" | jq -r '.findings|length')"
assert_eq "bare 'looks good / no issues' is clean" "clean" "$(bash "$CODEX" classify --input "$FIX/codex-clean-looksgood.json" | jq -r .status)"

echo "codex-review-loop.sh detect-classify (app list)"
assert_eq "codex installed for all repos => available"  "true"  "$(bash "$CODEX" detect-classify --input "$FIX/apps-with-codex.json" | jq -r .available)"
assert_eq "codex app absent => not available"           "false" "$(bash "$CODEX" detect-classify --input "$FIX/apps-without-codex.json" | jq -r .available)"
assert_eq "selected + this repo included => available"  "true"  "$(bash "$CODEX" detect-classify --input "$FIX/apps-codex-selected-included.json" | jq -r .available)"
assert_eq "selected + this repo excluded => not available" "false" "$(bash "$CODEX" detect-classify --input "$FIX/apps-codex-selected-excluded.json" | jq -r .available)"
assert_eq "all-repo install on owner's account => available"   "true"  "$(bash "$CODEX" detect-classify --input "$FIX/apps-codex-all-right-account.json" | jq -r .available)"
assert_eq "all-repo install on another account => not available" "false" "$(bash "$CODEX" detect-classify --input "$FIX/apps-codex-all-wrong-account.json" | jq -r .available)"
assert_eq "suspended codex install => not available"           "false" "$(bash "$CODEX" detect-classify --input "$FIX/apps-codex-suspended.json" | jq -r .available)"
assert_eq "detect-classify reports source"              "app-list" "$(bash "$CODEX" detect-classify --input "$FIX/apps-with-codex.json" | jq -r .via)"

echo
printf 'Total: %d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
