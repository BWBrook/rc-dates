#!/usr/bin/env Rscript
# Rebuild accepted Stage 6 summaries without writing into the evidence snapshot.
source("scripts/release/common.R")
output_dir <- "out/reproduced/effect-size"
status <- system2(file.path(R.home("bin"), "Rscript"), c(
  "--vanilla", "scripts/summarise_stage6_effect_size.R",
  paste0("--output-dir=", output_dir)
))
if (status != 0L) stop("Stage 6 summary reconstruction failed.", call. = FALSE)

accepted_dir <- "out/revision/effect-size-20261018"
keys <- list(
  stage6_acceptance = c("source", "truth", "prop", "ratio"),
  stage6_smoke_check = "smoke_file",
  stage6_selection_rates = c("type", "truth", "prop", "ratio", "strategy"),
  stage6_dose_response = c("family", "direction", "role", "ratio", "prop")
)
for (name in names(keys)) {
  filename <- paste0(name, ".csv")
  actual <- utils::read.csv(file.path(output_dir, filename), stringsAsFactors = FALSE)
  expected <- utils::read.csv(file.path(accepted_dir, filename), stringsAsFactors = FALSE)
  release_compare_rows(actual, expected, keys[[name]], filename)
}
stopifnot(identical(
  readLines(file.path(output_dir, "stage6_summary.txt")),
  readLines(file.path(accepted_dir, "stage6_summary.txt"))
))
message("Stage 6 rates, acceptance provenance, smoke check and summary text reproduced exactly.")
