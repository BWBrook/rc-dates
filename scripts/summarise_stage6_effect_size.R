#!/usr/bin/env Rscript
# Stage 6 (docs/STAGE6_EFFECT_SIZE.md): acceptance checks and selection-rate summaries across
# end-to-end ratios, pooled with the accepted Stage 2 ratio-10 and uniform evidence.

if (!file.exists("scripts/source_population_simulation.R")) {
  stop("Run this script from the rc-dates repository root.", call. = FALSE)
}
source("scripts/source_population_simulation.R")

stage6_dir <- file.path("out", "revision", "effect-size-20261018")
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 1L && args[[1L]] %in% c("--help", "-h")) {
  cat("Usage: Rscript --vanilla scripts/summarise_stage6_effect_size.R [--output-dir=PATH]\n")
  quit(status = 0L)
}
if (length(args) > 1L || (length(args) && !grepl("^--output-dir=.+$", args[[1L]]))) {
  stop("Only --output-dir=PATH is supported.", call. = FALSE)
}
out_dir <- if (length(args)) sub("^--output-dir=", "", args[[1L]]) else stage6_dir
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
stage2_dir <- file.path("out", "revision", "signed-models")
accepted_image <- "sha256:01f5e221d0f3b70ccb3edd0fd6556ffd1c645784e98e147e81034866b9137777"
nsim <- 1000L
nsim_new <- 500L
seed <- 1234L
proportions <- c(0.5, 0.75, 1)
new_ratios <- c(1.5, 2, 3, 5)
changing <- c("lin_inc", "lin_dec", "exp_inc", "exp_dec")
low <- 651
up <- 11650
rows_per_replicate <- population_simulation_contract("signed-v1")$rows_per_replicate

scenario_path <- function(dir, truth, prop, ratio, n = nsim) {
  file.path(dir, production_simulation_filename(truth, prop, n, seed, ratio))
}

grid_new <- expand.grid(truth = changing, prop = proportions, ratio = new_ratios,
                        stringsAsFactors = FALSE)
grid_new$nsim <- nsim_new
grid_new$path <- mapply(scenario_path, stage6_dir, grid_new$truth, grid_new$prop, grid_new$ratio, nsim_new)
grid_new$source <- "Stage 6"
grid_old <- rbind(
  data.frame(expand.grid(truth = changing, prop = proportions, stringsAsFactors = FALSE),
             ratio = 10),
  data.frame(truth = "uni", prop = proportions, ratio = 10)
)
grid_old$nsim <- nsim
grid_old$path <- mapply(scenario_path, stage2_dir, grid_old$truth, grid_old$prop, grid_old$ratio)
grid_old$source <- "accepted Stage 2"
smoke_path <- scenario_path(file.path(stage6_dir, "smoke"), "lin_inc", 1, 10, 20L)
smoke_reference_path <- scenario_path(stage2_dir, "lin_inc", 1, 10)

expected_paths <- c(grid_new$path, grid_old$path, smoke_path)
missing <- expected_paths[!file.exists(expected_paths)]
if (length(missing) > 0L) {
  stop("Missing scenario files:\n", paste(missing, collapse = "\n"), call. = FALSE)
}

read_with_provenance <- function(path) {
  x <- readRDS(path)
  list(results = x, provenance = attr(x, "production_provenance", exact = TRUE))
}
accepted_reference <- read_with_provenance(grid_old$path[[1L]])$provenance
frozen_fields <- c("schema_version", "design", "observation_model", "master_seed",
                   "input_md5", "renv_lock_md5", "model_source_md5", "distribution_source_md5",
                   "runner_source_md5", "container_recipe_md5", "container_install_md5",
                   "container_image_id", "r_version")
scenario_bound <- function(x, truth, prop, ratio, n) {
  identical(x$provenance$truth, truth) &&
    isTRUE(all.equal(as.numeric(x$provenance$prop), prop)) &&
    isTRUE(all.equal(as.numeric(x$provenance$ratio), ratio)) &&
    identical(as.integer(x$provenance$nsim), as.integer(n)) &&
    identical(unique(x$results$true), truth) &&
    isTRUE(all.equal(unique(x$results$prop), prop))
}

