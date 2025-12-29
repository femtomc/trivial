---
name: technical-writing
description: Write clear technical prose. Composes bob (drafting) with alice (multi-layer review). Applies to papers, docs, blog posts, design docs, READMEs - any technical writing that needs to transfer ideas clearly.
---

# Technical Writing Skill

Write clear technical prose with rigorous multi-layer review.

## When to Use

- Writing technical documentation, design docs, or READMEs
- Drafting blog posts or technical reports
- Writing research papers or whitepapers
- Any technical writing that needs to transfer ideas clearly
- Existing draft needs systematic improvement

**Don't use for**: Quick notes, informal messages, or throwaway text.

## Core Principles

Every sentence serves one goal: **transfer ideas from author to reader**.

1. **Give away the punchline** - State your point upfront, don't bury it
2. **Topic sentences** - First sentence of each paragraph enables scanning
3. **Active voice** - "The system handles X" not "X is handled by the system"
4. **Consistent terminology** - Same concept uses same term throughout
5. **Concrete before abstract** - Examples before generalizations
6. **Figure-first explanations** - Lead with diagrams, standalone captions

These principles come from the best technical writers across domains - from Strunk & White to Simon Peyton Jones to Distill.pub.

## Composition Pattern

**Multi-Layer Review with Bounded Iteration (max 1 revision per layer)**

```
                    bob (draft)
                        │
                        ▼
              ┌─────────────────┐
              │  STRUCTURE      │◄──── alice review
              │  review         │
              └────────┬────────┘
                       │ PASS/REVISE(1x)
                       ▼
              ┌─────────────────┐
              │  CLARITY        │◄──── alice review
              │  review         │
              └────────┬────────┘
                       │ PASS/REVISE(1x)
                       ▼
              ┌─────────────────┐
              │  EVIDENCE       │◄──── alice review
              │  review         │
              └────────┬────────┘
                       │ PASS
                       ▼
                     DONE
```

- Each layer has specific focus (no conflation)
- Max 1 revision per layer keeps cost predictable
- Skip to next layer on PASS
- Stop on NEEDS_INPUT at any layer

## Quality Rubric

### Layer 1: Structure Review

| Criterion | Check |
|-----------|-------|
| **Main point upfront** | Reader knows the point within first paragraph |
| **Logical flow** | Each section follows naturally from the previous |
| **Section balance** | No section dominates inappropriately |
| **Scannable** | Headers and topic sentences tell the story |
| **Completeness** | No obvious gaps in the argument or explanation |

### Layer 2: Clarity Review

| Criterion | Check |
|-----------|-------|
| **Active voice** | No passive constructions obscuring agency |
| **Topic sentences** | First sentence of each paragraph states main point |
| **Consistent terminology** | Same concept uses same term throughout |
| **No weasel words** | Avoid "clearly," "obviously," "simply," "just" |
| **Paragraph coherence** | 3-5 sentences, single idea, transition words |
| **Concrete examples** | Abstract claims grounded in specifics |

### Layer 3: Evidence Review

| Criterion | Check |
|-----------|-------|
| **Claims supported** | Every claim has evidence or reasoning |
| **Examples work** | Code samples run, commands execute |
| **Figures standalone** | Captions explain without requiring text |
| **Links valid** | External references resolve |
| **Accuracy** | Technical details correct and verifiable |

## Workflow

### Step 0: Prerequisites

Gather before starting:
- Topic and scope
- Target audience (who is reading this?)
- Key points to convey
- Supporting material (code, diagrams, data)

### Step 1: Draft (bob)

Invoke bob to draft the content:

```
Task(subagent_type="idle:bob", prompt="Draft technical content on <topic>

Audience: <who is reading>
Purpose: <what should they understand/do after reading>
Key points:
- <point 1>
- <point 2>

Apply principles:
- State main point upfront (first paragraph)
- Topic sentences for every paragraph
- Active voice throughout
- Concrete examples before abstractions
- Consistent terminology")
```

**bob produces**:
- Artifact at `.claude/plugins/idle/bob/<topic>.md`
- Status: DRAFTED | PARTIAL
- Section-by-section content with notes

**bob posts to jwz**:
```bash
jwz post "issue:<id>" --role bob \
  -m "[bob] DRAFT: <topic>
Path: .claude/plugins/idle/bob/<topic>.md
Sections: <count>
Notes: <any gaps or blockers>"
```

### Step 2: Structure Review (alice)

Invoke alice for structural review:

```
Task(subagent_type="idle:alice", prompt="STRUCTURE REVIEW of document at .claude/plugins/idle/bob/<topic>.md

Check against Structure Rubric:
- [ ] Main point upfront: Reader knows the point within first paragraph?
- [ ] Logical flow: Each section follows naturally?
- [ ] Section balance: Proportional to importance?
- [ ] Scannable: Headers and topic sentences tell the story?
- [ ] Completeness: No obvious gaps?

Return: PASS or REVISE with required fixes")
```

**alice returns**: **PASS** | **REVISE**

If REVISE, alice provides Required Fixes (max 3).

### Step 3: Structure Revision (if REVISE)

Re-invoke bob with alice's fixes:

```
Task(subagent_type="idle:bob", prompt="Revise structure at .claude/plugins/idle/bob/<topic>.md

Alice's required fixes:
- <fix 1>
- <fix 2>

Update and re-post.")
```

