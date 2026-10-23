#!/usr/bin/env Rscript
# Stage 7 (docs/STAGE7_REALISED_NOISE.md): acceptance checks, paired realised-versus-accepted selection
# rates and the prespecified headline decision rule.

if (!file.exists("scripts/source_population_simulation.R")) {
  stop("Run this script from the rc-dates repository root.", call. = FALSE)
}
source("scripts/source_population_simulation.R")

stage7_dir <- file.path("out", "revision", "realised-noise-20261023")
stage2_dir <- file.path("out", "revision", "signed-models")
accepted_image <- "sha256:01f5e221d0f3b70ccb3edd0fd6556ffd1c645784e98e147e81034866b9137777"
nsim <- 1000L
seed <- 1234L
truths <- c("uni", "lin_inc", "lin_dec", "exp_inc", "exp_dec")
proportions <- c(0.5, 0.75, 1)
rows_per_replicate <- population_simulation_contract("signed-v1")$rows_per_replicate
stage7_runner_md5 <- unname(tools::md5sum("scripts/run_stage7_realised_noise.R"))

scenario_path <- function(dir, truth, prop, n = nsim) {
  file.path(dir, production_simulation_filename(truth, prop, n, seed, 10))
}
grid <- expand.grid(truth = truths, prop = proportions, stringsAsFactors = FALSE)
grid$stage7 <- mapply(scenario_path, stage7_dir, grid$truth, grid$prop)
grid$accepted <- mapply(scenario_path, stage2_dir, grid$truth, grid$prop)
smoke_path <- scenario_path(file.path(stage7_dir, "smoke"), "lin_inc", 1, 20L)
expected <- c(grid$stage7, grid$accepted, smoke_path)
missing <- expected[!file.exists(expected)]
if (length(missing) > 0L) stop("Missing scenario files:\n", paste(missing, collapse = "\n"), call. = FALSE)

provenance_of <- function(x) attr(x, "production_provenance", exact = TRUE)
accepted_reference <- provenance_of(readRDS(grid$accepted[[1L]]))
unchanged_fields <- c("schema_version", "design", "master_seed", "input_md5", "renv_lock_md5", "model_source_md5",
                      "distribution_source_md5", "container_recipe_md5", "container_install_md5",
                      "container_image_id", "r_version")

# Acceptance 1: the Stage 7 wrapper under curve_mean reproduces accepted replicates 1-20 -------------
smoke <- readRDS(smoke_path)
reference <- readRDS(scenario_path(stage2_dir, "lin_inc", 1))
reference <- reference[reference$sim <= 20L, , drop = FALSE]
row_keys <- c("sim", "type", "strategy", "model")
sort_rows <- function(d) {
  d <- d[do.call(order, unname(as.list(d[row_keys]))), , drop = FALSE]
  rownames(d) <- NULL
  d
}
smoke_sorted <- sort_rows(smoke)
reference_sorted <- sort_rows(reference)
differing <- if (identical(names(smoke_sorted), names(reference_sorted)) &&
                 nrow(smoke_sorted) == nrow(reference_sorted)) {
  names(reference_sorted)[!vapply(names(reference_sorted), function(column) {
    identical(smoke_sorted[[column]], reference_sorted[[column]])
  }, logical(1))]
} else {
  names(reference_sorted)
}
smoke_provenance <- provenance_of(smoke)
smoke_check <- data.frame(
  smoke_md5 = unname(tools::md5sum(smoke_path)),
  rows_compared = nrow(reference_sorted),
  columns_compared = ncol(reference_sorted),
  columns_differing = paste(differing, collapse = ";"),
  observation_model = smoke_provenance$observation_model,
  runner_is_stage7 = identical(smoke_provenance$runner_source_md5, stage7_runner_md5),
  stringsAsFactors = FALSE
)
smoke_check$reproduced <- length(differing) == 0L && smoke_check$rows_compared == 20L * rows_per_replicate &&
  identical(smoke_check$observation_model, "curve_mean") && smoke_check$runner_is_stage7