# Acceptance 1: the smoke rerun reproduces accepted replicates 1-20 in every result column -------
validate_population_simulation_artifact(smoke_path, nsim = 20L)
validate_population_simulation_artifact(smoke_reference_path, nsim = nsim)
smoke <- read_with_provenance(smoke_path)
reference <- readRDS(smoke_reference_path)
reference <- reference[reference$sim <= 20L, , drop = FALSE]
row_keys <- c("sim", "type", "strategy", "model")
sort_rows <- function(d) {
  d <- d[do.call(order, unname(as.list(d[row_keys]))), , drop = FALSE]
  rownames(d) <- NULL
  d
}
smoke_sorted <- sort_rows(smoke$results)
reference_sorted <- sort_rows(reference)
same_columns <- identical(names(smoke_sorted), names(reference_sorted))
differing <- if (same_columns && nrow(smoke_sorted) == nrow(reference_sorted)) {
  names(reference_sorted)[!vapply(names(reference_sorted), function(column) {
    identical(smoke_sorted[[column]], reference_sorted[[column]])
  }, logical(1))]
} else {
  names(reference_sorted)
}
smoke_check <- data.frame(
  smoke_file = smoke_path,
  smoke_md5 = unname(tools::md5sum(smoke_path)),
  reference_file = smoke_reference_path,
  reference_md5 = unname(tools::md5sum(smoke_reference_path)),
  rows_compared = nrow(reference_sorted),
  rows_expected = 20L * rows_per_replicate,
  row_keys_unique = !anyDuplicated(reference_sorted[row_keys]) && !anyDuplicated(smoke_sorted[row_keys]),
  columns_compared = length(names(reference_sorted)),
  columns_differing = if (length(differing)) paste(differing, collapse = ";") else "",
  scenario_bound = scenario_bound(smoke, "lin_inc", 1, 10, 20L),
  provenance_frozen = identical(smoke$provenance[frozen_fields], accepted_reference[frozen_fields]),
  stringsAsFactors = FALSE
)
smoke_check$reproduced <- same_columns && length(differing) == 0L &&
  smoke_check$rows_compared == smoke_check$rows_expected && smoke_check$row_keys_unique &&
  smoke_check$scenario_bound && smoke_check$provenance_frozen
utils::write.csv(smoke_check, file.path(out_dir, "stage6_smoke_check.csv"), row.names = FALSE)
if (!smoke_check$reproduced) {
  print(smoke_check)
  stop("Stage 6 acceptance 1 failed: the smoke rerun does not reproduce accepted replicates 1-20.",
       call. = FALSE)
}
message("Acceptance 1 passed: smoke rerun reproduces accepted replicates 1-20 in all ",
        smoke_check$columns_compared, " columns.")

# Acceptance 2-4: completeness, scenario binding, provenance and truth specification ------------
all_grid <- rbind(grid_new, grid_old)
invisible(mapply(validate_population_simulation_artifact, all_grid$path, all_grid$nsim))
acceptance <- do.call(rbind, lapply(seq_len(nrow(all_grid)), function(i) {
  x <- read_with_provenance(all_grid$path[[i]])
  spec <- population_truth_specification(all_grid$truth[[i]], all_grid$ratio[[i]], low, up)
  density <- switch(
    spec$family,
    uni = function(t) rep(1 / (up - low), length(t)),
    lin = function(t) dtlin(t, spec$parameter, low, up),
    exp = function(t) dtexp(t, spec$parameter, low, up)
  )
  expected_ratio <- switch(spec$direction, constant = 1, increase = all_grid$ratio[[i]],
                           decrease = 1 / all_grid$ratio[[i]])
  data.frame(
    source = all_grid$source[[i]],
    truth = all_grid$truth[[i]], prop = all_grid$prop[[i]], ratio = all_grid$ratio[[i]],
    md5 = unname(tools::md5sum(all_grid$path[[i]])),
    rows = nrow(x$results),
    replicates = length(unique(x$results$sim)),
    replicate_ids_ok = identical(sort(unique(as.integer(x$results$sim))), seq_len(all_grid$nsim[[i]])),
    scenario_bound = scenario_bound(x, all_grid$truth[[i]], all_grid$prop[[i]], all_grid$ratio[[i]],
                                    all_grid$nsim[[i]]),
    provenance_frozen = identical(x$provenance[frozen_fields], accepted_reference[frozen_fields]),
    image_accepted = identical(x$provenance$container_image_id, accepted_image),
    density_integral = stats::integrate(density, low, up)$value,
    endpoint_ratio_ok = isTRUE(all.equal(density(low) / density(up), expected_ratio, tolerance = 1e-8)),
    stringsAsFactors = FALSE
  )
}))
acceptance$accepted <- acceptance$rows == all_grid$nsim * rows_per_replicate &
  acceptance$replicates == all_grid$nsim & acceptance$replicate_ids_ok & acceptance$scenario_bound &
  acceptance$provenance_frozen & acceptance$image_accepted &
  abs(acceptance$density_integral - 1) < 1e-6 & acceptance$endpoint_ratio_ok
utils::write.csv(acceptance, file.path(out_dir, "stage6_acceptance.csv"), row.names = FALSE)
if (nrow(grid_new) != 48L || !all(acceptance$accepted)) {
  print(acceptance[!acceptance$accepted, ])
  stop("Stage 6 technical acceptance failed; outputs are not usable.", call. = FALSE)
}
message("Acceptance 2-4 passed for all 48 Stage 6 scenarios and all 15 accepted reference cells.")

