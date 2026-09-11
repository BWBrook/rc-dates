#!/usr/bin/env Rscript
source("scripts/release/common.R")
source("scripts/source_population_simulation.R")
args <- release_arguments(list(`output-dir` = "out/reproduced/signed-models"))
input_dir <- "out/revision/signed-models"
contract <- population_simulation_contract("signed-v1")
paths <- unlist(lapply(c(0.5, 0.75, 1), function(prop) {
  file.path(input_dir, vapply(contract$truths, production_simulation_filename,
                             character(1), prop = prop, nsim = 1000,
                             master_seed = 1234, ratio = 10))
}), use.names = FALSE)
invisible(lapply(paths, validate_population_simulation_artifact, nsim = 1000L))
blocks <- lapply(paths, readRDS)
provenance <- lapply(blocks, attr, which = "production_provenance", exact = TRUE)
common_fields <- setdiff(names(provenance[[1]]), c("truth", "prop"))
stopifnot(all(vapply(provenance, function(p) {
  identical(p[common_fields], provenance[[1]][common_fields])
}, logical(1))))
results <- do.call(rbind, blocks)
validate_population_simulation_results(results, nsim = 1000L, design = "signed-v1")
for (truth in contract$truths) {
  all_dates <- results[results$true == truth & results$strategy == "r_all", ]
  columns <- setdiff(names(all_dates), "prop")
  for (prop in c(0.5, 0.75)) {
    release_compare_rows(all_dates[all_dates$prop == prop, columns],
                         all_dates[all_dates$prop == 1, columns],
                         c("sim", "type", "model"), paste("all-date pairing", truth, prop))
  }
}
tables <- list(
  truth_state_confusion = summarise_stage2_confusion(results),
  selection_performance = summarise_stage2_selection(results),
  log_ratio_bias = summarise_stage2_log_ratio_bias(results),
  boundary_frequency = summarise_stage2_boundaries(results),
  paired_contrasts_vs_all = summarise_stage2_paired_contrasts(results)
)
for (name in names(tables)) {
  expected <- file.path(input_dir, paste0(name, ".csv"))
  # All columns jointly form an unambiguous ordering even for the confusion table.
  release_write_compare_csv(tables[[name]], expected,
                            file.path(args[["output-dir"]], paste0(name, ".csv")),
                            names(tables[[name]]))
}
minimum <- stage2_selected_population_results(results)
a <- minimum[minimum$type == "l1", c("true", "prop", "sim", "strategy", "model", "selected_state")]
b <- minimum[minimum$type == "l2", c("true", "prop", "sim", "strategy", "model", "selected_state")]
joined <- merge(a, b, by = c("true", "prop", "sim", "strategy"), suffixes = c("_l1", "_l2"))
agreement <- data.frame(comparisons = nrow(joined),
                       family_and_direction_agree = sum(joined$selected_state_l1 == joined$selected_state_l2))
stopifnot(agreement$comparisons == 120000, agreement$family_and_direction_agree == 119698)
readr::write_csv(agreement, file.path(args[["output-dir"]], "scoring_agreement.csv"))
message("Accepted signed summaries regenerated from all 720,000 fitted rows.")
