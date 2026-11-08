# Adopting the living-paper skill: rc-dates test case

Claude (Opus 5.5), 8 November 2026, at Barry's request: "use the new living-paper skill and apply it to this repo
as a test case". rc-dates was a mature repository with an anonymous JAS manuscript at 4,949 words against a 5,000-word
limit, a makedoc build, and a 111-check numeric registry. This note records what was done, where the skill was followed
and where it was adapted, and what the test exposed about the skill and its tools.

## What was done

| Step | Result | Commit |
|---|---|---|
| makedoc checkout moved from a stale September feature branch to `main` (3d1934c) and pinned | `manuscript/makedoc.lock.json` | 2eb9f38 |
| Build migrated to `manuscript/settings/build.yaml`, with three profiles: main, supplement and brief | Article renders unchanged (4,949 words, 16 pages); the SI is now built by makedoc, with Figs S1–S3, instead of an ad hoc pandoc step | 2eb9f38 |
| `supplementary.md` renamed `supplement.md`; SI figures moved to `supplement_figures.md`; JAS CSL moved to `manuscript/csl/` | numeric-registry anchors updated | 2eb9f38 |
| `manuscript/estimands.md` written from the October review record, quoting the rejected phrasings | allowed and forbidden phrasings, results by claim range | 8298fb9 |
| `manuscript/claims.csv`: 28 result-level claims with evidence, reproduce command and limit; C04 has strict value bindings | 0 errors; all claims cited | 8298fb9 |
| Stage 7 (realised scatter) integrated into the article and SI (S2.8), using the verified draft | article 4,947 words, abstract 243 | 8298fb9 |
| Brief (two pages, one new figure) and agent guide written | brief 2 pages; render scan clean | 5883796 |
| Independent ledger, span and semantic review by a Claude Sonnet subagent | all 28 values confirmed from evidence; three product errors and eight phrasing issues fixed; claims marked supported | 6dca88f, 72b51d0 |

The root Makefile remains the command index. `make manuscript-check` runs the ledger check, the render scan, makedoc
lint and the reference audit for all profiles, and the 111-check registry.

## Independent review outcome

A Claude Sonnet subagent, which did not write the ledger or the products, re-derived every claim value from the
evidence files with its own code. All 28 were correct. It also found:

- **A pre-existing error in the article (since September).** "The primary and expected-log-density analyses agreed on
  the selected family and direction ... including every all-site oldest and youngest result" was false for family: for
  example, linear increase under oldest retention selected linear in 0.195 of replicates under `l1` and 0.21 under
  `l2`. The scores agree on direction in every replicate. This is corrected in the article, SI and agent guide, and
  recorded in SI S5.
- **A misplaced span.** C18 was attached to a sentence about weaker trends rather than to the full-treatment sentence.
- **Brief phrasings that loosened forbidden ones:**
  - "random selection rarely misled";
  - measurement-error results extended beyond the ten-fold design;
  - "a database often holds only some of those dates", a prevalence claim;
  - "cannot reveal" without "by itself";
  - unqualified "always" and "real trends".
- **Agent-guide trap 3** generalised the ten-fold exponential result to all ratios.

All were fixed. A new claim, C29 (concordant-rule direction), covers a sentence that had no claim. The numeric checker
could not have caught any of these: it verifies numbers, not meaning. That is the case for the skill's semantic review
step.

## Deliberate deviations from the skill

1. **The bibliography stays a Zotero export.** `tools/refs.py` builds `refs.yaml` from Crossref. A trial build gave
   different keys for 25 of the 80 works, and different years for some, because it uses Crossref's `issued` date
   (often the online-first year; for example Carleton 2021 became 2020). Two DataCite DOIs (arXiv, and the ADS AustArch
   dataset) returned 404s and crashed the tool. For a manuscript about to be submitted, the curated Better BibTeX
   export stays authoritative. `references/dois.txt` lists all 78 DOIs for Zotero's magic-wand route, as the global
   policy prescribes. `tools/refs.py` and `references/manual.yaml` were removed as unused.
2. **The article keeps its journal shape.** The skill's article template asks for a pivotal-records table, an
   assumption table, a "what would sharpen the answer" section and a roles section. At 4,947 of 5,000 words there is
   no room. They belong in the supplement and are not yet written there; that is the next tranche. The roles content
   stays in the JAS AI declaration, which Barry finalises.
3. **There are two ledgers for now.** The older `release/claims.csv` (111 row-filter checks, line-anchored) remains in
   force alongside `manuscript/claims.csv`. Converging them means converting row filters into value bindings, which
   the binding format cannot yet fully express (below).
4. **Main and supplement are anonymous** (no `author_metadata`) for double-anonymised review. The brief names authors
   and is marked as not yet reviewed by co-authors.

## Skill and tool findings