### Step 4: Clarity Review (alice)

```
Task(subagent_type="idle:alice", prompt="CLARITY REVIEW of document at .claude/plugins/idle/bob/<topic>.md

Check against Clarity Rubric:
- [ ] Active voice: No passive obscuring agency?
- [ ] Topic sentences: First sentence states paragraph's point?
- [ ] Consistent terminology: Same concept = same term?
- [ ] No weasel words: No 'clearly,' 'obviously,' 'simply'?
- [ ] Paragraph coherence: 3-5 sentences, single idea, transitions?
- [ ] Concrete examples: Abstract claims grounded in specifics?

Return: PASS or REVISE with required fixes")
```

### Step 5: Clarity Revision (if REVISE)

Re-invoke bob with alice's clarity fixes.

### Step 6: Evidence Review (alice)

```
Task(subagent_type="idle:alice", prompt="EVIDENCE REVIEW of document at .claude/plugins/idle/bob/<topic>.md

Check against Evidence Rubric:
- [ ] Claims supported: Every claim has evidence or reasoning?
- [ ] Examples work: Code samples correct, commands valid?
- [ ] Figures standalone: Captions explain without text?
- [ ] Links valid: External references resolve?
- [ ] Accuracy: Technical details correct?

Return: PASS or REVISE with required fixes")
```

### Step 7: Evidence Revision (if REVISE)

Re-invoke bob with alice's evidence fixes.

### Step 8: Completion

On all-PASS, document is ready for use.

```bash
jwz post "issue:<id>" --role alice \
  -m "[alice] COMPLETE: Document ready
Path: .claude/plugins/idle/bob/<topic>.md
Reviews passed: STRUCTURE, CLARITY, EVIDENCE
Status: Ready for use"
```

## Stop Conditions

1. All three review layers PASS
2. One revision completed per layer (no infinite loops)
3. NEEDS_INPUT at any layer (missing info, scope unclear)
4. User cancels

## Document Types

The same principles apply across formats, with emphasis shifts:

### Documentation / READMEs
- **Emphasis**: Scannable structure, working examples
- Structure: What → Why → How → Reference
- Every code block must be tested

### Blog Posts / Articles
- **Emphasis**: Hook, narrative flow, concrete examples
- Structure: Hook → Problem → Solution → Implications
- Lead with the interesting part

### Design Docs
- **Emphasis**: Context, alternatives considered, tradeoffs
- Structure: Context → Goals → Design → Alternatives → Plan
- Show your reasoning, not just conclusions

### Research Papers
- **Emphasis**: Contribution clarity, evidence rigor
- Structure: Problem → Contribution → Approach → Evaluation → Impact
- State contributions in introduction (give away the punchline)

### Technical Reports
- **Emphasis**: Completeness, actionable conclusions
- Structure: Executive Summary → Findings → Analysis → Recommendations
- Busy readers read only the summary

## Output

Final deliverables:
- Document artifact: `.claude/plugins/idle/bob/<topic>.md`
- jwz thread on `issue:<id>` with complete review history
- Per-layer verdicts and revision notes

## Example Usage

```bash
# User: "Write documentation for our new API"

# 1. bob drafts documentation following principles
# 2. alice: STRUCTURE REVIEW - REVISE (main point buried in paragraph 3)
# 3. bob: moves key info to opening
# 4. alice: STRUCTURE REVIEW - PASS
# 5. alice: CLARITY REVIEW - REVISE (inconsistent terminology: "endpoint" vs "route")
# 6. bob: standardizes on "endpoint"
# 7. alice: CLARITY REVIEW - PASS
# 8. alice: EVIDENCE REVIEW - REVISE (code example has syntax error)
# 9. bob: fixes code example
# 10. alice: EVIDENCE REVIEW - PASS
# 11. Complete: documentation ready
```

## Discovery

Find prior documents:
```bash
jwz search "DRAFT:"
jwz search "COMPLETE:" | grep "Document ready"
ls .claude/plugins/idle/bob/*.md
```

Find review history:
```bash
jwz search "STRUCTURE REVIEW:"
jwz search "CLARITY REVIEW:"
jwz search "EVIDENCE REVIEW:"
```

## Reference

This skill distills principles from authoritative sources on technical writing:

**Foundational**
- Strunk & White, *The Elements of Style*
- Steven Pinker, *The Sense of Style*
- Joseph Williams, *Style: Toward Clarity and Grace*

**Technical Writing**
- [Simon Peyton Jones - How to Write a Great Research Paper](https://simon.peytonjones.org/great-research-paper/)
- [Kayvon Fatahalian - Systems Paper Guide](https://graphics.stanford.edu/~kayvonf/notes/systemspaper/)
- [Derek Dreyer - How to Write Papers So People Can Read Them](https://people.mpi-sws.org/~dreyer/talks/talk-plmw16.pdf)
- [Michael Ernst - Writing Technical Papers](https://homes.cs.washington.edu/~mernst/advice/write-technical-paper.html)

**Clear Exposition**
- [Distill.pub](https://distill.pub/) - Exemplar of visual, interactive explanation

Full research artifact: `.claude/plugins/idle/bob/technical_writing_cs_venues.md`
