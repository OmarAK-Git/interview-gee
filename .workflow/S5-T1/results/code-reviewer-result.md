# S5-T1 code review — Source packs and parser

**Packet:** `.workflow/S5-T1/packets/03-review.md`
**Reviewer:** code-reviewer (did not author this code)
**Date:** 2026-08-23
**Kind:** scoped review of Task 1 packs + stdlib parser
**Scope:** `app/packs.py`, `tests/test_packs.py`, `tests/source_packs.sh`, `skills/crossfire-interviewer/sources/*.md`

Implementer report treated as unevidenced. Plan Task 1 (`docs/superpowers/plans/2026-08-23-practice-interviewer.md` through the line before Task 2) and design §4 are the spec.

**Verdict:** `approve`

| Priority | Count |
| --- | --- |
| Critical | 0 |
| Important | 0 |
| Minor | 3 |
| Blocking | 0 |

**Retry:** no

**Strongest issue:** `require_session_jd` joins unsanitized `pack_id` into a filesystem path (`app/packs.py:106`). Confirmed `pack_id="../SKILL"` resolves to `skills/crossfire-interviewer/SKILL.md` and is read. Local-only today; sanitize before Task 3 HTTP.

---

## Spec compliance

| Requirement | Result | Evidence |
| --- | --- | --- |
| Four packs exist (McCain / Mastercard / Praetor / ALTER_EGO) | **Met** | `skills/crossfire-interviewer/sources/{mccain-cyber-defense,mastercard-r-281517,praetor,alter-ego}.md` |
| Each pack: id, facts, 4–6 competencies, core and edge | **Met** | Independent parse (below). All four have 3–6 facts, 5 competencies, both bands. |
| One family per competency row | **Met** | Each row has one of `behavioral` / `technical` / `product`. ALTER_EGO front matter is `technical,behavioral` as the plan specifies (packet AC “one family each” means per competency, not per pack). |
| Cross-pack leak check | **Met** | Fresh `tests/source_packs.sh`: `passed=8 failed=0`. Mastercard has no `advisory-only` / `Praetor`. |
| `require_session_jd` rejects missing JD; pack/paste return `source_id`, `source_label`, `context_text` | **Met** | `app/packs.py:130` raise; pack/paste dicts include the three keys. Tests cover reject + pack + paste. |
| `normalize_temperature` default 2; reject 0 and 6 | **Met** | `app/packs.py:14-22`; unittest. |
| Stdlib only; no new dependencies | **Met** | `re` + `pathlib` only. No requirements file added. |
| No pre-written tail question lists | **Met** | Packs are facts + competency table only. Wording matches plan Step 3, not a question script. |
| SKILL.md demo questions / practice UI / persist topics untouched | **Met** | `git status` does not list `SKILL.md`, `app/server.py`, `app/static/*`, or `scripts/practice_session.sh`. Demo `q_technical_01` string still in SKILL.md. |
| Tests never mutate real `~/.hermes` | **Met** | Unit tests only read packs + call pure functions. Leak script only `cat`/`grep`s source files. |
| Demo 1.0.0 untouched | **Met** | No demo script or SKILL.md edits in this diff. |
| Files allowed | **Met** | Product files are exactly the Task 1 set. `memory-bank/activeContext.md` is a 1-line orchestrator status tweak, not parser code. |
| Plan Step 4 APIs | **Met** | `parse_pack_file`, `list_source_packs`, `normalize_temperature`, `slug_paste`, `require_session_jd` present with specified keys. `PACKS_DIR` is in the interfaces table but not in the Step 4 code block; omitted to match the code block (Task 3 defines `PACKS` locally). Not a defect. |
| Pack contents match plan Step 3 | **Met** | All four markdown files match the plan text (CRLF only). |

Packet review-diff showed `Â·` on the label line. On-disk `app/packs.py:112` is U+00B7 MIDDLE DOT (`0xb7`), as in the plan. Packet mojibake, not a product bug.

---

## Independent verification (not implementer output)

```
py -3 -m unittest tests.test_packs -v
Ran 6 tests in 0.001s
OK
```

```
"C:\Program Files\Git\bin\bash.exe" tests/source_packs.sh
PASS: exists mccain-cyber-defense
PASS: exists mastercard-r-281517
PASS: exists praetor
PASS: exists alter-ego
PASS: mccain leak
PASS: mastercard leak
PASS: praetor leak
PASS: alter-ego leak
source_packs: passed=8 failed=0
```

Fresh parse of all four packs via `list_source_packs`:

| id | facts | comps | bands | competency families |
| --- | --- | --- | --- | --- |
| alter-ego | 6 | 5 | core, edge | behavioral, technical |
| mastercard-r-281517 | 4 | 5 | core, edge | product |
| mccain-cyber-defense | 3 | 5 | core, edge | behavioral |
| praetor | 6 | 5 | core, edge | technical |

---

## Findings

### Critical

None.

### Important

None. Path traversal on `pack_id` was considered for Important because Task 3 will pass JSON `pack_id` into this function and `app/server.py:93-94` already contains a resolve-and-contain check for static files. Downgraded: Task 1 is local, plan-specified, and `parse_pack_file` fail-closes on non-pack shape. Track as Minor 1; do not ship Task 3 without the fix.

