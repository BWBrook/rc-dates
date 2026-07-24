#!/usr/bin/env Rscript

parse_arguments <- function(args) {
  settings <- list(
    input_dir = file.path("out", "production"),
    summary_dir = file.path("out", "production"),
    figure_dir = file.path("manuscript", "figures"),
    nsim = 1000L,
    master_seed = 1234L,
    n_boot = 1000L
  )
  key_map <- c(
    `input-dir` = "input_dir",
    `summary-dir` = "summary_dir",
    `figure-dir` = "figure_dir",
    nsim = "nsim",
    seed = "master_seed",
    `n-boot` = "n_boot"
  )
  for (argument in args) {
    parts <- regmatches(argument, regexec("^--([^=]+)=(.*)$", argument))[[1L]]
    if (length(parts) != 3L || !parts[[2L]] %in% names(key_map)) {
      stop("Unknown or malformed argument: ", argument, call. = FALSE)
    }
    settings[[key_map[[parts[[2L]]]]]] <- parts[[3L]]
  }
  for (field in c("nsim", "master_seed", "n_boot")) {
    settings[[field]] <- suppressWarnings(as.integer(settings[[field]]))
    if (is.na(settings[[field]]) || settings[[field]] < 1L) {
      stop("Invalid positive integer for ", field, call. = FALSE)
    }
  }
  settings
}

if (!file.exists("R/population_simulation_production.R")) {
  stop("Run this script from the rc-dates repository root.", call. = FALSE)
}
source("R/population_simulation_production.R")
settings <- parse_arguments(commandArgs(trailingOnly = TRUE))

models <- c("uni", "lin", "exp")
proportions <- c(0.5, 0.75, 1)
result_paths <- unlist(lapply(proportions, function(prop) {
  file.path(
    settings$input_dir,
    vapply(models, production_simulation_filename, character(1),
      prop = prop,
      nsim = settings$nsim,
      master_seed = settings$master_seed
    )
  )
}), use.names = FALSE)
missing_results <- result_paths[!file.exists(result_paths)]
if (length(missing_results) > 0L) {
  stop("Missing production RDS files: ", paste(missing_results, collapse = ", "), call. = FALSE)
}

invisible(lapply(
  result_paths,
  validate_population_simulation_artifact,
  nsim = settings$nsim
))
result_list <- lapply(result_paths, readRDS)
provenance_list <- lapply(result_list, attr, which = "production_provenance", exact = TRUE)
common_provenance_fields <- c(
  "schema_version", "nsim", "master_seed", "input_md5", "renv_lock_md5",
  "production_source_md5", "legacy_helper_md5", "runner_source_md5",
  "container_recipe_md5", "container_install_md5", "container_image_id",
  "provenance_origin", "r_version"
)
canonical_provenance <- provenance_list[[1L]][common_provenance_fields]
same_provenance <- vapply(provenance_list, function(provenance) {
  identical(provenance[common_provenance_fields], canonical_provenance)
}, logical(1))
if (!all(same_provenance)) {
  stop("Production artifacts were not generated under one common runtime.", call. = FALSE)
}
source_fields <- c(
  production_source_md5 = "R/population_simulation_production.R",
  legacy_helper_md5 = "R/legacy_simulation_helpers.R",
  runner_source_md5 = "scripts/run_population_simulation.R",
  container_recipe_md5 = "docker/production-simulation.Dockerfile",
  container_install_md5 = "docker/install-production-packages.R",
  renv_lock_md5 = "renv.lock",
  input_md5 = "data/austarch_filtered.csv"
)
source_sets <- list(
  active = source_fields,
  `production-20260710` = c(
    production_source_md5 = paste0(
      "provenance/production-20260710/",
      "R/population_simulation_production.R"
    ),
    legacy_helper_md5 = paste0(
      "provenance/production-20260710/",
      "R/legacy_simulation_helpers.R"
    ),
    runner_source_md5 = paste0(
      "provenance/production-20260710/",
      "scripts/run_population_simulation.R"
    ),
    container_recipe_md5 = paste0(
      "provenance/production-20260710/",
      "docker/production-simulation.Dockerfile"
    ),
    renv_lock_md5 = "renv.lock",
    input_md5 = "data/austarch_filtered.csv"
  )
)
matching_source_sets <- vapply(source_sets, function(paths) {
  all(file.exists(paths)) && identical(
    unname(tools::md5sum(paths)),
    unname(unlist(canonical_provenance[names(paths)]))
  )
}, logical(1))
if (!any(matching_source_sets)) {
  stop("No retained source set matches the production provenance.", call. = FALSE)
}
generation_source_set <- names(matching_source_sets)[which(matching_source_sets)[[1L]]]
results <- do.call(rbind, result_list)
rownames(results) <- NULL
validate_population_simulation_results(results, nsim = settings$nsim)