utils::write.csv(smoke_check, file.path(stage7_dir, "stage7_smoke_check.csv"), row.names = FALSE)
if (!smoke_check$reproduced) {
  print(smoke_check)
  stop("Stage 7 acceptance 1 failed: the curve_mean wrapper does not reproduce accepted replicates.", call. = FALSE)
}
message("Acceptance 1 passed: wrapper reproduces accepted replicates 1-20 in all ", smoke_check$columns_compared,
        " columns.")

# Acceptance 2: realised and curve_mean datasets share every structural draw -------------------------
input <- readr::read_csv("data/austarch_filtered.csv", show_col_types = FALSE)
specification <- prepare_population_simulation(input, ratio = 10)
simulate_with <- function(truth, prop, sim, observation_model) {
  requireNamespace("rcarbon", quietly = TRUE)
  set.seed(production_simulation_seed(truth, prop, sim, seed), kind = "L'Ecuyer-CMRG")
  simulate_population_data_set(truth, prop, specification, observation_model = observation_model)
}
structural <- c("site", "site_treated", "age_calendar", "age_uncalibrated_expected", "error",
                "r_1", "r_2", "r_3", "r_5")
pairing <- do.call(rbind, lapply(c("lin_inc", "uni"), function(truth) {
  do.call(rbind, lapply(1:3, function(sim) {
    mean_data <- simulate_with(truth, 0.5, sim, "curve_mean")
    realised_data <- simulate_with(truth, 0.5, sim, "realised")
    data.frame(
      truth = truth, prop = 0.5, sim = sim, dates = nrow(mean_data),
      structural_identical = all(vapply(structural, function(column) {
        identical(mean_data[[column]], realised_data[[column]])
      }, logical(1))),
      cra_differs_share = mean(mean_data$age_uncalibrated != realised_data$age_uncalibrated),
      extreme_old_changed_share = mean(mean_data$r_old != realised_data$r_old),
      stringsAsFactors = FALSE
    )
  }))
}))
pairing$accepted <- pairing$structural_identical & pairing$cra_differs_share > 0.5
utils::write.csv(pairing, file.path(stage7_dir, "stage7_pairing_check.csv"), row.names = FALSE)
if (!all(pairing$accepted)) {
  print(pairing)
  stop("Stage 7 acceptance 2 failed: realised draws do not preserve structural pairing.", call. = FALSE)
}
message("Acceptance 2 passed: structural draws identical; conventional ages differ for ",
        sprintf("%.0f%%", 100 * min(pairing$cra_differs_share)), " or more of dates.")

# Acceptance 3-4: completeness, scenario binding and provenance ---------------------------------------
acceptance <- do.call(rbind, lapply(seq_len(nrow(grid)), function(i) {
  x <- readRDS(grid$stage7[[i]])
  p <- provenance_of(x)
  validate_population_simulation_results(x, nsim = nsim, design = "signed-v1")
  data.frame(
    truth = grid$truth[[i]], prop = grid$prop[[i]],
    md5 = unname(tools::md5sum(grid$stage7[[i]])),
    rows = nrow(x),
    replicate_ids_ok = identical(sort(unique(as.integer(x$sim))), seq_len(nsim)),
    scenario_bound = identical(p$truth, grid$truth[[i]]) && isTRUE(all.equal(as.numeric(p$prop), grid$prop[[i]])) &&
      isTRUE(all.equal(as.numeric(p$ratio), 10)) && identical(as.integer(p$nsim), nsim) &&
      identical(unique(x$true), grid$truth[[i]]) && isTRUE(all.equal(unique(x$prop), grid$prop[[i]])),
    provenance_unchanged = identical(p[unchanged_fields], accepted_reference[unchanged_fields]),
    observation_realised = identical(p$observation_model, "realised"),
    runner_is_stage7 = identical(p$runner_source_md5, stage7_runner_md5),
    image_accepted = identical(p$container_image_id, accepted_image),
    stringsAsFactors = FALSE
  )
}))
acceptance$accepted <- acceptance$rows == nsim * rows_per_replicate & acceptance$replicate_ids_ok &
  acceptance$scenario_bound & acceptance$provenance_unchanged & acceptance$observation_realised &
  acceptance$runner_is_stage7 & acceptance$image_accepted
