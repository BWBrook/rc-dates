# rc-dates: path to submission

Started 23 October 2026. Barry and Claude work this through to submission together. On 23 October 2026, Barry closed the
correspondence board with Codex for this manuscript; it reopens only if Barry asks or a stage needs it, and is expected to
reopen for journal revisions. This file is the single checklist. Barry reports after each stage, and Claude updates the
status, the decision log and the next action. Journal-specific detail stays in
`manuscript/submission/submission_checklist.md`.

The manuscript is at commit `40323ca`. It contains 4,949 words against a 5,000 limit, so 51 words are spare, and the
abstract has 239 words against a limit of 250. All 111 registered claims pass and the strict build passes. Count words with
`python3 scripts/release/count_manuscript_words.py <built.docx>`.

## Stages

Each stage closes before the next begins, unless it is marked as able to run in parallel.

### 1. Barry's read-through (now)

- **Files.** `manuscript/submission/dist/barry_readthrough_2026-10-23/`, built from `40323ca`. It holds the main text and
  the SI as DOCX and PDF.
- **How to mark.** Use Word with Track Changes and comments, as many as needed and unresolved if necessary. PDF annotations
  or plain notes also work.
- **Questions to read for.** Is this the argument to make? Will an archaeologist see why it matters? Are the conclusions
  proportionate to the evidence?
- **Claude's part.** Read the tracked changes and comments, apply them to the Markdown source, and keep the numbers and
  methods intact. Rerun the claims audit, the strict build and the word count. Return a disposition table showing what
  was applied, what was adjusted and why, and what needs Barry's decision.
- **Word budget.** Any additions need matching cuts. Claude proposes the cuts, and Barry chooses.
- **Done when** every mark has a disposition and Barry accepts the revised build.

### 2. Science scope gate (decide during stage 1; can run in parallel)

- **The open item.** Realised measurement noise is untested for oldest, youngest and bracketed retention. The abstract and
  Section 4.3 state this limit, and it is the point a dating specialist is most likely to press.
- **Option A.** Prespecify and run one more analysis on `deep-server` while Barry reads, then report the outcome either way.
  The simulation code already has a `realised` observation model on an isolated random-number stream. The production
  runner fixes `curve_mean`, so the change is one runner option plus prespecification. The results would go to the SI,
  and one sentence in Section 4.3 would change, at about zero net words.
- **Option B.** Keep the limit as stated and put the question to the co-authors.
- **Claude recommends Option A.** It is cheap, it closes the most predictable reviewer objection, and the infrastructure
  already exists.

### 3. Pre-circulation tidy (Claude, after stage 1)

- Remove the September draft-status wording from the title page and cover letter, and redate them.
- Draft a Methods-level disclosure of AI assistance, covering the research process, code and visualisation, as Elsevier
  policy expects. It must fit the word budget.
- **AI declaration: Barry finalises.** Codex's role-based draft is in place. Still to settle:
  - the exact system names and versions, including whether "GPT-6 Astra" is a model name;
  - Luke's Claude/Opus use;
  - whether to offer the human–AI correspondence record with the paper.
- Refresh the co-author packet, with the main text, SI and the scientific archive as supporting material.
- Prepare a decision table for co-authors, with each question, its owner and its answer. Silence does not count as
  approval.

### 4. Co-author round (Barry sends; Claude drafts the email)

- Allow 10–14 days, with a calendar deadline.
- Lead with the main text and SI. Offer the archive and review records as supporting material.
- Suggested emphases, while everyone still reads the whole paper:
  - Luke on modelling and computation;
  - Alan and Sean on archaeological interpretation, AustArch provenance and sharing;
  - Rebecca and Chris on framing and implications.
- Ask everyone to confirm:
  - author order, affiliations, ORCIDs, CRediT roles, funding, competing interests and the AI declaration;
  - agreement in principle to submit to JAS;
  - their view on a preprint (stage 7).
- Ask Alan and Sean what basis allows the aggregate archaeological outputs to be released. Ask whether Indigenous data
  governance or further permissions apply, and settle the code licence. The archive already excludes raw and record-level
  AustArch data.

### 5. Consolidate comments (Claude)

- Merge compatible edits and identify contradictory requests.
- Return one disposition table that separates changes made from decisions needing Barry. Barry adjudicates, consulting the
  relevant co-author where needed.
- Avoid circulating repeated full drafts for minor polishing.
- **Done when** every substantive comment has a recorded disposition and the paper tells one coherent story.

### 6. Archive and data availability (Claude prepares; Barry approves the contents)

- **Public record at acceptance or preprint.** Use a versioned Zenodo deposit of the scientific archive. Reserve the DOI so
  it can go into the paper.
- **Review copy.** The review needs an author-anonymised copy. Anonymise the release README, provenance documents, logs and
  metadata, then confirm that the access route preserves anonymity.
- Replace the review-stage data-availability wording with precise access instructions at the right point.

### 7. Preprint decision (Barry, informed by co-authors)

- A named preprint can conflict with the anonymity of double-anonymised review, even where the journal permits preprints.
  Decide whether, when and where to post.
- Recheck the current JAS and Elsevier preprint policy, and the venue's AI-disclosure rules, at the time of deciding.
  Policies read a month ago are not relied on.

### 8. Final approval (all authors)

- Circulate one exact final version of the main text, SI, declarations and archive details.
- Record each author's explicit approval of submission, and of public posting if relevant. Keep the approved files
  unchanged.

### 9. Journal preparation (Claude; can run in parallel with stage 8)

- Recheck the current JAS Guide for Authors for:
  - review mode;
  - word-count scope;
  - abstract and highlight limits;
  - where AI must be disclosed;
  - figure and file formats.
- Finalise the cover letter, highlights and keywords, and draft copy-and-paste answers for the portal.
- **Barry decides:** suggested reviewers and conflicts, and the open-access or publication-cost route, after checking
  institutional coverage.

### 10. Submit (Barry)

- Inspect the review PDF built by the portal for author-identifying text and file metadata, missing figures, broken
  equations and the SI.
- Barry submits. Claude keeps the submitted files, the manuscript number and the confirmation, and tags the submitted
  commit.

## Decision log

| # | Decision | Owner | Status |
|---|---|---|---|
| 1 | Realised-noise check for one-sided and bracketed rules (stage 2) | Barry | Done. Barry chose Option A on 23 Oct 2026. Stage 7 was accepted in `842ec9a`, with all 75 headline rates within 0.001 (gate 0.02). An independent re-aggregation matched all 240 rate rows and 75 headlines exactly, and the text changes, drafted in `manuscript/reviews/claude_stage7_integration_draft_2026-10-23.md`, will be applied after stage 1 |
| 2 | Final AI declaration wording and system versions | Barry | Open |
| 3 | Offer the human–AI correspondence record with the paper | Barry | Open |
| 4 | Author list, order, affiliations, CRediT, funding, competing interests | Co-authors | Open |
| 5 | Basis for releasing aggregate outputs, data governance and code licence | Alan, Sean, Barry | Open |
| 6 | Preprint: whether, when and where | Barry with co-authors | Open |
| 7 | Suggested reviewers and conflicts | Barry | Open |
| 8 | Open-access or publication-cost route | Barry | Open |