### Minor (track)

#### Minor 1 — `app/packs.py:106` unsanitized `pack_id` path join

```python
path = sources_dir / f"{pack_id}.md"
```

`pack_id="../SKILL"` (and `..\\SKILL`) resolves to `skills/crossfire-interviewer/SKILL.md`; `path.is_file()` is true and `parse_pack_file` reads it (then raises `invalid pack shape`). Any well-formed pack `.md` outside `sources/` would be accepted as the session JD.

**Fix:** reject non-slug ids and require containment:

```python
if not re.fullmatch(r"[a-z0-9-]+", pack_id or ""):
    raise ValueError(f"unknown pack {pack_id!r}")
path = (sources_dir / f"{pack_id}.md").resolve()
if path.parent != sources_dir.resolve() or not path.is_file():
    raise ValueError(f"unknown pack {pack_id!r}")
```

Do this before Task 3 wires `/api/session/start`.

#### Minor 2 — `app/packs.py:85-86` parser does not enforce AC shape beyond count

Shape check is `id`, `employer`, and competency count 4–6. It does not require non-empty `facts` or both `core` and `edge`. Shipped packs satisfy AC (verified above); a later pack could drop facts or ship core-only and still parse.

**Fix:** after building `competencies`:

```python
bands = {c["band"] for c in competencies}
if not facts or bands != {"core", "edge"} and not ({"core", "edge"} <= bands):
    raise ValueError(f"invalid pack shape: {path}")
```

(Use `{"core", "edge"} <= bands`.)

#### Minor 3 — `tests/test_packs.py:30-46` only Mastercard is shape- and leak-tested in unittest

`test_four_required_packs_exist` only checks the id set. Core/edge, facts, and Praetor-token absence are asserted for Mastercard only. McCain / Praetor / ALTER_EGO rely on the bash leak script plus this review’s parse. Tests are not vacuous (they read real files and would fail if `packs` or the four ids were missing), but they could pass a core-only McCain pack.

**Fix:** loop the four ids and assert `facts`, both bands, and 4–6 competencies; keep bash as the cross-pack token contract.

---

## Correctness / security / simplicity / tests (audit)

**Correctness**

- Front-matter `split("---", 2)` leaves table `---` rows in the body; shipped CRLF packs parse.
- `normalize_temperature` accepts `None`/`""`→2, `"4"`→4, rejects `0`/`6`.
- `slug_paste("Acme SWE\n…")` → `pasted-acme-swe`; empty → `pasted-jd`.
- Paste `context_text` is stripped; pack `context_text` is full file `raw.strip()` (facts + competencies). Intended allowlist for the session.
- `list_source_packs` globs `*.md` and parses each; extra non-pack `.md` would fail the whole list (acceptable for a four-file library).

**Security**

- No secrets, no new deps, no deserialization.
- Path join: Minor 1.
- Tests do not touch `~/.hermes`.

**Simplicity**

- Implementation matches plan Step 4 almost verbatim. No extra APIs (`start_session_args` correctly left for Task 3).
- `REQUIRED_IDS` (`app/packs.py:9-11`) is unused (also unused in the plan code). Dead constant; not a defect. Could back Minor 1’s slug check later, but design §4 says new library JDs are new files, so do not hard-allowlist only these four at runtime.

**Tests**

- `tests/test_packs.py` matches the plan block. Exercises exist, Mastercard shape, temperature, JD reject, pack, paste.
- `tests/source_packs.sh` matches the plan block (exists + leak; it does not parse — parse is the unittest). File-structure table said “parse”; plan Step 5 script does not. Combined coverage meets AC.
- Could they pass without the behavior? Not for the specified cases: missing module, missing pack files, wrong Mastercard facts, temperature 0/6, missing JD, or Praetor leak on Mastercard all fail.

**Out of scope / not findings**

- `memory-bank/activeContext.md` still says “implementer dispatched” — orchestrator line, not Task 1 product.
- Design §4 YAML `families: [product]` vs plan `families: product`. Parser is comma-split, not YAML. Shipped packs use the plan form.
- Competency lines that read like questions are the plan’s competency column, not a tail-question list.

---

## What was checked so approve is auditable

1. Read packets `03-review.md`, `02-implementation.md`, `03-review-diff.md`; implementer result (unevidenced); plan Task 1 only; design §4.
2. Read live `app/packs.py`, `tests/test_packs.py`, `tests/source_packs.sh`, all four pack files.
3. `git status` / `git diff --stat` for scope (SKILL.md, server, UI, persist wrapper not in this diff).
4. Byte check: label separator is U+00B7; packs are UTF-8, no BOM, CRLF.
5. Re-ran `py -3 -m unittest tests.test_packs -v` and Git Bash `tests/source_packs.sh`.
6. Re-parsed all four packs for facts / count / bands / families.
7. Probed `require_session_jd("pack", "../SKILL", …)` — reads outside `sources/` (Minor 1).
8. Grepped sources for leak tokens; grepped SKILL.md for demo `q_technical_01` verbatim.