utils::write.csv(acceptance, file.path(stage7_dir, "stage7_acceptance.csv"), row.names = FALSE)
if (nrow(acceptance) != 15L || !all(acceptance$accepted)) {
  print(acceptance[!acceptance$accepted, ])
  stop("Stage 7 technical acceptance failed; outputs are not usable.", call. = FALSE)
}
message("Acceptance 3-4 passed for all 15 Stage 7 scenarios.")

# Paired selection rates ----------------------------------------------------------------------------
cell_rates <- function(selected) {
  by_rule <- split(selected, interaction(selected$type, selected$strategy, drop = TRUE))
  do.call(rbind, lapply(by_rule, function(x) {
    data.frame(type = x$type[[1L]], strategy = x$strategy[[1L]], n = nrow(x),
               correct_state_rate = mean(x$direction_correct), reversal_rate = mean(x$direction_reversed),
               uniform_rate = mean(x$model == "uni"), family_rate = mean(x$family_correct),
               stringsAsFactors = FALSE)
  }))
}
rates <- do.call(rbind, lapply(seq_len(nrow(grid)), function(i) {
  realised <- stage2_selected_population_results(readRDS(grid$stage7[[i]]))
  accepted <- stage2_selected_population_results(readRDS(grid$accepted[[i]]))
  r <- cell_rates(realised)
  a <- cell_rates(accepted)
  out <- merge(r, a, by = c("type", "strategy", "n"), suffixes = c("_realised", "_accepted"))
  for (rate in c("correct_state_rate", "reversal_rate", "uniform_rate", "family_rate")) {
    out[[paste0(rate, "_change")]] <- out[[paste0(rate, "_realised")]] - out[[paste0(rate, "_accepted")]]
  }
  paired <- merge(realised[c("sim", "type", "strategy", "selected_state")],
                  accepted[c("sim", "type", "strategy", "selected_state")],
                  by = c("sim", "type", "strategy"), suffixes = c("_realised", "_accepted"))
  same <- tapply(paired$selected_state_realised == paired$selected_state_accepted,
                 interaction(paired$type, paired$strategy, drop = TRUE), mean)
  out$same_state_share <- unname(same[paste(out$type, out$strategy, sep = ".")])
  l1 <- realised[realised$type == "l1", c("sim", "strategy", "selected_state")]
  l2 <- realised[realised$type == "l2", c("sim", "strategy", "selected_state")]
  scores <- merge(l1, l2, by = c("sim", "strategy"), suffixes = c("_l1", "_l2"))
  agreement <- tapply(scores$selected_state_l1 == scores$selected_state_l2, scores$strategy, mean)
  out$l1_l2_agreement_realised <- unname(agreement[out$strategy])
  drops <- realised[realised$type == "l1", c("strategy", "n_observations", "n_dropped")]
  dropped <- tapply(drops$n_dropped, drops$strategy, sum)
  retained <- tapply(drops$n_observations + drops$n_dropped, drops$strategy, sum)
  out$dropped_share_realised <- unname((dropped / retained)[out$strategy])
  cbind(truth = grid$truth[[i]], prop = grid$prop[[i]], out, stringsAsFactors = FALSE)
}))
rates <- rates[order(rates$type, rates$truth, rates$prop, rates$strategy), ]
rownames(rates) <- NULL
utils::write.csv(rates, file.path(stage7_dir, "stage7_selection_rates.csv"), row.names = FALSE)

