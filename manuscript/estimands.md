# What each analysis bounds: the allowed claims

The interpretation specification for this paper. Every rendering (article, supplement, brief, agent guide) states
each result only in these terms. Change this file before changing prose, and agree it before writing analysis code that
it governs. A sentence passes only if its subject is the same object as the calculation; a caveat attached to a sentence
does not rescue it if its noun has changed.

Most of these rules were settled in the October 2026 editorial rework and the Codex audits (discussion 88; the review
files are listed under `manuscript/reviews/`). Each "Not allowed" item is a phrasing that was proposed and rejected,
quoted so that a reviewer can search for it.

## Empirical retention benchmark (C01–C08)

- **Estimand:** how far retained-date summaries (SPD, FD, KDE) of one fixed benchmark move from that benchmark's own
  all-date summary. The benchmark is 540 terrestrial charcoal or wood dates from 68 AustArch sites with at least five
  eligible dates each. Full-site extrema rules are deterministic, and random rules are summarised over 1,000 conditional
  realisations.
- **Allowed:** "in this benchmark, keeping each site's oldest (youngest) date shifted the SPD mean N years older
  (younger)". "Random retention of the same number of dates shifted it about a century". "Full-site oldest and youngest
  retention changed temporal shape more than the choice among three summary methods". Random-rule ranges are described
  as variation across repeated retention from this fixed benchmark.
- **Not allowed:**
  - "the population history of Sahul", or "the true curve", or any statement that a retained or all-date curve is the
    actual history;
  - "an unbiased sample of Sahul occupation";
  - random-rule ranges described as uncertainty about the archive or the population;
  - any claim about how often archives contain extremal retention ("archives commonly keep oldest dates");
  - "dates are often a selection".

## Direction and reversal in the main simulation (C09–C12)

- **Estimand:** the share of replicates in which minimum AIC, under the primary marginal likelihood (`l1`), selects each
  direction state (uniform, increasing, decreasing). The setting is exchangeable regional dates with site labels, the
  calibration-curve-mean observation model, ten-fold end-to-end ratios, the candidate set {uniform, linear, exponential}
  in both directions, and 50%, 75% or 100% of sites treated.
- **Allowed:** "full-site oldest (youngest) retention imposed decline (growth) in every replicate, including reversal of
  opposing ten-fold trends". "At half-site treatment it created apparent change from constant histories in over 97% of
  replicates". "For ten-fold changes, complete reversal required every site to be treated".
- **Not allowed:**
  - "reversal occurs only under full treatment" without the ten-fold qualifier (Stage 6 refutes it for weaker trends);
  - "random retention is safe" or "representative";
  - "a safe filtering threshold";
  - results presented as rates of error in real archives.

## Weaker trends (C17–C24)

- **Estimand:** the correct-direction, reversal and uniform-selection rates as functions of the true end-to-end density
  ratio (1.5, 2, 3, 5 and the accepted 10) and of the treatment proportion. The ratio-1.5 to ratio-5 cells have 500
  replicates each.
- **Allowed:** "with three-quarters of sites treated, the opposing rule reversed 93–100% of 1.5- and 2-fold changes but
  no ten-fold change". "For a fixed proportion of sites treated, weaker trends were more vulnerable to reversal or uniform
  selection". "The tested proportions do not establish a safe retention threshold". "Avoiding reversal did not ensure
  recovery of a trend".
- **Not allowed:**
  - "a treatment threshold that is safe for one signal strength is not safe for another", or any other threshold claim;
  - "dilution protected strong trends but not weak ones", a binary reading;
  - "the full-treatment result was an artefact" (it is specific to ten-fold signals);
  - interpolated statements between the tested ratios;
  - the ratio described as a growth rate. It is an end-to-end density contrast over an 11,000-year window.

## Form and shape under bracketed retention (C13–C15, C23)

- **Estimand:** generating-family selection within the fitted candidate set, under a working-independence fit for the
  paired extrema of each site; the bounded endpoint contrast $c=\tanh(\theta/2)$ of the generating-family fit.
- **Allowed:** "keeping both extrema avoided reversals but obscured weak changes". "At full treatment exponential models
  were favoured for every ten-fold linear history". "Uniform selection under bracketed retention does not establish shape
  recovery, because the candidates include no U-shaped alternative".
- **Not allowed:**
  - "bracketed retention preserves the history", or "recovers shape";
  - uniform selection read as evidence of uniform retained ages;
  - "model comparison cannot detect retention", or "none of the tested analyses could detect it", which are universal
    detectability claims;
  - fitted contrasts read as growth rates.

## Realised measurement scatter (C25–C26)

- **Estimand:** the paired change in the headline rates when every conventional age is drawn around its curve mean with
  its quoted and curve errors. The design is the ten-fold main experiment, with independent curve errors.
- **Allowed:** "the headline results held under realised measurement scatter", or "moved no headline rate by more than
  0.001". The earlier v1 assessment "met 15 of 18 prespecified criteria and remains failed", and the v2 diagnostic is
  described as post-unblinding.
- **Not allowed:**
  - "robust to measurement error" or "robust to calibration uncertainty" (correlated curve errors, laboratory offsets
    and outliers are untested);
  - v1 described as passed, or v2 described as validating it;
  - scatter results extended to the weaker-ratio cells.

## Mechanism (C27)

- **Estimand:** exact-age order statistics for independent uniform ages, an analytic illustration.
- **Allowed:** "of five independent ages from a constant distribution, the oldest falls in the oldest fifth about two
  times in three, against one in five for a random date". Figure 1 is described as exact-age selection, not a calibrated
  result.
- **Not allowed:** "an extreme calibrated date marks occupation onset or termination"; post hoc retention equated with
  prospective choice of contexts to date.

## What every rendering must keep

- Agreement among analyses of the same dates "cannot, by itself" show representativeness. The qualifier stays.
- "A retained age alone does not reveal the rule that kept it": the record may still carry provenance.
- Simulation results are conditional on exchangeable regional dates, without occupation histories, stratigraphy or
  spatial structure.
