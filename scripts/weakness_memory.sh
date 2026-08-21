#!/usr/bin/env bash
# Deterministic MEMORY.md weakness-block merge (spec §8–§9).
# Sources demo_common.sh for isolation; never writes real ~/.hermes.
set -euo pipefail

_weakness_memory_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)
if ! declare -F fail_closed >/dev/null 2>&1; then
  # shellcheck source=scripts/demo_common.sh
  source "${_weakness_memory_dir}/demo_common.sh"
fi

CROSSFIRE_WEAKNESS_START='<!-- CROSSFIRE-WEAKNESSES:START -->'
CROSSFIRE_WEAKNESS_END='<!-- CROSSFIRE-WEAKNESSES:END -->'
CROSSFIRE_WEAKNESS_CAP=3
CROSSFIRE_RECORD_SEP=$'\x1f'

crossfire_weakness_fail() {
  echo "weakness_memory: $*" >&2
}

crossfire_normalize_topic_key() {
  local topic="${1:-}"
  topic=$(printf '%s' "$topic" | tr '[:upper:]' '[:lower:]')
  topic=$(printf '%s' "$topic" | sed -E 's/[^a-z0-9]+/-/g; s/-+/-/g; s/^-//; s/-$//')
  printf '%s' "$topic"
}

crossfire_sha256_hex() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 | awk '{print $1}'
  else
    crossfire_weakness_fail "sha256 utility not found"
    return 1
  fi
}

crossfire_compute_weakness_id() {
  local family="${1:-}"
  local topic_key="${2:-}"
  local hash
  hash=$(printf '%s\n%s' "$family" "$topic_key" | crossfire_sha256_hex)
  printf 'w-%s' "${hash:0:12}"
}

crossfire_weakness_family_elements() {
  case "${1:-}" in
    behavioral) printf '%s' 'situation task action result' ;;
    technical) printf '%s' 'problem approach tradeoff verification' ;;
    product) printf '%s' 'user constraint decision metric' ;;
    *) return 1 ;;
  esac
}

crossfire_weakness_is_valid_family() {
  case "${1:-}" in
    behavioral | technical | product) return 0 ;;
    *) return 1 ;;
  esac
}

