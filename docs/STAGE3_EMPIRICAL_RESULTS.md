# Stage 3 common-membership empirical results

## Acceptance

The repaired empirical analysis completed under R 4.5.3 on 11 August 2026 and passed the frozen
gates in `docs/STAGE3_EMPIRICAL_REPAIR.md`. The accepted primary benchmark contains 540 terrestrial
charcoal or wood determinations from 68 sites, each with at least five eligible dates. SPD, FD and
KDE received exactly the same determinations in every realisation; all curves were finite,
non-negative and unit mass, and every evidence checksum passed.

The tracked 976-date reference was reduced in four explicit stages:

| Stage | Dates | Sites |
|---|---:|---:|
| Locked filtered reference | 976 | 116 |
| Terrestrial charcoal or wood | 737 | 106 |
| Common calendar membership | 645 | 106 |
| At least five eligible dates per site | 540 | 68 |

The common calendar gate required a calibrated posterior median inside 751--11,550 cal BP and at
least 0.80 posterior mass inside the 651--11,650 cal BP analysis window. All shell and human-bone
determinations were excluded from the primary analysis.

## Quantitative decision

The old general visual claim does not survive. Retention deformation was demonstrably larger than
between-method variation only in the three deterministic full-site boundary scenarios.

| Full-site rule | Retention total variation across methods | Largest between-method total variation | Conservative contrast | Mean-cal-BP shift across methods |
|---|---:|---:|---:|---:|
| Oldest | 0.455--0.535 | 0.263 | +0.193 | +3,133 to +3,136 yr |
| Youngest | 0.524--0.554 | 0.154 | +0.370 | -2,447 to -2,439 yr |
| Bracketed | 0.279--0.326 | 0.195 | +0.084 | +344 to +352 yr |

Positive mean-cal-BP shifts are older. For context, the all-date baseline total-variation distances
among methods were 0.046 for SPD--KDE, 0.088 for FD--KDE and 0.101 for SPD--FD.

The prespecified conservative contrast was the smallest method-specific retention distance minus
the largest between-method distance within the same retained dates. Its 2.5th percentile was not
positive for either half-site boundary rule, either random rule at either intensity, or half-site
bracketed retention. Their conditional direction was also not unambiguous where stochastic site
selection was involved. The manuscript must therefore attach the ordering claim to full-site
oldest, youngest and bracketed retention rather than to within-site retention generally.

## Sensitivity result

The full-site oldest and youngest decisions were unchanged in all nine prespecified configurations:

- 0-, 100- and 200-year calendar buffers;
- posterior-mass thresholds 0.50, 0.80 and 0.95;
- reflected KDE bandwidths 50, 100 and 200 years;
- an unreflected 100-year KDE; and
- the occupation-related `Y`-only subset, which retained 154 dates from 24 sites.

Every configuration retained a positive older shift and a positive conservative distance contrast
for oldest retention, and a negative younger shift and positive contrast for youngest retention.
The primary headline sensitivity gate therefore passed. Two sites had tied youngest posterior
medians and weighted means; ascending ADSID supplied the prespecified final tie-break. No oldest
tie required resolution.

## Revision consequence

The empirical analysis now supports a precise statement: **when every retained site contributes
only its posterior-median age extremum, the resulting temporal-shape deformation is larger than the
differences among common-membership SPD, FD and KDE summaries in this benchmark**. It does not
support that ordering at half-site treatment or for sparse random retention.

The result remains descriptive. Curves are normalised to unit mass, the primary set is conditioned
on well-replicated terrestrial charcoal or wood dates, and extrema are selected after calibration.
They are not site onsets, terminations, or prospective stratigraphic choices. Machine-readable
evidence is in `out/empirical-sampling/`; manuscript Figures 1--2 should be regenerated from this
accepted source when the Stage 2 signed-simulation figures and manuscript claims are revised
together.

## Stage 5 bracketed extension

On 12 August 2026, before inspecting new outputs, the same nine-configuration gate was extended to
full-site bracketed retention. Its older shift persisted in every configuration and its ordering
contrast was positive in eight. The occupation-related `Y`-only subset instead gave a contrast of
-0.054, so bracketed retention failed the frozen all-nine robustness rule. It is consequently
reported as primary-specification-only; oldest and youngest retain the nine-configuration claim.
