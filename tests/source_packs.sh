#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
SRC="$REPO_ROOT/skills/crossfire-interviewer/sources"
pass=0
fail=0
ok() { echo "PASS: $1"; pass=$((pass + 1)); }
bad() { echo "FAIL: $1"; fail=$((fail + 1)); }

for id in mccain-cyber-defense mastercard-r-281517 praetor alter-ego; do
  [ -f "$SRC/$id.md" ] && ok "exists $id" || bad "exists $id"
done

mccain=$(cat "$SRC/mccain-cyber-defense.md")
printf '%s' "$mccain" | grep -qiE 'Praetor|ALTER_EGO|Agent Suite|R-281517|advisory-only|never-contain' \
  && bad "mccain leak" || ok "mccain leak"

mc=$(cat "$SRC/mastercard-r-281517.md")
printf '%s' "$mc" | grep -qiE 'Praetor|ALTER_EGO|McCain|advisory-only|never-contain|KL-divergence' \
  && bad "mastercard leak" || ok "mastercard leak"

pr=$(cat "$SRC/praetor.md")
printf '%s' "$pr" | grep -qiE 'McCain|ALTER_EGO|Agent Suite|R-281517|KL-divergence|shadow profile' \
  && bad "praetor leak" || ok "praetor leak"

ae=$(cat "$SRC/alter-ego.md")
printf '%s' "$ae" | grep -qiE 'McCain|Praetor|Agent Suite|R-281517|advisory-only|never-contain' \
  && bad "alter-ego leak" || ok "alter-ego leak"

SKILL="$REPO_ROOT/skills/crossfire-interviewer/SKILL.md"
grep -q '## Practice interviewer (session JD)' "$SKILL" && ok "skill procedure heading" || bad "skill procedure heading"
grep -q 'q_technical_01' "$SKILL" && ok "demo q_technical_01 remains" || bad "demo q_technical_01 remains"
grep -Fq 'Walk through how Praetor decides not to contain' "$SKILL" && ok "demo question verbatim" || bad "demo question verbatim"
grep -q 'temperature' "$SKILL" && ok "skill mentions temperature" || bad "skill mentions temperature"
grep -q 'Skip' "$SKILL" && ok "skill mentions Skip" || bad "skill mentions Skip"
grep -Fq 'Tell me more about that' "$SKILL" && ok "skill probe: short answer" || bad "skill probe: short answer"
grep -Fq 'What was the hardest part of that for you personally?' "$SKILL" && ok "skill probe: rehearsed" || bad "skill probe: rehearsed"
grep -q 'Forbidden interviewer moves' "$SKILL" && ok "skill forbids coaching" || bad "skill forbids coaching"
grep -Fq 'flavors voice only' "$SKILL" && bad "skill persona still voice-only" || ok "skill persona not voice-only"
grep -Fq 'that are not in the session JD' "$SKILL" && bad "skill still JD-only invent lock" || ok "skill invent lock is employer-scoped"
grep -q 'lens on this JD' "$SKILL" && ok "skill persona is lens" || bad "skill persona is lens"
grep -Fq 'Domain knowledge implied by the persona is allowed' "$SKILL" && ok "skill allows persona domain" || bad "skill allows persona domain"
grep -Fq "not a second JD" "$SKILL" && ok "skill persona not second JD" || bad "skill persona not second JD"

echo "source_packs: passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