crossfire_weakness_is_rfc3339_z() {
  local ts="${1:-}"
  [[ "$ts" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
}

crossfire_weakness_is_valid_answer_ref() {
  local ref="${1:-}"
  [[ "$ref" =~ ^[^/]+/[^/]+/[0-9]+$ ]]
}

crossfire_weakness_missing_csv_valid() {
  local family="${1:-}"
  local csv="${2:-}"
  local allowed item
  allowed=$(crossfire_weakness_family_elements "$family") || return 1
  [ -n "$csv" ] || return 1
  local IFS=','
  for item in $csv; do
    item=${item// /}
    [ -n "$item" ] || return 1
    case " $allowed " in
      *" $item "*) ;;
      *) return 1 ;;
    esac
  done
  return 0
}

crossfire_weakness_union_missing_csv() {
  local a="${1:-}"
  local b="${2:-}"
  local -a items=()
  local item seen
  local IFS=','
  for item in $a $b; do
    item=${item// /}
    [ -n "$item" ] || continue
    seen=0
    for existing in "${items[@]:-}"; do
      if [ "$existing" = "$item" ]; then
        seen=1
        break
      fi
    done
    if [ "$seen" -eq 0 ]; then
      items+=("$item")
    fi
  done
  (IFS=','; printf '%s' "${items[*]}")
}

crossfire_weakness_evidence_valid() {
  local kind="${1:-}"
  local value="${2:-}"
  local answer="${3:-}"
  case "$kind" in
    quote)
      [[ "$answer" == *"$value"* ]]
      ;;
    byte_offset)
      local start end len
      if [[ ! "$value" =~ ^[0-9]+:[0-9]+$ ]]; then
        return 1
      fi
      start=${value%%:*}
      end=${value##*:}
      if [ "$start" -ge "$end" ]; then
        return 1
      fi
      len=$(printf '%s' "$answer" | wc -c | tr -d ' ')
      if [ "$end" -gt "$len" ]; then
        return 1
      fi
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

crossfire_weakness_record_pack() {
  local weakness_id="$1" family="$2" topic="$3" topic_key="$4" missing_csv="$5"
  local first_seen="$6" last_seen="$7" observation_count="$8"
  local source_session_id="$9" answer_ref="${10}" evidence_kind="${11}" evidence_value="${12}"
  printf '%s' \
    "${weakness_id}${CROSSFIRE_RECORD_SEP}${family}${CROSSFIRE_RECORD_SEP}${topic}${CROSSFIRE_RECORD_SEP}${topic_key}${CROSSFIRE_RECORD_SEP}${missing_csv}${CROSSFIRE_RECORD_SEP}${first_seen}${CROSSFIRE_RECORD_SEP}${last_seen}${CROSSFIRE_RECORD_SEP}${observation_count}${CROSSFIRE_RECORD_SEP}${source_session_id}${CROSSFIRE_RECORD_SEP}${answer_ref}${CROSSFIRE_RECORD_SEP}${evidence_kind}${CROSSFIRE_RECORD_SEP}${evidence_value}"
}

crossfire_weakness_record_field() {
  local record="$1"
  local idx="$2"
  printf '%s' "$record" | awk -v n="$idx" 'BEGIN { FS = sprintf("%c", 31) } { print $n }'
}

crossfire_weakness_sort_key_evict() {
  local record="$1"
  local last_seen obs wid
  last_seen=$(crossfire_weakness_record_field "$record" 7)
  obs=$(crossfire_weakness_record_field "$record" 8)
  wid=$(crossfire_weakness_record_field "$record" 1)
  printf '%s\t%s\t%s\t%s' "$last_seen" "$obs" "$wid" "$record"
}

crossfire_weakness_memory_fingerprint() {
  local file="${1:-}"
  local mtime size
  if [ ! -e "$file" ]; then
    printf 'absent:0'
    return 0
  fi
  mtime=$(stat -c '%Y' "$file" 2>/dev/null || stat -f '%m' "$file")
  size=$(wc -c <"$file" | tr -d ' ')
  printf '%s:%s' "$mtime" "$size"
}

crossfire_weakness_fsync_file() {
  local file="${1:-}"
  [ -n "$file" ] || return 1
  [ -f "$file" ] || return 1
  if command -v python3 >/dev/null 2>&1; then
    python3 -c "import os, sys; f=open(sys.argv[1], 'rb'); os.fsync(f.fileno()); f.close()" "$file" || return 1
  elif sync -f "$file" 2>/dev/null; then
    :
  else
    crossfire_weakness_fail "fsync failed for $file"
    return 1
  fi
}

crossfire_weakness_release_lock() {
  local lock_file="${1:-}"
  if command -v flock >/dev/null 2>&1; then
    flock -u 9 2>/dev/null || true
  fi
  exec 9>&- 2>/dev/null || true
  [ -n "$lock_file" ] && rm -f "$lock_file"
}

crossfire_weakness_sort_records_for_eviction() {
  local -a records=("$@")
  local -a sorted=()
  local line key
  for line in "${records[@]:-}"; do
    [ -n "$line" ] || continue
    key=$(crossfire_weakness_sort_key_evict "$line")
    sorted+=("$key")
  done
  if [ "${#sorted[@]}" -eq 0 ]; then
    return 0
  fi
  printf '%s\n' "${sorted[@]}" | sort -t $'\t' -k1,1 -k2,2n -k3,3r | cut -f4-
}

crossfire_weakness_apply_cap() {
  local -a records=("$@")
  local -a kept=()
  local line
  if [ "${#records[@]}" -le "$CROSSFIRE_WEAKNESS_CAP" ]; then
    printf '%s\n' "${records[@]}"
    return 0
  fi
  while IFS= read -r line || [ -n "$line" ]; do
    [ -n "$line" ] || continue
    kept+=("$line")
  done < <(crossfire_weakness_sort_records_for_eviction "${records[@]}")
  local drop=$(( ${#records[@]} - CROSSFIRE_WEAKNESS_CAP ))
  local i
  for ((i = 0; i < drop; i++)); do
    kept=("${kept[@]:1}")
  done
  printf '%s\n' "${kept[@]}"
}

crossfire_weakness_yaml_quote() {
  local value="${1:-}"
  if [[ "$value" =~ ^[a-zA-Z0-9._/-]+$ ]]; then
    printf '%s' "$value"
  else
    value=${value//\\/\\\\}
    value=${value//\"/\\\"}
    printf '"%s"' "$value"
  fi
}

crossfire_weakness_render_block() {
  local -a records=("$@")
  local record
  local weakness_id family topic topic_key missing_csv first_seen last_seen
  local observation_count source_session_id answer_ref evidence_kind evidence_value
  local -a missing_items=()
  local item

  printf '%s\n' "$CROSSFIRE_WEAKNESS_START"
  printf '%s\n' '```yaml'
  printf '%s\n' 'version: 1'
  printf '%s\n' 'weaknesses:'
  for record in "${records[@]}"; do
    [ -n "$record" ] || continue
    weakness_id=$(crossfire_weakness_record_field "$record" 1)
    family=$(crossfire_weakness_record_field "$record" 2)
    topic=$(crossfire_weakness_record_field "$record" 3)
    topic_key=$(crossfire_weakness_record_field "$record" 4)
    missing_csv=$(crossfire_weakness_record_field "$record" 5)
    first_seen=$(crossfire_weakness_record_field "$record" 6)
    last_seen=$(crossfire_weakness_record_field "$record" 7)
    observation_count=$(crossfire_weakness_record_field "$record" 8)
    source_session_id=$(crossfire_weakness_record_field "$record" 9)
    answer_ref=$(crossfire_weakness_record_field "$record" 10)
    evidence_kind=$(crossfire_weakness_record_field "$record" 11)
    evidence_value=$(crossfire_weakness_record_field "$record" 12)

    printf '%s\n' "  - weakness_id: $weakness_id"
    printf '%s\n' "    family: $family"
    printf '    topic: '
    crossfire_weakness_yaml_quote "$topic"
    printf '\n'
    printf '%s\n' "    topic_key: $topic_key"
    missing_items=()
    local IFS=','
    for item in $missing_csv; do
      item=${item// /}
      [ -n "$item" ] && missing_items+=("$item")
    done
    printf '    missing_elements: [%s]\n' "$(IFS=','; printf '%s' "${missing_items[*]}")"
    printf '%s\n' "    first_seen: $first_seen"
    printf '%s\n' "    last_seen: $last_seen"
    printf '%s\n' "    observation_count: $observation_count"
    printf '%s\n' "    source_session_id: $source_session_id"
    printf '%s\n' "    answer_ref: $answer_ref"
    printf '%s\n' '    evidence:'
    printf '%s\n' "      kind: $evidence_kind"
    printf '      value: '
    crossfire_weakness_yaml_quote "$evidence_value"
    printf '\n'
  done
  printf '%s\n' '```'
  printf '%s\n' "$CROSSFIRE_WEAKNESS_END"
}

crossfire_weakness_split_memory_file() {
  local file="$1"
  local before_file="$2"
  local block_file="$3"
  local after_file="$4"
  : >"$before_file"
  : >"$block_file"
  : >"$after_file"
  if [ ! -f "$file" ]; then
    return 0
  fi
  awk -v start="$CROSSFIRE_WEAKNESS_START" -v end="$CROSSFIRE_WEAKNESS_END" \
    -v before="$before_file" -v block="$block_file" -v after="$after_file" '
    BEGIN { section="before" }
    {
      sub(/\r$/, "")
      if ($0 == start) { section="block"; print > block; next }
      if ($0 == end) { print > block; section="after"; next }
      if (section == "before") { print > before; next }
      if (section == "block") { print > block; next }
      if (section == "after") { print > after; next }
    }
  ' "$file"
}

crossfire_weakness_parse_missing_inline() {
  local line="${1:-}"
  line=${line#*missing_elements:}
  line=${line# }
  line=${line#[}
  line=${line%]}
  line=${line// /}
  printf '%s' "$line"
}

crossfire_weakness_parse_block_records() {
  local block_file="$1"
  local -a records=()
  local in_yaml=0
  local in_item=0
  local weakness_id="" family="" topic="" topic_key="" missing_csv=""
  local first_seen="" last_seen="" observation_count=""
  local source_session_id="" answer_ref="" evidence_kind="" evidence_value=""
  local line trimmed key val

  if [ ! -s "$block_file" ]; then
    return 0
  fi

  while IFS= read -r line || [ -n "$line" ]; do
    trimmed="$line"
    trimmed="${trimmed//$'\r'/}"
    if [ "$trimmed" = '```yaml' ]; then
      in_yaml=1
      continue
    fi
    if [ "$trimmed" = '```' ] && [ "$in_yaml" -eq 1 ]; then
      in_yaml=0
      continue
    fi
    if [ "$in_yaml" -ne 1 ]; then
      continue
    fi
    case "$trimmed" in
      '  - weakness_id:'*)
        if [ "$in_item" -eq 1 ] && [ -n "$weakness_id" ]; then
          records+=("$(crossfire_weakness_record_pack "$weakness_id" "$family" "$topic" "$topic_key" "$missing_csv" "$first_seen" "$last_seen" "$observation_count" "$source_session_id" "$answer_ref" "$evidence_kind" "$evidence_value")")
        fi
        in_item=1
        weakness_id=${trimmed#  - weakness_id: }
        weakness_id=${weakness_id// /}
        ;;
      '    family:'*)
        family=${trimmed#    family: }
        family=${family// /}
        ;;
      '    topic:'*)
        topic=${trimmed#    topic: }
        topic=${topic#\"}
        topic=${topic%\"}
        ;;
      '    topic_key:'*)
        topic_key=${trimmed#    topic_key: }
        topic_key=${topic_key// /}
        ;;
      '    missing_elements:'*)
        missing_csv=$(crossfire_weakness_parse_missing_inline "$trimmed")
        ;;
      '    first_seen:'*)
        first_seen=${trimmed#    first_seen: }
        first_seen=${first_seen// /}
        ;;
      '    last_seen:'*)
        last_seen=${trimmed#    last_seen: }
        last_seen=${last_seen// /}
        ;;
      '    observation_count:'*)
        observation_count=${trimmed#    observation_count: }
        observation_count=${observation_count// /}
        ;;
      '    source_session_id:'*)
        source_session_id=${trimmed#    source_session_id: }
        source_session_id=${source_session_id// /}
        ;;
      '    answer_ref:'*)
        answer_ref=${trimmed#    answer_ref: }
        answer_ref=${answer_ref// /}
        ;;
      '      kind:'*)
        evidence_kind=${trimmed#      kind: }
        evidence_kind=${evidence_kind// /}
        ;;
      '      value:'*)
        evidence_value=${trimmed#      value: }
        evidence_value=${evidence_value#\"}
        evidence_value=${evidence_value%\"}
        ;;
    esac
  done <"$block_file"

  if [ "$in_item" -eq 1 ] && [ -n "$weakness_id" ]; then
    records+=("$(crossfire_weakness_record_pack "$weakness_id" "$family" "$topic" "$topic_key" "$missing_csv" "$first_seen" "$last_seen" "$observation_count" "$source_session_id" "$answer_ref" "$evidence_kind" "$evidence_value")")
  fi

  if [ "${#records[@]}" -gt 0 ]; then
    printf '%s\n' "${records[@]}"
  fi
}

crossfire_weakness_validate_incoming() {
  local family="$1" topic="$2" missing_csv="$3" last_seen="$4"
  local source_session_id="$5" answer_ref="$6" evidence_kind="$7" evidence_value="$8"
  local submitted_answer="$9"
  local topic_key weakness_id

  [ -n "$family" ] || return 1
  [ -n "$topic" ] || return 1
  [ -n "$missing_csv" ] || return 1
  [ -n "$last_seen" ] || return 1
  [ -n "$source_session_id" ] || return 1
  [ -n "$answer_ref" ] || return 1
  [ -n "$evidence_kind" ] || return 1
  [ -n "$evidence_value" ] || return 1
  [ -n "$submitted_answer" ] || return 1

  crossfire_weakness_is_valid_family "$family" || return 1
  crossfire_weakness_is_rfc3339_z "$last_seen" || return 1
  crossfire_weakness_is_valid_answer_ref "$answer_ref" || return 1
  crossfire_weakness_missing_csv_valid "$family" "$missing_csv" || return 1
  crossfire_weakness_evidence_valid "$evidence_kind" "$evidence_value" "$submitted_answer" || return 1

  topic_key=$(crossfire_normalize_topic_key "$topic")
  [ -n "$topic_key" ] || return 1
  weakness_id=$(crossfire_compute_weakness_id "$family" "$topic_key")
  [ -n "$weakness_id" ] || return 1
  return 0
}

crossfire_weakness_merge_records() {
  local family="$1" topic="$2" missing_csv="$3" last_seen="$4"
  local source_session_id="$5" answer_ref="$6" evidence_kind="$7" evidence_value="$8"
  shift 8 || true
  local -a records=("$@")

  local topic_key weakness_id incoming
  local -a merged=()
  local record wid first_seen obs existing_missing dedup=0 found=0

  CROSSFIRE_WEAKNESS_LAST_OP=changed
  topic_key=$(crossfire_normalize_topic_key "$topic")
  weakness_id=$(crossfire_compute_weakness_id "$family" "$topic_key")
  incoming=$(crossfire_weakness_record_pack "$weakness_id" "$family" "$topic" "$topic_key" "$missing_csv" "$last_seen" "$last_seen" "1" "$source_session_id" "$answer_ref" "$evidence_kind" "$evidence_value")

  for record in "${records[@]:-}"; do
    [ -n "$record" ] || continue
    wid=$(crossfire_weakness_record_field "$record" 1)
    if [ "$wid" = "$weakness_id" ]; then
      found=1
      if [ "$(crossfire_weakness_record_field "$record" 9)" = "$source_session_id" ] && \
         [ "$(crossfire_weakness_record_field "$record" 10)" = "$answer_ref" ]; then
        dedup=1
        merged+=("$record")
        continue
      fi
      first_seen=$(crossfire_weakness_record_field "$record" 6)
      obs=$(crossfire_weakness_record_field "$record" 8)
      existing_missing=$(crossfire_weakness_record_field "$record" 5)
      obs=$((obs + 1))
      merged+=("$(crossfire_weakness_record_pack \
        "$weakness_id" "$family" "$topic" "$topic_key" \
        "$(crossfire_weakness_union_missing_csv "$existing_missing" "$missing_csv")" \
        "$first_seen" "$last_seen" "$obs" \
        "$source_session_id" "$answer_ref" "$evidence_kind" "$evidence_value")")
    else
      merged+=("$record")
    fi
  done

  if [ "$dedup" -eq 1 ]; then
    CROSSFIRE_WEAKNESS_LAST_OP=noop
    printf '%s\n' "${merged[@]}"
    return 0
  fi

  if [ "$found" -eq 0 ]; then
    merged+=("$incoming")
  fi

  crossfire_weakness_apply_cap "${merged[@]}"
}

crossfire_weakness_write_memory_atomic() {
  local memory_md="$1"
  local before_file="$2"
  local block_content_file="$3"
  local after_file="$4"
  local tmp dir

  if declare -F crossfire_require_monday_home >/dev/null 2>&1; then
    crossfire_require_monday_home
  else
    crossfire_require_isolated_hermes_home
    if is_real_hermes_home "$(dirname "$memory_md")"; then
      crossfire_weakness_fail "refusing to write MEMORY.md under real profile tree"
      return 1
    fi
  fi
  dir=$(dirname "$memory_md")
  mkdir -p "$dir"

  tmp=$(mktemp "${memory_md}.XXXXXX")
  {
    if [ -s "$before_file" ]; then
      cat "$before_file"
      if [ -s "$block_content_file" ] || [ -s "$after_file" ]; then
        printf '\n'
      fi
    fi
    if [ -s "$block_content_file" ]; then
      cat "$block_content_file"
      if [ -s "$after_file" ]; then
        printf '\n'
      fi
    fi
    if [ -s "$after_file" ]; then
      cat "$after_file"
    fi
  } >"$tmp"

  if ! crossfire_weakness_fsync_file "$tmp"; then
    rm -f "$tmp"
    return 1
  fi
  mv -f "$tmp" "$memory_md"
}

crossfire_persist_weakness() {
  local memory_md="${1:-}"
  local family="${2:-}"
  local topic="${3:-}"
  local missing_csv="${4:-}"
  local last_seen="${5:-}"
  local source_session_id="${6:-}"
  local answer_ref="${7:-}"
  local evidence_kind="${8:-}"
  local evidence_value="${9:-}"
  local submitted_answer="${10:-}"

  local before block after
  local -a records=() out_records=()
  local record line
  local lock_file
  local merge_out render_out
  local attempt=0 max_attempts=5
  local fp_at_read fp_before_write

  [ -n "$memory_md" ] || {
    crossfire_weakness_fail "memory path required"
    return 2
  }

  if declare -F crossfire_require_monday_home >/dev/null 2>&1; then
    crossfire_require_monday_home
    if [ "$(normalize_path "$memory_md")" != "$(normalize_path "$HERMES_MEMORY_MD")" ]; then
      crossfire_weakness_fail "practice persist path is not Monday MEMORY.md"
      return 2
    fi
  else
    crossfire_require_isolated_hermes_home
    if is_real_hermes_home "$(dirname "$memory_md")"; then
      crossfire_weakness_fail "refusing to write MEMORY.md under real profile tree"
      return 2
    fi
  fi

  before=$(mktemp)
  block=$(mktemp)
  after=$(mktemp)
  merge_out=$(mktemp)
  render_out=$(mktemp)
  trap 'rm -f "$before" "$block" "$after" "$merge_out" "$render_out"' RETURN

  while [ "$attempt" -lt "$max_attempts" ]; do
    attempt=$((attempt + 1))
    records=()

    lock_file="${memory_md}.lock"
    exec 9>"$lock_file"
    if command -v flock >/dev/null 2>&1; then
      flock -x 9
    fi

    fp_at_read=$(crossfire_weakness_memory_fingerprint "$memory_md")
    crossfire_weakness_split_memory_file "$memory_md" "$before" "$block" "$after"
    while IFS= read -r line || [ -n "$line" ]; do
      [ -n "$line" ] && records+=("$line")
    done < <(crossfire_weakness_parse_block_records "$block")

    if ! crossfire_weakness_validate_incoming \
      "$family" "$topic" "$missing_csv" "$last_seen" \
      "$source_session_id" "$answer_ref" "$evidence_kind" "$evidence_value" \
      "$submitted_answer"; then
      crossfire_weakness_release_lock "$lock_file"
      crossfire_weakness_fail "validation failed; leaving original intact"
      return 1
    fi

    : >"$merge_out"
    crossfire_weakness_merge_records \
      "$family" "$topic" "$missing_csv" "$last_seen" \
      "$source_session_id" "$answer_ref" "$evidence_kind" "$evidence_value" \
      "${records[@]:-}" >"$merge_out"

    if [ "${CROSSFIRE_WEAKNESS_LAST_OP:-}" = "noop" ]; then
      crossfire_weakness_release_lock "$lock_file"
      return 0
    fi

    out_records=()
    while IFS= read -r line || [ -n "$line" ]; do
      [ -n "$line" ] && out_records+=("$line")
    done <"$merge_out"

    crossfire_weakness_render_block "${out_records[@]:-}" >"$render_out"

    fp_before_write=$(crossfire_weakness_memory_fingerprint "$memory_md")
    if [ "$fp_before_write" != "$fp_at_read" ]; then
      crossfire_weakness_release_lock "$lock_file"
      continue
    fi

    if ! crossfire_weakness_write_memory_atomic "$memory_md" "$before" "$render_out" "$after"; then
      crossfire_weakness_release_lock "$lock_file"
      return 2
    fi

    crossfire_weakness_release_lock "$lock_file"
    return 0
  done

  crossfire_weakness_fail "write retry limit exceeded after concurrent MEMORY.md change"
  return 2
}

crossfire_weakness_block_count() {
  local file="${1:-}"
  local count=0
  if [ ! -f "$file" ]; then
    printf '0'
    return 0
  fi
  count=$(grep -c "$CROSSFIRE_WEAKNESS_START" "$file" 2>/dev/null || true)
  printf '%s' "${count:-0}"
}

crossfire_weakness_extract_yaml() {
  local file="${1:-}"
  awk -v start="$CROSSFIRE_WEAKNESS_START" -v end="$CROSSFIRE_WEAKNESS_END" '
    { sub(/\r$/, "") }
    $0 == start { capture=1; next }
    $0 == end { capture=0; next }
    capture { print }
  ' "$file"
}
