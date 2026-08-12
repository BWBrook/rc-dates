# Stage 5: final bounded revision

## Purpose

This tranche answers the 11 August 2026 adequacy review without reopening the paper's settled
simulation scope. The only new scientific analysis is the existing nine-configuration empirical
sensitivity suite applied to full-site bracketed retention. This decision rule was frozen from
source commit `267f996` before the bracketed sensitivity outputs were generated.

## Bracketed-retention decision gate

The analysis reuses exactly the Stage 3 reference filters, curve constructions, total-variation
contrast, calendar-shift estimand and nine named configurations. No parameter or threshold is
changed after inspection.

Full-site bracketed retention is called sensitivity-robust only if, in every configuration:

1. its deterministic conservative contrast is positive, so the smallest method-specific
   retention distance exceeds the largest between-method distance on the retained dates; and
2. all three method-specific mean-cal-BP shifts retain the older direction observed under the
   accepted primary specification.

If both conditions pass in all nine configurations, bracketed retention may share the empirical
robustness statement with oldest and youngest retention. Otherwise, it is reported consistently as
a primary-specification-only result. The emitted evidence must include all configuration-level
gates, a three-rule decision table and refreshed checksums.

## Bounded textual and production corrections

After the gate is evaluated once, the manuscript and submission files will:

- state the uniform calibration-prior condition, strict-window conditioning and renormalisation,
  and working independence used for paired bracketed extrema;
- qualify high-visibility simulation claims by full treatment and the simulated ten-fold monotonic
  truths;
- identify the deposited AustArch dataset and the exact project derivative used for analysis;
- distinguish checksum verification from execution of the scientific tests;
- disclose manuscript-preparation and research-method AI assistance in line with current Elsevier
  policy;
- retain the current *Journal of Archaeological Science* double-anonymized workflow and record that
  the contrary review advice referred to the sister journal, *Journal of Archaeological Science:
  Reports*;
- repair the title-page author marker, radiocarbon glyphs and arXiv preprint label; and
- rebuild and inspect all journal-facing PDF and DOCX files.

No new realised-noise run, site-history generator, weaker-signal factorial, matched-sample
experiment or display redesign belongs to this tranche.

## Gate result

The frozen analysis completed once under R 4.5.3 on 12 August 2026. Checksum validation and an
independent read of the configuration-level table both passed.

- Bracketed retention shifted older in all nine configurations.
- Its conservative contrast was positive in the primary specification and seven other
  sensitivities, ranging from +0.060 to +0.089.
- The occupation-related `Y`-only configuration reversed the ordering contrast to -0.054.

The prespecified robustness gate therefore **failed**. In accordance with the rule above, full-site
bracketed retention is reported as a primary-specification result. Full-site oldest and youngest
retention remain the only rules supported across all nine configurations. The negative bracketed
sensitivity is retained in `out/empirical-sampling/`; no threshold or specification was changed
after inspection.
