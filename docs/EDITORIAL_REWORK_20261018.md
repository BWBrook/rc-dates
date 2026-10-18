# Manuscript reworking for editors and specialists

## Brief and current state

Barry requested substantial reworking in asynchronous collaboration with
Claude on 18 October 2026. His priority is a paper whose novelty, argument and
implications engage an expert editor outside the immediate speciality while
remaining convincing to specialists. He explicitly anticipates iteration.
His exact request and Codex's first proposition are in correspondence
discussion **88**, first message **1908**.

The starting checkout was clean `e40bfb6`, including Claude's September 29 prose
pass, ecological bridge and archive-wording revisions. The previous evidence
and submission packages are not replaced by exploratory editorial drafts.

## First proposition

Organise the paper around the difference between equal site contributions and
representative age contributions. Lead with the controlled reversal of
inferred direction, develop bracketed retention as a second result showing
that correct direction need not mean correct temporal form, and use the
AustArch benchmark to establish the scale of deformation in a real archive.

The established order-statistic mechanism is not a novelty claim. The argument
must explain what the radiocarbon experiment adds and where its implications
stop. Claude is asked to challenge this interpretation and offer a competing
structure, not merely polish the proposed wording.

## Working files and ownership

- Codex's initial alternatives: `manuscript/reviews/codex_editorial_rework_2026-10-18.md`.
  This contains two titles/abstracts, an opening sequence, a Discussion
  centrepiece, objections and a proposed architecture. Abstracts are 226 and
  217 whitespace-delimited words. All 18 citation keys are in the current
  bibliography; that mechanical check is not a fresh literature audit.
- Suggested Claude draft: `manuscript/reviews/claude_editorial_rework_2026-10-18.md`.
  Claude has been asked to reply in discussion 88 and use this separate file
  for proposals. Codex owns canonical integration to avoid concurrent edits.
- Source copies, hashes and a 14-item content contract with exact supporting
  excerpts: ignored `tmp/editorial_rework_20261018/`. These support comparison;
  the tracked manuscript remains the authoritative scientific reference.

## Protected meanings

Preserve the distinction between simulated and empirical inference; post hoc
retention and prospective context selection; direction and generating-family
selection; relative temporal shape and population abundance. Preserve the
full-site scope of the universal-in-replicates results, the ten-fold truth
scope of random-retention performance, and the partial-treatment mixture.

Keep the empirical lack of random-2, bracketed sensitivity failure, main
observation model's omission of realised scatter, historical growth-only
candidate set, failed prespecified noise screen and post-unblinding diagnostic
explicit. Retain bracketed working independence and the distinction between
natural linear and imposed exponential bounds. No frozen evidence or
simulation semantics change as part of this editorial exercise.

## Integrated candidate, 18 October 2026

Claude's reply in message 1919 proposed a concrete archaeological opening,
simulation-first Results and an explanatory mechanism figure. Codex adopted
that structure with the qualifications discussed in messages 1931 and 1940.
Message 1942 supplied the complete integrated manuscript for Claude's review.

The candidate title is **Choosing among a site's radiocarbon dates can create
or reverse regional trends**. The 230-word abstract and opening make the
inferential consequence explicit. The opening's difference of more than 5,500
years is the separation between the oldest-retained and youngest-retained SPD
means (5,571.602 years in the accepted aggregate evidence); it is not a measure
of uncertainty about actual population history or the total-variation gate.

The Results now proceed from inferred direction, through the distinction
between direction and temporal form, to deformation of the empirical curves.
The Discussion explains what the tested agreement measures can miss, what
selection metadata would change in practice, and where the experiment stops.
It does not claim that every diagnostic must miss retention bias, that the
order-statistic mechanism is new, or that the experiment estimates how often
archaeologists retain extreme dates.

Figure order is now:

| Current location | Content | Source |
|---|---|---|
| Figure 1 | Exact-age retention mechanism | New analytic illustration |
| Figure 2 | Direction selection | Previous Figure 3 |
| Figure 3 | Bounded endpoint contrasts | Previous Figure 4 |
| Figure 4 | Generating-family selection | Previous Figure 5 |
| Figure 5 | Empirical retained-minus-baseline curves | Previous Figure 2 |
| Supplementary Figure S3 | All-date empirical summaries | Previous Figure 1 |

The new figure uses the equations already in Supplementary Section S2.6 and
five independent ages per hypothetical site. It is not a calibrated simulation
or a fitted demographic history. Its Python renderer is available through
`make concept-figure`; the locked R environment and accepted figure files are
unchanged. The supplement's added figure and caption are kept together in both
PDF and Word. The submission build also now respects `SUBMISSION_DIST` for SI
outputs, which previously went to the default directory.

## Verification and retained qualifications

- `make manuscript-check` passed strict source and reference checks, 38 builder
  tests and the build. These are document checks, not new scientific tests.
- All 82 declarative numerical-claim checks passed against accepted aggregate
  evidence. Only manuscript line anchors changed in `release/claims.csv`.
- All 45 distinct main-text citation keys and all four displayed equations
  were retained; the equations are byte-identical to the baseline.
- A 14-item textual preservation audit retained every protected commitment:
  full versus partial treatment, direction versus generating family,
  conditional empirical ranges, no empirical random-2 comparator, the
  bracketed `Y`-only failure, independent site-label simulations, ten-fold
  signal scope, working independence, the original parameter boundaries,
  prospective versus post hoc selection, and the failed prespecified noise
  screen versus its post-unblinding diagnostic.
- Independent numerical checks of the analytic figure verified unit
  integrals, extrema-CDF derivatives and moments. Maximum integral error was
  below 1e-9 and derivative error below 2e-8.
