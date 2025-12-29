---
name: bib-managing
description: Curate and validate BibTeX bibliographies. Composes bob (research/fix) with bibval (validation) and alice (coverage review). Use for adding references, validating existing bibliographies, building citations for documents, or cleaning up .bib files.
---

# Bibliography Management Skill

Curate BibTeX bibliographies with validation against academic databases.

## When to Use

- Adding a citation for a paper (user knows title/author, needs proper BibTeX)
- Validating an existing references.bib file before submission
- Building a bibliography for a draft (identify what needs citing)
- Cleaning up a messy .bib file (dedup, standardize, fill DOIs)

**Don't use for**: Quick one-off lookups where you don't need validated BibTeX. Just ask bob directly.

## Tool: bibval

bibval validates BibTeX against academic databases:

```bash
bibval references.bib              # Validate all entries
bibval references.bib -k key1,key2 # Validate specific entries
bibval references.bib --strict     # Treat warnings as errors
```

**Databases checked**: CrossRef, DBLP, ArXiv, Semantic Scholar, OpenAlex, OpenReview, Zenodo

**Issues detected**:
- Year mismatches
- Title differences
- Author discrepancies
- Missing DOIs

## Composition Patterns

Match agent cost to task complexity:

| Use Case | Agents | Rationale |
|----------|--------|-----------|
| **Add** | bob + bibval | Simple lookup, validation sufficient |
| **Validate** | bibval + bob (fix) | Automated check, bob fixes |
| **Curate** | alice + bob + bibval | Coverage analysis needs reasoning |
| **Clean** | bob + bibval + alice | Dedup + consistency review |

## Quality Rubric

### Pass (bibliography is healthy)

| Criterion | Check |
|-----------|-------|
| **bibval clean** | Exits 0 with no errors |
| **No duplicates** | No duplicate keys or DOIs |
| **Required fields** | All entries have: author, title, year, venue |
| **DOIs present** | DOIs included where available |

### Warn (alice should review)

| Criterion | Check |
|-----------|-------|
| **Low DOI coverage** | >20% entries missing DOIs |
| **Inconsistent keys** | Mix of styles (AuthorYear vs author2024foo) |
| **Venue inconsistency** | Mix of abbreviations (ICML vs Proc. ICML) |
| **Missing seminal works** | Obvious gaps a reviewer would notice |

### Fail (must fix)

| Criterion | Check |
|-----------|-------|
| **bibval errors** | Year/title/author mismatches |
| **Placeholder text** | TODO, TBD, placeholder in fields |
| **Broken cross-refs** | @string or crossref that doesn't resolve |

---

## Workflow 1: Add Reference

User wants to cite a paper. bob finds proper BibTeX, validates, adds to file.

```
bob (search) → bob (bibval) → PASS → append → DONE
                           └→ ERROR → bob (fix) → bibval → PASS/NEEDS_INPUT
```

### Step 1: Research (bob)

```
Task(subagent_type="idle:bob", prompt="Find BibTeX for: <paper description>

Search for the paper on:
1. DBLP (for CS papers)
2. arXiv (for preprints)
3. DOI.org (if you have DOI)
4. Semantic Scholar

Get the official BibTeX. Include DOI if available.
Generate a citation key: <FirstAuthorLastName><Year><FirstWord>

Example key: Vaswani2017Attention")
```

### Step 2: Validate (bob runs bibval)

```bash
# bob appends entry to temp file, validates
echo '<new entry>' >> /tmp/new-entry.bib
bibval /tmp/new-entry.bib
```

If errors: bob fixes the entry (e.g., corrects year, standardizes authors)

### Step 3: Add to Bibliography (bob)

If bibval passes, bob appends to `references.bib`:

```bash
cat /tmp/new-entry.bib >> references.bib
```

### Step 4: Notify

```bash
jwz post "issue:<id>" --role bob \
  -m "[bob] BIB_ADD: <paper>
Key: <citation_key>
DOI: <doi or 'none'>
Status: VALIDATED"
```

---

## Workflow 2: Validate Bibliography

Run bibval on existing references.bib, bob fixes issues.

```
bibval → CLEAN → DONE
      └→ ERRORS → alice (triage) → bob (fix) → bibval → [repeat max 2x] → DONE/NEEDS_INPUT
```

### Step 1: Initial Validation

```bash
bibval references.bib
```

If clean: DONE

### Step 2: Triage (alice)

```
Task(subagent_type="idle:alice", prompt="Review bibval output for references.bib

ERRORS:
<paste bibval errors>

WARNINGS:
<paste bibval warnings>

Categorize:
1. AUTO_FIX: bob can fix (year typos, missing DOIs that exist)
2. VERIFY: Need user to confirm (title changes, author spelling)
3. ACCEPT: Warning is acceptable (e.g., old paper without DOI)

Return list of fixes for bob.")
```

### Step 3: Fix Iteration (bob, max 2)

```
Task(subagent_type="idle:bob", prompt="Fix these bibval issues in references.bib:

<alice's AUTO_FIX list>

For each:
1. Search for correct metadata
2. Update the entry
3. Re-run bibval on that entry

Do NOT modify VERIFY items - flag for user.")
```

### Step 4: Report