# Prespecified headline rule --------------------------------------------------------------------------
l1 <- rates[rates$type == "l1", ]
changing <- c("lin_inc", "lin_dec", "exp_inc", "exp_dec")
adverse <- c(lin_inc = "r_old", exp_inc = "r_old", lin_dec = "r_young", exp_dec = "r_young")
concordant <- c(lin_inc = "r_young", exp_inc = "r_young", lin_dec = "r_old", exp_dec = "r_old")
pick <- function(truth, prop, strategy, rate, label, transform = identity) {
  row <- l1[l1$truth == truth & abs(l1$prop - prop) < 1e-9 & l1$strategy == strategy, ]
  stopifnot(nrow(row) == 1L)
  data.frame(headline = label, truth = truth, prop = prop, strategy = strategy,
             accepted = transform(row[[paste0(rate, "_accepted")]]),
             realised = transform(row[[paste0(rate, "_realised")]]), stringsAsFactors = FALSE)
}
directional <- function(x) 1 - x
headline <- rbind(
  do.call(rbind, lapply(changing, function(t) pick(t, 1, adverse[[t]], "reversal_rate", "1 full adverse reversal"))),
  do.call(rbind, lapply(changing, function(t) pick(t, 1, concordant[[t]], "correct_state_rate",
                                                   "1 full concordant direction"))),
  do.call(rbind, lapply(c("r_old", "r_young"), function(s) pick("uni", 1, s, "uniform_rate",
                                                                 "2 constant full uniform selection"))),
  do.call(rbind, lapply(c("r_old", "r_young"), function(s) pick("uni", 0.5, s, "uniform_rate",
                                                                 "2 constant half directional", directional))),
  do.call(rbind, lapply(changing, function(t) do.call(rbind, lapply(c(0.5, 0.75), function(p) {
    pick(t, p, adverse[[t]], "reversal_rate", "3 partial adverse reversal")
  })))),
  do.call(rbind, lapply(c("r_1", "r_2", "r_3", "r_5"), function(s) do.call(rbind, lapply(changing, function(t) {
    do.call(rbind, lapply(proportions, function(p) pick(t, p, s, "reversal_rate", "4 random reversal")))
  })))),
  do.call(rbind, lapply(changing, function(t) pick(t, 1, "r_bracket", "correct_state_rate",
                                                   "5 full bracketed direction"))),
  do.call(rbind, lapply(c("lin_inc", "lin_dec"), function(t) pick(t, 1, "r_bracket", "family_rate",
                                                                   "5 full bracketed linear family"))),
  pick("uni", 1, "r_bracket", "correct_state_rate", "5 full bracketed constant uniform")
)
headline$change <- headline$realised - headline$accepted
headline$within_0.02 <- abs(headline$change) <= 0.02 + 1e-12
utils::write.csv(headline, file.path(stage7_dir, "stage7_headline.csv"), row.names = FALSE)
holds <- all(headline$within_0.02)

writeLines(c(
  "rc-dates Stage 7 summary",
  sprintf("acceptance 1: curve_mean wrapper reproduced accepted replicates 1-20 (%d rows, %d columns)",
          smoke_check$rows_compared, smoke_check$columns_compared),
  sprintf("acceptance 2: structural draws identical in %d of %d paired datasets; conventional ages differ for %.3f-%.3f of dates",
          sum(pairing$structural_identical), nrow(pairing), min(pairing$cra_differs_share), max(pairing$cra_differs_share)),
  sprintf("acceptance 3-4: %d of 15 scenarios accepted (%d replicates each)", sum(acceptance$accepted), nsim),
  paste("container image:", accepted_image),
  sprintf("headline rule (all %d headline rates within 0.02 of accepted): %s", nrow(headline),
          if (holds) "HOLDS" else "DOES NOT HOLD"),
  sprintf("largest absolute headline change: %.3f", max(abs(headline$change))),
  sprintf("l1/l2 family-and-direction agreement under realised scatter: %.4f",
          stats::weighted.mean(l1$l1_l2_agreement_realised, l1$n)),
  sprintf("retained dates dropped for zero in-window mass: %.4f-%.4f of retained dates across rules and scenarios",
          min(l1$dropped_share_realised), max(l1$dropped_share_realised))
), file.path(stage7_dir, "stage7_summary.txt"))
message("Wrote Stage 7 summaries to ", stage7_dir, "; headline rule ", if (holds) "holds" else "does not hold")
