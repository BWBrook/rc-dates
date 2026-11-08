# Adopting the living-paper skill: rc-dates test case

Claude (Opus 5.5), 8 November 2026, at Barry's request: "use the new living-paper skill and apply it to this repo
as a test case". rc-dates was a mature repository with an anonymous JAS manuscript at 4,949 words against a 5,000-word
limit, a makedoc build, and a 111-check numeric registry. This note records what was done, where the skill was followed
and where it was adapted, and what the test exposed about the skill and its tools.

## What was done

| Step | Result | Commit |
|---|---|---|
| makedoc checkout moved from a stale September feature branch to `main` (3d1934c) and pinned | `manuscript/makedoc.lock.json` | 30a5904 |
| Build migrated to `manuscript/settings/build.yaml`, with three profiles: main, supplement and brief | Article renders unchanged (4,949 words, 16 pages); the SI is now built by makedoc, with Figs S1–S3, instead of an ad hoc pandoc step | 30a5904 |
| `supplementary.md` renamed `supplement.md`; SI figures moved to `supplement_figures.md`; JAS CSL moved to `manuscript/csl/` | numeric-registry anchors updated | 30a5904 |
| `manuscript/estimands.md` written from the October review record, quoting the rejected phrasings | allowed and forbidden phrasings, results by claim range | 10db22d |
| `manuscript/claims.csv`: 28 result-level claims with evidence, reproduce command and limit; C04 has strict value bindings | 0 errors; all claims cited | 10db22d |
| Stage 7 (realised scatter) integrated into the article and SI (S2.8), using the verified draft | article 4,947 words, abstract 243 | 10db22d |
| Brief (two pages, one new figure) and agent guide written | brief 2 pages; render scan clean | (Phase 3) |
| Independent ledger, span and semantic review by a Claude Sonnet subagent | see below | (Phase 4) |

The root Makefile remains the command index. `make manuscript-check` runs the ledger check, the render scan, makedoc
lint and the reference audit for all profiles, and the 111-check registry.

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
8. **`init_paper.py` assumes a fresh repository.** In this mature repo the substantive work was migration: the build
   config, renaming the supplement, re-anchoring an existing registry, and integrating pending text. A short
   "migrating an existing paper" section in `SKILL.md` would help: rename the SI first, keep the existing makedoc
   profile settings, and remap any line-anchored checks.

## Next tranche

- Supplement sections the skill expects: a pivotal-records table, an assumption table, "what would sharpen the
  answer", and an audit trail of superseded statements (the trap list in the agent guide is the seed).
- Merge `release/claims.csv` into the ledger once bindings support aggregates (finding 3).
- Barry's read-through on the current build. It supersedes the 23 October read-through copies: the rendered text
  differs only by the Stage 7 integration and the contrast notation "$C$ = 0.193".