- Main PDF (15 pages), SI PDF (10 pages), and LibreOffice renders of Word
  (19 and 12 pages respectively) were inspected. A split SI figure/caption
  was repaired and the affected pages rechecked. PDF structural checks passed.
- No accepted simulation results, original figure files, frozen provenance
  or `renv.lock` were changed. No heavy analysis was rerun by Codex.

Detailed source excerpts, candidate excerpts, adjudications, numerical-check
outputs, build logs and rendered inspection images are in the ignored working
directory `tmp/editorial_rework_20261018/`. The content contract and manual
review use the Jev-assisted-writing workflow, but no live Jev evaluation was
run and no reader-preference score is claimed.

The review files are in
`manuscript/submission/dist/editorial_rework_2026-10-18/`.
The manuscript source SHA-256 is
`cfc21c57001774b6cc6c38bc454c554b01296f5a82de5e640ffcf07da4000255`.
The source is still an editorial candidate, not an author-approved submission.
The prior co-author ZIPs and scientific release were not regenerated. Once
the editorial/scientific content is accepted, the release source inventory,
figure reproduction instructions, manifests and submission package need to
be refreshed together, including the new analytic renderer.

Claude separately reported a Stage 6 extension to weaker simulated changes in
message 1940. His specification and execution/summary/figure scripts remain
his work. This candidate uses only accepted evidence and still says that
intermediate signal strengths were not tested. Stage 6 should alter that
statement only after its prespecified checks and independent verification.
Codex's message 1950 also asks that constant-history success be shown separately
from correct-direction curves, and that any pooling of increasing and
decreasing truths be explicit.

## Acceptance and next exchange

An editor should be able to explain the question, what is added beyond known
sampling effects, the decisive result and its practical consequence after
reading the abstract and opening page. A specialist should be able to locate
the estimand, comparator, observation assumptions and limits that support each
claim. A full candidate must also preserve essential citations and pass the
existing manuscript and numerical-claim checks after integration.

Next: Claude's sceptical reading of the complete candidate, assessing both the
first-page editorial case and the specialist's strongest objections. Codex has
finished the integration and verification pass and will hand canonical editing
back explicitly in discussion 88. Model agreement or preference scores will
not be treated as scientific validation. Any newly accepted simulation evidence
requires its own scientific integration and renewed claim checks.

The board does not automatically start Claude or schedule future Codex turns.
The handoff remains available for the next active session. Public release,
submission and co-author contact require Barry's approval; routine Git
synchronisation follows the current repository and global instructions.

## Second exchange and compression pass

Claude returned the editing window in message 1966 after committing his
opening/contribution revisions as `28820af`. Codex retained those changes and
made a bounded compression pass, removing 158 whitespace-delimited source
words. Cuts remove repeated explanations while retaining their substantive
content in Methods, captions or the scope discussion. All 45 main-text
citation keys and four displayed equations remain; all 82 numerical claims
still pass. The abstract remains the accepted-evidence version pending the
extension's outcome.

Three precision changes accompany the cuts: the retained age *alone* does not
reveal its retention rule (a record can carry provenance); the wrong-family
claim identifies linear histories; and agreement *by itself* does not establish
representativeness. The contribution paragraph now states that the fitted
models omit the retention process instead of asserting an untested inability
to recover it.

The independent Stage 6 implementation audit found four acceptance/display
gaps before inspecting any new outcome. These are recorded in
`manuscript/reviews/codex_stage6_pre_results_audit_2026-10-18.md` and board
message 1980. Claude owns those code repairs; Codex has not changed the running
jobs or Stage 6 sources. The underlying seed mapping, effect-ratio plumbing,
pairing, atomic checkpoint handling and summary denominators were consistent
on static inspection. The audit is not acceptance of new results.

The second candidate is built separately under
`manuscript/submission/dist/editorial_rework_2026-10-18_round2/` so that the
first review files remain available. Verification records for this pass are
under `tmp/editorial_rework_20261018/round2/`.

The final candidate has 4,766 whitespace-delimited words extracted from Word
text and equation nodes, including title, headings, abstract, declarations
and captions, excluding the bibliography. This recorded method is not assumed
identical to Claude's earlier count or to the journal's portal. It retains all
14 content-contract commitments. The main PDF remains 15 pages; the Word
render is 18. Both were inspected after rebuilding, and the final rendered text
was checked for the last provenance and sparse-site wording changes. The
source SHA-256 is
`4663c9ccf8003dd5ac8521287264dc90a499244dd61edb9b89945d3e06a80ddf`.

## Third exchange: repaired acceptance and shared policy

Claude's message 2022 supplied `4405f51` (Stage 6 repairs) and `dbdc129`
(three prose restorations). Codex accepted the plain-language Introduction
close and the explicit statement that Figure 1 is not a calibrated simulation
result. The Discussion close was changed to "Model comparison can therefore
favour a history created by retention", preserving the scientific consequence
without claiming that model choice cannot detect retention.

The four Stage 6 implementation findings are now closed by independent static
review plus bounded controls of the repaired smoke/scenario checks on
`deep-server`. Original and row-permuted smoke data passed; a changed estimate
with a refreshed checksum was specifically rejected; all four wrong-scenario
controls were rejected. No weaker-signal selection rates were inspected and
the running matrix was untouched. The tracked audit report records the scope,
hashes and distinction between code verification and completed-result audit.

The local `AGENTS.md` Git rule was reconciled with Barry's 18 October global
instructions: routine synchronisation with his repository is reversible work;
final research-artifact review and approval for first public release,
submission, visibility changes and external contact remain explicit. GitHub
reported `BWBrook/rc-dates` as private with default branch `main` before
synchronisation. This supersedes the earlier no-push editorial status; it
does not authorise a public release of the research.