all_dates <- results[results$strategy == "r_all", ]
comparison_columns <- setdiff(names(all_dates), "prop")
canonical <- all_dates[all_dates$prop == 1, comparison_columns, drop = FALSE]
canonical <- canonical[order(canonical$true, canonical$sim, canonical$type, canonical$model), ]
rownames(canonical) <- NULL
for (prop in c(0.5, 0.75)) {
  candidate <- all_dates[all_dates$prop == prop, comparison_columns, drop = FALSE]
  candidate <- candidate[order(candidate$true, candidate$sim, candidate$type, candidate$model), ]
  rownames(candidate) <- NULL
  if (!identical(candidate, canonical)) {
    stop("Common-random-number check failed for all-dates results at prop = ", prop, call. = FALSE)
  }
}

accuracy <- summarise_population_accuracy(
  results,
  n_boot = settings$n_boot,
  seed = settings$master_seed
)
bias <- summarise_population_bias(results)
unique_ose <- summarise_unique_ose(
  results,
  n_boot = settings$n_boot,
  seed = settings$master_seed
)
artifact_manifest <- do.call(rbind, Map(function(path, result) {
  provenance <- attr(result, "production_provenance", exact = TRUE)
  data.frame(
    file = basename(path),
    metadata_file = basename(paste0(path, ".metadata.txt")),
    true_model = unique(result$true),
    site_subsampling_proportion = unique(result$prop),
    replicates = length(unique(result$sim)),
    rows = nrow(result),
    bytes = file.info(path)$size,
    md5 = unname(tools::md5sum(path)),
    container_image_id = provenance$container_image_id,
    provenance_origin = provenance$provenance_origin,
    r_version = provenance$r_version,
    generation_source_set = generation_source_set,
    stringsAsFactors = FALSE
  )
}, result_paths, result_list))

dir.create(settings$summary_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(settings$figure_dir, recursive = TRUE, showWarnings = FALSE)
manifest_path <- file.path(settings$summary_dir, "production_manifest.csv")
accuracy_path <- file.path(settings$summary_dir, "summary_model_accuracy.csv")
bias_path <- file.path(settings$summary_dir, "summary_parameter_bias.csv")
ose_path <- file.path(settings$summary_dir, "summary_unique_ose.csv")
image_id_path <- file.path(settings$summary_dir, "container_image_id.txt")
readr::write_csv(artifact_manifest, manifest_path)
readr::write_csv(accuracy, accuracy_path)
readr::write_csv(bias, bias_path)
readr::write_csv(unique_ose, ose_path)
writeLines(canonical_provenance$container_image_id, image_id_path)

checksum_paths <- c(
  result_paths,
  paste0(result_paths, ".metadata.txt"),
  manifest_path,
  accuracy_path,
  bias_path,
  ose_path,
  image_id_path
)
checksums <- vapply(checksum_paths, function(path) {
  digest::digest(path, algo = "sha256", serialize = FALSE, file = TRUE)
}, character(1))
writeLines(
  paste(checksums, basename(checksum_paths)),
  file.path(settings$summary_dir, "SHA256SUMS")
)

strategy_labels <- c(
  r_all = "all",
  r_1 = "random-1",
  r_3 = "random-3",
  r_5 = "random-5",
  r_bracket = "bracketed",
  r_old = "oldest",
  r_young = "youngest"
)
add_strategy_label <- function(data) {
  data$strategy_label <- factor(
    data$strategy,
    levels = names(strategy_labels),
    labels = unname(strategy_labels)
  )
  data
}

accuracy_l1 <- add_strategy_label(accuracy[accuracy$type == "l1", ])
figure_3 <- ggplot2::ggplot(
  accuracy_l1,
  ggplot2::aes(x = prop, y = accuracy, colour = strategy_label, group = strategy_label)
) +
  ggplot2::geom_hline(yintercept = 1 / 3, linetype = "dotted", linewidth = 0.35) +
  ggplot2::geom_linerange(
    ggplot2::aes(ymin = ci_low, ymax = ci_high),
    linewidth = 0.4,
    alpha = 0.55
  ) +
  ggplot2::geom_line(linewidth = 0.55) +
  ggplot2::geom_point(size = 1.8) +
  ggplot2::scale_x_continuous(
    breaks = proportions,
    labels = scales::label_percent(accuracy = 1)
  ) +
  ggplot2::scale_y_continuous(breaks = seq(0.3, 1, 0.1), limits = c(0.3, 1)) +
  ggplot2::scale_colour_brewer(palette = "Dark2", name = "Strategy") +
  ggplot2::labs(
    title = "Accuracy of sampling strategies",
    x = "Percentage of sites subsampled",
    y = "Accuracy"
  ) +
  ggplot2::theme_classic(base_size = 10) +
  ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5))