1. **`refs.py` diverges from the Better BibTeX keys it claims to match.** 25 of 80 keys differ in this repo, through
   year source, stop-words ("New"), capitalisation and name particles, so a Zotero export does not match. It also
   crashes on non-Crossref DOIs instead of reporting them. Suggestions: prefer `published-print` over `issued` for the
   year; route DataCite DOIs through `https://api.datacite.org/` or report and skip them; test against a real Better
   BibTeX export.
2. **Bindings cannot express a sign, a unit or a rounding transform.** "2,439 years younger" (source −2439.4), "93.4%"
   (source 0.934) and "about 100 years" (source 102.9) cannot be strictly bound, so those spans fall back to the pooled
   check. That check cannot catch a swap between two values of the same claim. Suggestion: optional `scale` and `abs`
   fields, and a rounding tolerance, on a binding row.
3. **Ranges over rows cannot be bound.** Most of this paper's quoted numbers are ranges across truths ("93.4–100%
   across four histories"). A binding selects exactly one row, or counts rows. Suggestion: `{"aggregate": {"op":
   "min"|"max"}}`, which would let the old numeric registry be merged into the ledger.
4. **`same()` accepts a rounding of any value**, so `[11]{.C22}` passes against 10.6 without a declared `~11`. That is
   convenient, but it means a value label like `~11` is never needed. The documentation should say so.
5. **The article template assumes word-count room** for its pivotal-records and assumption tables. For journals with
   hard limits, the skill should direct these sections to the supplement.
6. **makedoc fails on a tmpfs `/tmp`.** Its DOCX step renames a temporary file across devices ("Invalid cross-device
   link") on wsl-laptop since the Ubuntu 26.04 upgrade. Workaround: `TMPDIR` on the repository's filesystem. Fix:
   `shutil.move` instead of `os.rename` in makedoc.
7. **The scaffold's `.gitignore` handling missed a repository-wide `*.pdf` ignore**, so built PDFs would silently go
   untracked. `init_paper.py` could check `git check-ignore manuscript/build/x.pdf` and add the negation.
8. **Stamps break silently after a rebase.** `claims.py` checks only that a stamped commit exists. After rebasing onto
   a remote commit, every stamp pointed at an orphaned pre-rebase hash: it passed locally, but would fail on a fresh
   clone. Suggestion: check `git merge-base --is-ancestor <commit> HEAD`, and warn to restamp.
9. **`init_paper.py` assumes a fresh repository.** In this mature repo the substantive work was migration: the build
   config, renaming the supplement, re-anchoring an existing registry, and integrating pending text. A short
   "migrating an existing paper" section in `SKILL.md` would help: rename the SI first, keep the existing makedoc
   profile settings, and remap any line-anchored checks.

## Fixes made (8 November 2026, at Barry's request)

| Finding | Fix | Where |
|---|---|---|
| 1 refs.py keys and years | Better BibTeX skip words and per-word casing; print year before `issued`; DataCite through doi.org content negotiation; failures reported, not a crash; suffix on key collisions. Agreement with the Zotero export rose from 55 to 72 of 80; the remaining eight differ in the source metadata (title casing, name particles, one record's year, one hand-assigned key), not in the algorithm. rc-dates keeps its Zotero export. | claude-config 397057b |
| 2–3 bindings | Selectors take `aggregate` `min`/`max` and `abs`/`scale` transforms. C19 now carries nine strict bindings across the abstract, Results, Discussion and brief (V006–V014); a swapped range fails, and `abs` binds "2,439 years younger" to −2439.06. | claude-config 397057b; this repo |
| 4 rounding | Documented in `claims.py` and `claims-ledger.md`. | claude-config 397057b |
| 5 article template | `products.md` and `SKILL.md` direct word-limited journals to put these sections in the supplement. | claude-config 397057b |
| 6 makedoc tmpfs | The normalised DOCX is written beside its target, so the replace is atomic and stays on one filesystem; builds no longer need `TMPDIR`. Pinned here. | makedoc 1178639 |
| 7 ignored PDFs | `init_paper.py` adds `!manuscript/build/*.pdf` when a repository-wide rule would hide them (tested). | claude-config 397057b |
| 8 rebased stamps | `claims.py check` fails on stamps that are not ancestors of HEAD (tested with an orphan commit). | claude-config 397057b |
| 9 migration | `SKILL.md` has a "Migrating an existing paper" section. | claude-config 397057b |

## Next tranche

- Supplement sections the skill expects: a pivotal-records table, an assumption table, "what would sharpen the
  answer", and an audit trail of superseded statements (the trap list in the agent guide is the seed).
- Merge `release/claims.csv` into the ledger once bindings support aggregates (finding 3).
- Barry's read-through on the current build. It supersedes the 23 October read-through copies: the rendered text
  differs only by the Stage 7 integration and the contrast notation "$C$ = 0.193".
