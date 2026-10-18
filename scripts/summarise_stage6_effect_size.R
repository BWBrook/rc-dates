#!/usr/bin/env Rscript
# Stage 6 (docs/STAGE6_EFFECT_SIZE.md): acceptance checks and selection-rate summaries across
# end-to-end ratios, pooled with the accepted Stage 2 ratio-10 and uniform evidence.

if (!file.exists("scripts/source_population_simulation.R")) {
  stop("Run this script from the rc-dates repository root.", call. = FALSE)
}
source("scripts/source_population_simulation.R")

stage6_dir <- Sys.getenv("STAGE6_DIR", file.path("out", "revision", "effect-size-20261018"))
out_dir <- Sys.getenv("STAGE6_OUT_DIR", stage6_dir)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
stage2_dir <- file.path("out", "revision", "signed-models")
accepted_image <- "sha256:01f5e221d0f3b70ccb3edd0fd6556ffd1c645784e98e147e81034866b9137777"
nsim <- 1000L
nsim_new <- as.integer(Sys.getenv("STAGE6_NSIM", "500"))
seed <- 1234L
proportions <- c(0.5, 0.75, 1)
new_ratios <- as.numeric(strsplit(Sys.getenv("STAGE6_RATIOS", "1.5,2,3,5"), ",")[[1L]])
changing <- c("lin_inc", "lin_dec", "exp_inc", "exp_dec")
low <- 651
up <- 11650

scenario_path <- function(dir, truth, prop, ratio, n = nsim) {
  file.path(dir, production_simulation_filename(truth, prop, n, seed, ratio))
}

grid_new <- expand.grid(truth = changing, prop = proportions, ratio = new_ratios,
                        stringsAsFactors = FALSE)
grid_new$path <- mapply(scenario_path, stage6_dir, grid_new$truth, grid_new$prop, grid_new$ratio, nsim_new)
grid_old <- rbind(
  data.frame(expand.grid(truth = changing, prop = proportions, stringsAsFactors = FALSE),
             ratio = 10),
  data.frame(truth = "uni", prop = proportions, ratio = 10)
)
grid_old$path <- mapply(scenario_path, stage2_dir, grid_old$truth, grid_old$prop, grid_old$ratio)

missing <- c(grid_new$path, grid_old$path)[!file.exists(c(grid_new$path, grid_old$path))]
if (length(missing) > 0L) {
  stop("Missing scenario files:\n", paste(missing, collapse = "\n"), call. = FALSE)
}

# Acceptance 2-4: completeness, provenance and truth specification ---------------------------
invisible(lapply(grid_new$path, validate_population_simulation_artifact, nsim = nsim_new))
invisible(lapply(grid_old$path, validate_population_simulation_artifact, nsim = nsim))
read_with_provenance <- function(path) {
  x <- readRDS(path)
  list(results = x, provenance = attr(x, "production_provenance", exact = TRUE))
}
accepted_reference <- read_with_provenance(grid_old$path[[1L]])$provenance
frozen_fields <- c("schema_version", "design", "observation_model", "master_seed",
                   "input_md5", "renv_lock_md5", "model_source_md5", "distribution_source_md5",
                   "runner_source_md5", "container_recipe_md5", "container_install_md5",
                   "container_image_id", "r_version")
acceptance <- do.call(rbind, lapply(seq_len(nrow(grid_new)), function(i) {
  x <- read_with_provenance(grid_new$path[[i]])
  spec <- population_truth_specification(grid_new$truth[[i]], grid_new$ratio[[i]], low, up)
  density <- if (spec$family == "lin") {
    function(t) dtlin(t, spec$parameter, low, up)
  } else {
    function(t) dtexp(t, spec$parameter, low, up)
  }
  integral <- stats::integrate(density, low, up)$value
  endpoint_ratio <- density(low) / density(up)
  expected_ratio <- if (spec$direction == "increase") grid_new$ratio[[i]] else 1 / grid_new$ratio[[i]]
  data.frame(
    truth = grid_new$truth[[i]], prop = grid_new$prop[[i]], ratio = grid_new$ratio[[i]],
    rows = nrow(x$results),
    replicates = length(unique(x$results$sim)),
    provenance_frozen = identical(x$provenance[frozen_fields], accepted_reference[frozen_fields]),
    provenance_ratio = isTRUE(all.equal(as.numeric(x$provenance$ratio), grid_new$ratio[[i]])),
    image_accepted = identical(x$provenance$container_image_id, accepted_image),
    density_integral = integral,
    endpoint_ratio_ok = isTRUE(all.equal(endpoint_ratio, expected_ratio, tolerance = 1e-8)),
    stringsAsFactors = FALSE
  )
}))
expected_rows <- nsim_new * population_simulation_contract("signed-v1")$rows_per_replicate
acceptance$accepted <- acceptance$rows == expected_rows & acceptance$replicates == nsim_new &
  acceptance$provenance_frozen & acceptance$provenance_ratio & acceptance$image_accepted &
  abs(acceptance$density_integral - 1) < 1e-6 & acceptance$endpoint_ratio_ok
utils::write.csv(acceptance, file.path(out_dir, "stage6_acceptance.csv"), row.names = FALSE)
if (!all(acceptance$accepted)) {
  print(acceptance[!acceptance$accepted, ])
  stop("Stage 6 technical acceptance failed; outputs are not usable.", call. = FALSE)
}
message("Technical acceptance passed for all ", nrow(acceptance), " Stage 6 scenarios.")

# Selection rates ---------------------------------------------------------------------------
all_grid <- rbind(grid_new, grid_old)
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
                 family_rate = both$family_rate, source = both$source,
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
  paste("scenarios accepted:", sum(acceptance$accepted), "of", nrow(acceptance)),
  paste("rows per scenario:", expected_rows),
  paste("container image:", accepted_image),
  sprintf("l1/l2 selected-state agreement over all Stage 6 and pooled cells: %.4f", agreement)
), file.path(out_dir, "stage6_summary.txt"))
message("Wrote Stage 6 summaries to ", out_dir)