```bash
jwz post "issue:<id>" --role bob \
  -m "[bob] BIB_VALIDATE: references.bib
Initial: <X> errors, <Y> warnings
Fixed: <N> entries
Remaining: <M> need user input
Status: CLEAN|NEEDS_INPUT"
```

---

## Workflow 3: Curate for Document

Given a draft, identify what needs citing and build bibliography.

```
alice (analyze) → alice (coverage) → bob (research) → bob (build) → bibval
    → CLEAN → alice (final review) → PASS/REVISE
    → ERRORS → bob (fix, 1x) → bibval → alice (final)
```

### Step 1: Analyze Document (alice)

```
Task(subagent_type="idle:alice", prompt="Analyze draft.md for citation needs

Identify:
1. CLAIMS: Statements that need citations
   - Empirical claims ("X improves Y by Z%")
   - Attribution ("Smith proposed...")
   - Background ("Transformers are...")

2. EXISTING_REFS: Papers already mentioned by name
   - List with enough detail for bob to find

3. MISSING_SEMINAL: Obvious gaps a reviewer would notice
   - Core papers in the field that must be cited
   - Only flag if clearly missing, not comprehensive lit review

Return structured list for bob to research.")
```

### Step 2: Research References (bob)

```
Task(subagent_type="idle:bob", prompt="Research and create BibTeX for these papers:

<alice's list>

For each:
1. Search academic databases
2. Get official BibTeX with DOI
3. Use consistent key format: <Author><Year><Word>

Write all entries to references.bib
Validate with: bibval references.bib")
```

### Step 3: Coverage Review (alice)

```
Task(subagent_type="idle:alice", prompt="Review references.bib against draft.md

Check:
- [ ] All CLAIMS from step 1 have corresponding citations
- [ ] MISSING_SEMINAL works are now included
- [ ] No obvious gaps remain

Return: PASS or REVISE with specific gaps")
```

### Step 4: Notify

```bash
jwz post "issue:<id>" --role alice \
  -m "[alice] BIB_CURATE: draft.md
References: <N> entries
Coverage: PASS|REVISE
Gaps: <list or 'none'>"
```

---

## Workflow 4: Clean Bibliography

Deduplicate, standardize formatting, fill missing DOIs.

```
bob (dedup) → bob (fuzzy dedup) → bob (standardize) → bob (fill DOIs) → bibval → alice (consistency) → PASS/REVISE
```

### Step 1: Automated Deduplication (bob)

```
Task(subagent_type="idle:bob", prompt="Clean references.bib - Phase 1: Deduplication

Automated merges (no judgment needed):
- Exact duplicate keys → keep first, delete rest
- Same DOI, different keys → keep canonical key, delete duplicate
- Identical title+year+author → merge

Fuzzy matches (use judgment):
- Similar titles → check if same work or different
- Same authors, similar year → verify distinct works

Log all changes. Output cleaned file.")
```

### Step 2: Standardize (bob)

```
Task(subagent_type="idle:bob", prompt="Clean references.bib - Phase 2: Standardize

1. Citation keys: Use <Author><Year><Word> format consistently
2. Venues: Standardize abbreviations (pick one style)
3. Authors: Consistent format (First Last vs Last, First)
4. Fill missing DOIs: Search for any entries without DOI

Validate with bibval after changes.")
```

### Step 3: Consistency Review (alice)

```
Task(subagent_type="idle:alice", prompt="Review cleaned references.bib for consistency

Check:
- [ ] Citation key format uniform
- [ ] Venue abbreviations consistent
- [ ] Author format consistent
- [ ] No remaining duplicates
- [ ] DOI coverage acceptable

Return: PASS or REVISE with specific issues")
```

### Step 4: Report

```bash
jwz post "issue:<id>" --role bob \
  -m "[bob] BIB_CLEAN: references.bib
Duplicates removed: <N>
DOIs added: <M>
Entries standardized: <K>
Final count: <total>
Status: CLEAN"
```

---

## Stop Conditions

1. **DONE**: bibval passes AND alice approves (or alice not invoked for simple adds)
2. **MAX_ITERATIONS**: 2 fix cycles completed, still has errors
3. **NEEDS_INPUT**: Issues require user judgment (title changes, ambiguous duplicates)
4. **USER_CANCEL**: User interrupts

## Artifact Location

Bibliography artifacts co-locate with the writing piece:

```
project/
├── paper/
│   ├── draft.md
│   ├── references.bib    ← bibliography here
│   └── figures/
```

NOT in `.claude/plugins/idle/bob/` - the .bib is a primary artifact, not research notes.

## Discovery

```bash
# Find bibliography work
jwz search "BIB_ADD:"
jwz search "BIB_VALIDATE:"
jwz search "BIB_CURATE:"
jwz search "BIB_CLEAN:"

# Check validation status
bibval references.bib

# List all entries
grep -E "^@" references.bib
```

## Example Usage

```bash
# Add single reference
User: "Add the original GPT paper to references.bib"
# → bob searches, validates, appends

# Validate before submission
User: "Check references.bib for errors"
# → bibval runs, bob fixes, alice triages remaining

# Build bibliography for new paper
User: "Create references.bib for paper/draft.md"
# → alice analyzes, bob researches, bibval validates, alice reviews coverage

# Clean messy legacy file
User: "Clean up this old references.bib"
# → bob dedupes/standardizes, bibval validates, alice checks consistency
```