bias_l1 <- add_strategy_label(bias[bias$type == "l1", ])
bias_l1$strategy_label <- factor(
  bias_l1$strategy_label,
  levels = rev(unname(strategy_labels))
)
bias_l1$truth_label <- factor(
  bias_l1$true,
  levels = c("exp", "lin"),
  labels = c("exponential", "linear")
)
bias_l1$prop_label <- factor(
  bias_l1$prop,
  levels = proportions,
  labels = scales::label_percent(accuracy = 1)(proportions)
)
dodge <- ggplot2::position_dodge(width = 0.55)
figure_4 <- ggplot2::ggplot(
  bias_l1,
  ggplot2::aes(y = strategy_label, x = mean_bias, colour = prop_label)
) +
  ggplot2::geom_vline(xintercept = 0, linetype = "dashed", linewidth = 0.35) +
  ggplot2::geom_errorbar(
    ggplot2::aes(xmin = ci_low, xmax = ci_high),
    width = 0.12,
    orientation = "y",
    position = dodge,
    linewidth = 0.4,
    alpha = 0.6
  ) +
  ggplot2::geom_point(position = dodge, size = 1.7) +
  ggplot2::facet_wrap(~truth_label, scales = "free_x") +
  ggplot2::scale_colour_brewer(
    palette = "Set1",
    name = "Percentage of sites subsampled"
  ) +
  ggplot2::scale_x_continuous(
    labels = function(x) format(x, scientific = TRUE, digits = 2)
  ) +
  ggplot2::labs(x = "Bias in distributional parameter (rate or slope)", y = "Strategy") +
  ggplot2::theme_classic(base_size = 10) +
  ggplot2::theme(
    legend.position = "bottom",
    strip.background = ggplot2::element_blank(),
    strip.text = ggplot2::element_text(face = "plain")
  )

ose_l1 <- add_strategy_label(unique_ose[unique_ose$type == "l1", ])
figure_5 <- ggplot2::ggplot(
  ose_l1,
  ggplot2::aes(x = prop, y = p, colour = strategy_label, group = strategy_label)
) +
  ggplot2::geom_linerange(
    ggplot2::aes(ymin = ci_low, ymax = ci_high),
    linewidth = 0.4,
    alpha = 0.55
  ) +
  ggplot2::geom_line(linewidth = 0.55) +
  ggplot2::geom_point(size = 1.8) +
  ggplot2::scale_x_continuous(
    breaks = proportions,
    labels = scales::label_percent(accuracy = 1)
  ) +
  ggplot2::scale_y_continuous(breaks = seq(0.2, 1, 0.1), limits = c(0.2, 1)) +
  ggplot2::scale_colour_brewer(palette = "Dark2", name = "Strategy") +
  ggplot2::labs(
    title = "Unambiguous growth-model selection",
    x = "Percentage of sites subsampled",
    y = "Proportion of simulations"
  ) +
  ggplot2::theme_classic(base_size = 10) +
  ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5))

ggplot2::ggsave(
  file.path(settings$figure_dir, "fig_3.pdf"),
  figure_3,
  width = 6,
  height = 5,
  device = grDevices::cairo_pdf
)
ggplot2::ggsave(
  file.path(settings$figure_dir, "fig_4.pdf"),
  figure_4,
  width = 7,
  height = 5,
  device = grDevices::cairo_pdf
)
ggplot2::ggsave(
  file.path(settings$figure_dir, "fig_5.pdf"),
  figure_5,
  width = 6,
  height = 5,
  device = grDevices::cairo_pdf
)

message("Validated and rendered Figures 3-5 from ", nrow(results), " production rows.")
