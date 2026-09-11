# AustArch source provenance

## Deposited source

The cited source is Alan Williams and Sean Ulm's 2014 AustArch dataset, Archaeology Data Service
(ADS) collection 1661, DOI `10.5284/1027216`. The deposited table used for reconciliation is
`Austarch_1-3_and_IDASQ_28Nov13-1.csv`.

A fresh download from the ADS record on 12 August 2026 had:

- SHA-256 `bb37e887a57c87173ac5e7b25b034886a6509646a03650eeda559653bcbdb583`;
- 5,522 data rows, all nonblank and with unique `ADSID` values; and
- 5,044 rows labelled `Radiocarbon` plus 478 rows assigned to other dating methods.

This file is not redistributed in the scientific reproducibility archive. The checksum records the
object used for the 2026 provenance audit, not permission to republish it.

## Historical project working derivative

The development repository's file `data/Austarch_1-3_and_IDASQ_28Nov13-1.csv` is a project working derivative, not a
pristine ADS download. It was introduced in Git commit `dea1f336` on 2 April 2025 and edited in
commit `4b95f57b` on 3 April 2025. Its current SHA-256 is
`7e8e053389830e8ec56657feb1bbbfdd5dba5f9ed8bc13d7f0634f1aa66d28cb`.

The CSV contains 5,288 rows after the header, including 17 blank rows. Its 5,271 nonblank records
have unique ADSIDs; 4,828 are labelled `Radiocarbon`. Relative to the 2026 ADS download, the
derivative omits 251 ADSIDs and changes one or more fields in 239 retained records. The most common
changed fields are depth (105 records), latitude (104), longitude (18), quoted error (14), carbon-13
age (9) and conventional age (7). Git records the changes, but the historical rationale for every
edit is not recoverable. The file must therefore be described as a project derivative.

## Analysis reference

The accepted filtered reference is `data/austarch_filtered.csv`, SHA-256
`2f1b5ccc40038f9e30bce643d57191c545c98448266fcaab3b11c9a33059c70a`. It contains 976
radiocarbon determinations from 116 sites.

All 976 ADSIDs occur in the fresh ADS download. For these records, conventional ages, quoted
errors, methods, laboratory codes, longitude, latitude, time-series status, site status and
occupation-relation status match the deposited table. Site, site-type and material labels match
after the project's mechanical replacement of spaces with underscores. The accepted analysis
reference therefore does not inherit the derivative's seven conventional-age changes, fourteen
quoted-error changes or coordinate changes.

The empirical manuscript benchmark applies additional source-controlled filters to this 976-row
reference. It contains 540 terrestrial charcoal or wood determinations from 68 sites; the exact
flow and sensitivity decisions are recorded under `out/empirical-sampling/`.

## Release boundary

The public or reviewable scientific record may contain code, synthetic simulation artefacts and
permitted aggregate empirical evidence. Raw and record-level AustArch data require a separate
decision based on ADS terms, sensitive-location risk and Indigenous data-governance requirements.
Do not describe the source records as de-identified or freely redistributable without that review.

## Reconstruction verified on 11 September 2026

The original 5,522-row import in commit `dea1f336` has SHA-256
`67cf7f5b10662165544d5a7525ac56b65d109530c51ca00030d39c8275b4fd1d`.
The recovered historical workflow reproduced the accepted 976-row reference
**byte for byte** under R 4.5.3 and the recorded package versions. Stage counts
were 5,522 source rows, 3,700 after initial screening, 3,076 after material/site
and calibration-range eligibility, 2,553 after posterior overlap with the
inclusive 651–11,650 cal BP window, and 976 after requiring five dates per site.

`scripts/release/reconstruct_austarch_reference.R` makes this workflow explicit
and refuses to publish an output unless it matches the accepted reference
checksum above. It recognises both the verified original-import hash and the
2026 ADS-audit hash. These input hashes are distinct and are not explained by
simple BOM, line-ending or terminal-newline changes. The ADS-audit snapshot
could not be reacquired during assembly (HTTP 403), so its full replay is not
claimed here. The accepted-output gate applies to either source snapshot.
The original source and the reconstructed record-level reference remain outside
the distributed package. The reconstruction result resolves execution from the
earliest import; it does not establish why the later working-file edits occurred.