# Selection rates ---------------------------------------------------------------------------
rates <- do.call(rbind, lapply(seq_len(nrow(all_grid)), function(i) {
  results <- readRDS(all_grid$path[[i]])
  selected <- stage2_selected_population_results(results)
  by_rule <- split(selected, interaction(selected$type, selected$strategy, drop = TRUE))
  out <- do.call(rbind, lapply(by_rule, function(x) {
    data.frame(
      type = x$type[[1L]], truth = all_grid$truth[[i]], prop = all_grid$prop[[i]],
      ratio = if (all_grid$truth[[i]] == "uni") 1 else all_grid$ratio[[i]],
      strategy = x$strategy[[1L]], n = nrow(x),
      correct_state_rate = mean(x$direction_correct),
      reversal_rate = mean(x$direction_reversed),
      uniform_rate = mean(x$model == "uni"),
      family_rate = mean(x$family_correct),
      stringsAsFactors = FALSE
    )
  }))
  l1 <- selected[selected$type == "l1", c("sim", "strategy", "selected_state")]
  l2 <- selected[selected$type == "l2", c("sim", "strategy", "selected_state")]
  paired <- merge(l1, l2, by = c("sim", "strategy"), suffixes = c("_l1", "_l2"))
  agreement <- tapply(paired$selected_state_l1 == paired$selected_state_l2, paired$strategy, mean)
  out$l1_l2_state_agreement <- unname(agreement[out$strategy])
  out
}))
rownames(rates) <- NULL
rates$source <- ifelse(rates$truth == "uni" | rates$ratio == 10, "accepted Stage 2", "Stage 6")
rates$replicates <- ifelse(rates$source == "Stage 6", nsim_new, nsim)
rates <- rates[order(rates$type, rates$truth, rates$ratio, rates$prop, rates$strategy), ]
utils::write.csv(rates, file.path(out_dir, "stage6_selection_rates.csv"), row.names = FALSE)

# Dose-response view: adverse and concordant one-sided rules, bracketed, random-1, all dates ----
l1 <- rates[rates$type == "l1", ]
directions <- c(increase = "inc", decrease = "dec")
dose <- do.call(rbind, lapply(c("lin", "exp"), function(family) {
  do.call(rbind, lapply(names(directions), function(direction) {
    truth <- paste0(family, "_", directions[[direction]])
    adverse <- if (direction == "increase") "r_old" else "r_young"
    concordant <- if (direction == "increase") "r_young" else "r_old"
    roles <- c(adverse = adverse, concordant = concordant, bracketed = "r_bracket",
               `random-1` = "r_1", `all dates` = "r_all")
    do.call(rbind, lapply(names(roles), function(role) {
      changing_rows <- l1[l1$truth == truth & l1$strategy == roles[[role]], ]
      constant_rows <- l1[l1$truth == "uni" & l1$strategy == roles[[role]], ]
      both <- rbind(changing_rows, constant_rows)
      data.frame(family = family, direction = direction, role = role,
                 strategy = roles[[role]], ratio = both$ratio, prop = both$prop,
                 correct_state_rate = both$correct_state_rate,
                 reversal_rate = both$reversal_rate, uniform_rate = both$uniform_rate,
                 family_rate = both$family_rate, source = both$source, replicates = both$replicates,
                 stringsAsFactors = FALSE)
    }))
  }))
}))
dose <- dose[order(dose$family, dose$direction, dose$role, dose$prop, dose$ratio), ]
utils::write.csv(dose, file.path(out_dir, "stage6_dose_response.csv"), row.names = FALSE)

agreement <- stats::weighted.mean(rates$l1_l2_state_agreement[rates$type == "l1"],
                                  rates$n[rates$type == "l1"])
writeLines(c(
  "rc-dates Stage 6 summary",
  sprintf("acceptance 1: smoke rerun reproduced accepted replicates 1-20 (%d rows, %d columns; smoke md5 %s)",
          smoke_check$rows_compared, smoke_check$columns_compared, smoke_check$smoke_md5),
  sprintf("acceptance 2-4: %d of %d Stage 6 scenarios (%d replicates) and %d of %d accepted cells (%d replicates)",
          sum(acceptance$accepted[acceptance$source == "Stage 6"]), sum(acceptance$source == "Stage 6"), nsim_new,
          sum(acceptance$accepted[acceptance$source != "Stage 6"]), sum(acceptance$source != "Stage 6"), nsim),
  paste("container image:", accepted_image),
  sprintf("l1/l2 selected-state agreement over all Stage 6 and pooled cells: %.4f", agreement)
), file.path(out_dir, "stage6_summary.txt"))
message("Wrote Stage 6 summaries to ", out_dir)
