## Source-controlled empirical manuscript Figures 1--2 --------------------

#' Define the empirical within-site sampling scenarios used in Figure 2
#' @param iterations Monte Carlo iterations for stochastic scenarios.
#' @param seed Master seed.
#' @return Ten-row scenario data frame.
manuscript_empirical_scenarios <- function(iterations = 1000L, seed = 1234L) {
  valid_iterations <- length(iterations) == 1L && is.finite(iterations) &&
    iterations >= 1L && iterations == as.integer(iterations)
  valid_seed <- length(seed) == 1L && is.finite(seed) &&
    seed >= 1L && seed == as.integer(seed)
  if (!valid_iterations || !valid_seed) {
    rlang::abort(
      "Figure 2 iterations and seed must be positive integers.",
      class = "rcdates_manuscript_figure_error"
    )
  }

  strategy <- rep(
    c("oldest", "youngest", "bracketed", "random", "random"),
    each = 2L
  )
  strategy_label <- rep(
    c("oldest", "youngest", "bracketed", "random-1", "random-5"),
    each = 2L
  )
  proportion <- rep(c(0.5, 1), times = 5L)
  n_samples <- rep(c(1L, 1L, 2L, 1L, 5L), each = 2L)
  deterministic <- proportion == 1 &
    strategy %in% c("oldest", "youngest", "bracketed")

  data.frame(
    strategy = strategy,
    strategy_label = strategy_label,
    proportion = proportion,
    n_samples = n_samples,
    iterations = ifelse(deterministic, 1L, as.integer(iterations)),
    seed = rep(as.integer(seed), 10L),
    stringsAsFactors = FALSE
  )
}

#' Define legacy-anchored calendar bins intersecting the analysis window
#' @param min_age Young boundary in cal BP.
#' @param max_age Old boundary in cal BP.
#' @param bin_width Bin width in years.
#' @return Data frame with bin labels and clipped integration bounds.
manuscript_calendar_bins <- function(
  min_age = 651,
  max_age = 11650,
  bin_width = 100
) {
  valid <- all(is.finite(c(min_age, max_age, bin_width))) &&
    min_age < max_age && bin_width > 0
  if (!valid) {
    rlang::abort(
      "Calendar-bin bounds and width are invalid.",
      class = "rcdates_manuscript_figure_error"
    )
  }
  labels <- seq(
    floor(min_age / bin_width) * bin_width,
    floor(max_age / bin_width) * bin_width,
    by = bin_width
  )
  data.frame(
    bin = labels,
    lower = pmax(labels, min_age),
    upper = pmin(labels + bin_width, max_age),
    midpoint = (
      pmax(labels, min_age) + pmin(labels + bin_width, max_age)
    ) / 2,
    width = pmax(0, pmin(labels + bin_width, max_age) - pmax(labels, min_age)),
    stringsAsFactors = FALSE
  )
}

#' Generate deterministic treated-site indicators for empirical sampling
#' @param sites Stable vector of site identifiers.
#' @param proportion Proportion of treated sites.
#' @param iterations Number of columns to generate.
#' @param seed Master site-selection seed.
#' @return Logical site-by-iteration matrix.
manuscript_treated_site_matrix <- function(
  sites,
  proportion,
  iterations,
  seed
) {
  sites <- unique(as.character(sites))
  valid_iterations <- length(iterations) == 1L && is.finite(iterations) &&
    iterations >= 1L && iterations == as.integer(iterations)
  n_treated <- as.integer(round(length(sites) * proportion))
  exact_count <- abs(n_treated - length(sites) * proportion) <
    sqrt(.Machine$double.eps)
  if (length(sites) == 0L || !valid_iterations || !is.finite(seed) ||
      !exact_count || n_treated < 1L || n_treated > length(sites)) {
    rlang::abort(
      "Treated-site specification is invalid or has a non-integer site count.",
      class = "rcdates_manuscript_figure_error"
    )
  }

  treated <- matrix(
    FALSE,
    nrow = length(sites),
    ncol = as.integer(iterations),
    dimnames = list(sites, paste0("iteration_", seq_len(as.integer(iterations))))
  )
  if (n_treated == length(sites)) {
    treated[,] <- TRUE
    return(treated)
  }
  for (iteration in seq_len(as.integer(iterations))) {
    selected <- withr::with_seed(
      as.integer(seed) + iteration - 1L,
      sample.int(length(sites), n_treated, replace = FALSE)
    )
    treated[selected, iteration] <- TRUE
  }
  treated
}

#' Build date-selection indicators for one empirical sampling scenario
#' @param data Reference data containing calibrated posterior summaries.
#' @param strategy One of random, oldest, youngest, or bracketed.
#' @param n_samples Dates retained per treated site for random sampling.
#' @param treated_site_matrix Logical site-by-iteration treatment matrix.
#' @param seed Strategy-specific seed.
#' @return Logical date-by-iteration selection matrix.
manuscript_selection_matrix <- function(
  data,
  strategy,
  n_samples,
  treated_site_matrix,
  seed
) {
  required <- c(
    "SITE", "ADSID", "calibrated_median_calBP", "weighted_mean_calBP"
  )
  if (!is.data.frame(data) || !all(required %in% names(data)) ||
      anyDuplicated(data$ADSID) ||
      any(!is.finite(data$calibrated_median_calBP)) ||
      any(!is.finite(data$weighted_mean_calBP))) {
    rlang::abort(
      "Empirical selection requires unique IDs and finite calibrated summaries.",
      class = "rcdates_manuscript_figure_error"
    )
  }
  valid_strategies <- c("random", "oldest", "youngest", "bracketed")
  if (length(strategy) != 1L || !strategy %in% valid_strategies) {
    rlang::abort(
      "Unknown empirical within-site strategy.",
      class = "rcdates_manuscript_figure_error"
    )
  }
  site_rows <- split(seq_len(nrow(data)), as.character(data$SITE))
  site_names <- names(site_rows)
  if (!identical(sort(rownames(treated_site_matrix)), sort(site_names))) {
    rlang::abort(
      "Treated-site matrix does not match the empirical sites.",
      class = "rcdates_manuscript_figure_error"
    )
  }
  treated_site_matrix <- treated_site_matrix[site_names, , drop = FALSE]
  iterations <- ncol(treated_site_matrix)
  selected <- matrix(
    TRUE,
    nrow = nrow(data),
    ncol = iterations,
    dimnames = list(NULL, colnames(treated_site_matrix))
  )

  for (iteration in seq_len(iterations)) {
    treated_sites <- site_names[treated_site_matrix[, iteration]]
    selected_rows <- if (identical(strategy, "random")) {
      withr::with_seed(
        as.integer(seed) + iteration - 1L,
        lapply(treated_sites, function(site) {
          rows <- site_rows[[site]]
          if (length(rows) < n_samples) {
            rlang::abort(
              "A treated site contains fewer dates than the requested random sample.",
              class = "rcdates_manuscript_figure_error"
            )
          }
          sample(rows, as.integer(n_samples), replace = FALSE)
        })
      )
    } else {
      lapply(treated_sites, function(site) {
        rows <- site_rows[[site]]
        median_age <- data$calibrated_median_calBP[rows]
        mean_age <- data$weighted_mean_calBP[rows]
        stable_id <- as.character(data$ADSID[rows])
        oldest <- rows[order(-median_age, -mean_age, stable_id)][[1L]]
        youngest <- rows[order(median_age, mean_age, stable_id)][[1L]]
        switch(
          strategy,
          oldest = oldest,
          youngest = youngest,
          bracketed = unique(c(oldest, youngest))
        )
      })
    }

    for (index in seq_along(treated_sites)) {
      rows <- site_rows[[treated_sites[[index]]]]
      selected[rows, iteration] <- FALSE
      selected[selected_rows[[index]], iteration] <- TRUE
    }
  }
  selected
}

#' Report ties encountered by calibrated extrema rules
#' @param data Common-membership empirical reference.
#' @return One row for oldest and youngest retention.
summarise_manuscript_extreme_ties <- function(data) {
  required <- c(
    "SITE", "ADSID", "calibrated_median_calBP", "weighted_mean_calBP"
  )
  if (!all(required %in% names(data))) {
    rlang::abort(
      "Tie audit requires calibrated empirical summaries.",
      class = "rcdates_manuscript_figure_error"
    )
  }
  site_rows <- split(seq_len(nrow(data)), as.character(data$SITE))
  do.call(rbind, lapply(c("oldest", "youngest"), function(strategy) {
    tie_counts <- vapply(site_rows, function(rows) {
      medians <- data$calibrated_median_calBP[rows]
      target_median <- if (strategy == "oldest") max(medians) else min(medians)
      median_rows <- rows[medians == target_median]
      means <- data$weighted_mean_calBP[median_rows]
      target_mean <- if (strategy == "oldest") max(means) else min(means)
      c(
        median = length(median_rows),
        mean = sum(means == target_mean)
      )
    }, numeric(2L))
    data.frame(
      strategy = strategy,
      sites = length(site_rows),
      posterior_median_tie_sites = sum(tie_counts["median", ] > 1L),
      posterior_mean_tie_sites = sum(tie_counts["mean", ] > 1L),
      stringsAsFactors = FALSE
    )
  }))
}

#' Apply rcarbon's centred running-mean edge-fill convention by column
#' @param values Numeric matrix.
#' @param width Positive integer running-mean width.
#' @return Smoothed matrix with unsmoothed edge cells.
manuscript_running_mean_matrix <- function(values, width) {
  values <- as.matrix(values)
  valid_width <- length(width) == 1L && is.finite(width) && width >= 1L &&
    width == as.integer(width) && width <= nrow(values)
  if (!valid_width) {
    rlang::abort(
      "Running-mean width must be a positive integer no greater than the rows.",
      class = "rcdates_manuscript_figure_error"
    )
  }
  if (width == 1L) return(values)
  smoothed <- vapply(seq_len(ncol(values)), function(column) {
    x <- values[, column]
    filtered <- stats::filter(x, rep(1 / width, width), sides = 2)
    x[!is.na(filtered)] <- filtered[!is.na(filtered)]
    x
  }, numeric(nrow(values)))
  dimnames(smoothed) <- dimnames(values)
  smoothed
}

#' Build a Gaussian-kernel probability-mass basis on common calendar bins
#' @param point_ages Per-date calibrated point summaries.
#' @param bins Output of [manuscript_calendar_bins()].
#' @param bandwidth Gaussian bandwidth in years.
#' @param boundary Either reflected boundary correction or no correction.
#' @return Bin-by-date kernel-mass matrix.
manuscript_gaussian_bin_basis <- function(
  point_ages,
  bins,
  bandwidth = 100,
  boundary = c("reflect", "none")
) {
  boundary <- match.arg(boundary)
  point_ages <- as.numeric(point_ages)
  min_age <- min(bins$lower)
  max_age <- max(bins$upper)
  if (length(point_ages) == 0L || any(!is.finite(point_ages)) ||
      any(point_ages < min_age | point_ages > max_age) ||
      length(bandwidth) != 1L || !is.finite(bandwidth) || bandwidth <= 0) {
    rlang::abort(
      "KDE inputs must be finite point ages inside the analysis window.",
      class = "rcdates_manuscript_figure_error"
    )
  }
  kernel_mass <- function(means) {
    upper <- outer(bins$upper, means, function(bound, mean_age) {
      stats::pnorm((bound - mean_age) / bandwidth)
    })
    lower <- outer(bins$lower, means, function(bound, mean_age) {
      stats::pnorm((bound - mean_age) / bandwidth)
    })
    upper - lower
  }
  basis <- kernel_mass(point_ages)
  if (boundary == "reflect") {
    basis <- basis +
      kernel_mass(2 * min_age - point_ages) +
      kernel_mass(2 * max_age - point_ages)
    totals <- colSums(basis)
    if (any(!is.finite(totals) | totals <= 0)) {
      rlang::abort(
        "Reflected KDE basis has invalid probability mass.",
        class = "rcdates_manuscript_figure_error"
      )
    }
    basis <- sweep(basis, 2L, totals, FUN = "/")
  }
  basis
}

manuscript_frequency_bin_basis <- function(point_ages, bins, bin_width = 100) {
  point_ages <- as.numeric(point_ages)
  basis <- matrix(0, nrow = nrow(bins), ncol = length(point_ages))
  valid <- is.finite(point_ages) &
    point_ages >= min(bins$lower) &
    point_ages <= max(bins$upper)
  labels <- floor(point_ages[valid] / bin_width) * bin_width
  row_index <- match(labels, bins$bin)
  basis[cbind(row_index, which(valid))] <- 1
  basis
}

manuscript_spd_bin_basis <- function(
  calibrated,
  date_ids,
  bins,
  runm = 100L
) {
  date_ids <- as.character(date_ids)
  grid_ids <- names(calibrated$grids)
  if (anyDuplicated(date_ids) || any(!date_ids %in% grid_ids)) {
    rlang::abort(
      "Calibrated grids do not align one-to-one with the reference dates.",
      class = "rcdates_manuscript_figure_error"
    )
  }
  min_age <- min(bins$lower)
  max_age <- max(bins$upper)
  calendar_age <- seq(max_age, min_age, by = -1)
  probability <- matrix(
    0,
    nrow = length(calendar_age),
    ncol = length(date_ids),
    dimnames = list(as.character(calendar_age), date_ids)
  )

  for (column in seq_along(date_ids)) {
    grid <- calibrated$grids[[date_ids[[column]]]]
    keep <- grid$calBP >= min_age & grid$calBP <= max_age
    row_index <- match(grid$calBP[keep], calendar_age)
    probability[row_index, column] <- grid$PrDens[keep]
  }
  probability <- manuscript_running_mean_matrix(probability, width = runm)
  bin_labels <- floor(calendar_age / 100) * 100
  grouped <- rowsum(probability, group = bin_labels, reorder = TRUE)
  grouped <- grouped[as.character(bins$bin), , drop = FALSE]
  unname(grouped)
}

#' Prepare reusable per-date curve bases for Figures 1 and 2
#' @param data Reference data with ADSID and calibrated medians.
#' @param calibrated CalDates object aligned to `data`.
#' @param bins Common calendar-bin definition.
#' @param bandwidth KDE bandwidth.
#' @param spd_runm SPD running-mean width.
#' @param kde_boundary KDE boundary treatment.
#' @return Named list of SPD, FD, KDE bases and bins.
prepare_manuscript_curve_bases <- function(
  data,
  calibrated,
  bins = manuscript_calendar_bins(),
  bandwidth = 100,
  spd_runm = 100L,
  kde_boundary = c("reflect", "none")
) {
  kde_boundary <- match.arg(kde_boundary)
  required <- c("ADSID", "calibrated_median_calBP")
  if (!all(required %in% names(data))) {
    rlang::abort(
      "Reference data lack ADSID or calibrated posterior medians.",
      class = "rcdates_manuscript_figure_error"
    )
  }
  list(
    SPD = manuscript_spd_bin_basis(
      calibrated,
      date_ids = data$ADSID,
      bins = bins,
      runm = spd_runm
    ),
    FD = manuscript_frequency_bin_basis(data$calibrated_median_calBP, bins),
    KDE = manuscript_gaussian_bin_basis(
      data$calibrated_median_calBP,
      bins,
      bandwidth,
      boundary = kde_boundary
    ),
    bins = bins
  )
}

normalise_manuscript_curve_matrix <- function(values) {
  values <- as.matrix(values)
  totals <- colSums(values)
  if (any(!is.finite(totals) | totals <= 0)) {
    rlang::abort(
      "A manuscript curve has no mass inside the analysis window.",
      class = "rcdates_manuscript_figure_error"
    )
  }
  sweep(values, 2L, totals, FUN = "/")
}

manuscript_curve_matrices <- function(
  bases,
  selection_matrix,
  fd_smooth_width = 2L
) {
  selection_numeric <- unclass(selection_matrix) * 1
  curves <- list(
    SPD = normalise_manuscript_curve_matrix(bases$SPD %*% selection_numeric),
    FD = normalise_manuscript_curve_matrix(bases$FD %*% selection_numeric),
    KDE = normalise_manuscript_curve_matrix(bases$KDE %*% selection_numeric)
  )
  curves$FD <- normalise_manuscript_curve_matrix(
    manuscript_running_mean_matrix(curves$FD, width = fd_smooth_width)
  )
  valid <- vapply(curves, function(curve) {
    all(is.finite(curve)) && all(curve >= 0) &&
      all(abs(colSums(curve) - 1) <= 1e-10)
  }, logical(1))
  if (!all(valid)) {
    rlang::abort(
      "Empirical curves failed finite, non-negative, or unit-mass gates.",
      class = "rcdates_manuscript_figure_error"
    )
  }
  curves
}

summarise_manuscript_effective_counts <- function(
  selection_matrix,
  bases,
  strategy_label,
  proportion
) {
  selected <- as.matrix(selection_matrix)
  if (!is.logical(selected)) selected <- selected != 0
  effective_by_method <- vapply(c("SPD", "FD", "KDE"), function(method) {
    effective_date <- colSums(bases[[method]]) > 0
    colSums(
      selected & matrix(
        effective_date,
        nrow = length(effective_date),
        ncol = ncol(selected)
      )
    )
  }, numeric(ncol(selected)))
  if (is.null(dim(effective_by_method))) {
    effective_by_method <- matrix(effective_by_method, nrow = 1L)
  }
  colnames(effective_by_method) <- c("SPD", "FD", "KDE")
  if (any(apply(effective_by_method, 1L, function(x) length(unique(x)) != 1L))) {
    rlang::abort(
      "Curve methods do not have identical effective membership.",
      class = "rcdates_manuscript_figure_error"
    )
  }
  do.call(rbind, lapply(c("SPD", "FD", "KDE"), function(method) {
    effective <- effective_by_method[, method]
    data.frame(
      strategy_label = strategy_label,
      proportion = as.numeric(proportion),
      method = method,
      iterations = ncol(selected),
      selected_dates_mean = mean(colSums(selected)),
      selected_dates_min = min(colSums(selected)),
      selected_dates_max = max(colSums(selected)),
      effective_dates_mean = mean(effective),
      effective_dates_min = min(effective),
      effective_dates_max = max(effective),
      stringsAsFactors = FALSE
    )
  }))
}

#' Summarise a bin-by-iteration curve matrix
#' @param curve_matrix Matrix of unit-area curves.
#' @param bins Calendar-bin labels.
#' @param method Method label.
#' @return Data frame with mean and central 95% interval.
summarise_manuscript_curve_matrix <- function(curve_matrix, bins, method) {
  curve_matrix <- as.matrix(curve_matrix)
  if (nrow(curve_matrix) != length(bins) || ncol(curve_matrix) < 1L) {
    rlang::abort(
      "Curve matrix dimensions do not match the calendar bins.",
      class = "rcdates_manuscript_figure_error"
    )
  }
  if (ncol(curve_matrix) == 1L) {
    lower <- upper <- curve_matrix[, 1L]
  } else {
    lower <- apply(
      curve_matrix,
      1L,
      stats::quantile,
      probs = 0.025,
      names = FALSE
    )
    upper <- apply(
      curve_matrix,
      1L,
      stats::quantile,
      probs = 0.975,
      names = FALSE
    )
  }
  data.frame(
    method = method,
    calBP = as.numeric(bins),
    mean = rowMeans(curve_matrix),
    lower = as.numeric(lower),
    upper = as.numeric(upper),
    stringsAsFactors = FALSE
  )
}

#' Compute all-date curve matrices
#' @param bases Reusable curve bases.
#' @param n_dates Number of reference dates.
#' @return Named list of unit-mass curve matrices.
build_manuscript_baseline_matrices <- function(bases, n_dates) {
  selected <- matrix(TRUE, nrow = n_dates, ncol = 1L)
  manuscript_curve_matrices(bases, selected)
}

#' Compute the all-dates Figure 1 curve summaries
#' @param bases Reusable curve bases.
#' @param n_dates Number of reference dates.
#' @return Long-form baseline curve summary.
build_manuscript_baseline_curves <- function(bases, n_dates) {
  curves <- build_manuscript_baseline_matrices(bases, n_dates)
  do.call(rbind, lapply(names(curves), function(method) {
    summarise_manuscript_curve_matrix(
      curves[[method]],
      bins = bases$bins$bin,
      method = method
    )
  }))
}

#' Compute all Figure 2 empirical sampling summaries
#' @param data Empirical reference data.
#' @param bases Reusable curve bases.
#' @param specs Output of [manuscript_empirical_scenarios()].
#' @return Named summaries, common-membership counts, distances, and claim gates.
run_manuscript_empirical_sampling <- function(data, bases, specs) {
  results <- vector("list", nrow(specs))
  deviations <- vector("list", nrow(specs))
  effective_counts <- vector("list", nrow(specs))
  distance_summaries <- vector("list", nrow(specs))
  gates <- vector("list", nrow(specs))
  sites <- unique(as.character(data$SITE))
  strategy_order <- c("oldest", "youngest", "bracketed", "random-1", "random-5")
  baseline <- build_manuscript_baseline_matrices(bases, nrow(data))

  for (index in seq_len(nrow(specs))) {
    spec <- specs[index, , drop = FALSE]
    treated <- manuscript_treated_site_matrix(
      sites = sites,
      proportion = spec$proportion[[1L]],
      iterations = spec$iterations[[1L]],
      seed = as.integer(spec$seed[[1L]] + spec$proportion[[1L]] * 10000L)
    )
    strategy_index <- match(spec$strategy_label[[1L]], strategy_order)
    selected <- manuscript_selection_matrix(
      data = data,
      strategy = spec$strategy[[1L]],
      n_samples = spec$n_samples[[1L]],
      treated_site_matrix = treated,
      seed = as.integer(spec$seed[[1L]] + strategy_index * 100000L)
    )
    curves <- manuscript_curve_matrices(bases, selected)
    effective_counts[[index]] <- summarise_manuscript_effective_counts(
      selection_matrix = selected,
      bases = bases,
      strategy_label = spec$strategy_label[[1L]],
      proportion = spec$proportion[[1L]]
    )
    scenario_summary <- do.call(rbind, lapply(names(curves), function(method) {
      summarise_manuscript_curve_matrix(
        curves[[method]],
        bins = bases$bins$bin,
        method = method
      )
    }))
    scenario_summary$strategy <- spec$strategy[[1L]]
    scenario_summary$strategy_label <- spec$strategy_label[[1L]]
    scenario_summary$proportion <- spec$proportion[[1L]]
    scenario_summary$iterations <- spec$iterations[[1L]]
    results[[index]] <- scenario_summary
    deviation_summary <- do.call(rbind, lapply(names(curves), function(method) {
      deviation <- sweep(
        curves[[method]],
        1L,
        baseline[[method]][, 1L],
        FUN = "-"
      )
      summarise_manuscript_curve_matrix(
        deviation,
        bins = bases$bins$bin,
        method = method
      )
    }))
    deviation_summary$strategy <- spec$strategy[[1L]]
    deviation_summary$strategy_label <- spec$strategy_label[[1L]]
    deviation_summary$proportion <- spec$proportion[[1L]]
    deviation_summary$iterations <- spec$iterations[[1L]]
    deviations[[index]] <- deviation_summary
    distances <- summarise_manuscript_scenario_distances(
      curves = curves,
      baseline = baseline,
      midpoints = bases$bins$midpoint,
      strategy_label = spec$strategy_label[[1L]],
      proportion = spec$proportion[[1L]]
    )
    distance_summaries[[index]] <- distances$summary
    gates[[index]] <- distances$gate
  }
  list(
    curves = do.call(rbind, results),
    deviations = do.call(rbind, deviations),
    effective_counts = do.call(rbind, effective_counts),
    distances = do.call(rbind, distance_summaries),
    gates = do.call(rbind, gates)
  )
}

manuscript_method_palette <- function() {
  c(FD = "#e31a1c", KDE = "#33a02c", SPD = "#1f78b4")
}

#' Plot the all-dates empirical baseline for manuscript Figure 1
#' @param curves Output of [build_manuscript_baseline_curves()].
#' @param bin_width Display bin width.
#' @return ggplot object.
manuscript_methods_plot <- function(curves, bin_width = 100) {
  curves$method <- factor(curves$method, levels = c("FD", "KDE", "SPD"))
  curves$display_density <- curves$mean / bin_width
  ggplot2::ggplot(
    curves,
    ggplot2::aes(x = calBP, y = display_density, colour = method)
  ) +
    ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::scale_colour_manual(values = manuscript_method_palette(), name = "Method") +
    ggplot2::scale_x_reverse(
      limits = c(12000, 0),
      breaks = c(12000, 9000, 6000, 3000, 0),
      expand = c(0, 0)
    ) +
    ggplot2::scale_y_continuous(
      name = expression("Scaled density (" * 10^-4 * ")"),
      labels = scales::label_number(scale = 10000, accuracy = 1),
      expand = c(0, 0)
    ) +
    ggplot2::labs(x = "Years cal BP") +
    ggplot2::theme_minimal(base_size = 11)
}

#' Plot the 5-by-2 empirical retention-deformation panel for Figure 2
#' @param curves Deviation summaries from [run_manuscript_empirical_sampling()].
#' @return Faceted ggplot object.
manuscript_sampling_panel_plot <- function(curves) {
  strategy_levels <- c("oldest", "youngest", "bracketed", "random-1", "random-5")
  curves$strategy_label <- factor(curves$strategy_label, levels = strategy_levels)
  curves$proportion_label <- factor(
    curves$proportion,
    levels = c(0.5, 1),
    labels = c("50% of sites treated", "100% of sites treated")
  )
  curves$method <- factor(curves$method, levels = c("FD", "KDE", "SPD"))
  curves$display_mean <- curves$mean / 100
  curves$display_lower <- curves$lower / 100
  curves$display_upper <- curves$upper / 100
  ggplot2::ggplot(
    curves,
    ggplot2::aes(
      x = calBP,
      y = display_mean,
      colour = method,
      fill = method,
      group = method
    )
  ) +
    ggplot2::geom_hline(yintercept = 0, linewidth = 0.25, colour = "grey45") +
    ggplot2::geom_ribbon(
      ggplot2::aes(ymin = display_lower, ymax = display_upper),
      alpha = 0.14,
      colour = NA
    ) +
    ggplot2::geom_line(linewidth = 0.45) +
    ggplot2::facet_grid(
      rows = ggplot2::vars(strategy_label),
      cols = ggplot2::vars(proportion_label),
      switch = "y"
    ) +
    ggplot2::scale_colour_manual(values = manuscript_method_palette(), name = "Method") +
    ggplot2::scale_fill_manual(values = manuscript_method_palette(), name = "Method") +
    ggplot2::scale_x_reverse(
      limits = c(12000, 0),
      breaks = c(12000, 9000, 6000, 3000, 0),
      expand = c(0, 0)
    ) +
    ggplot2::scale_y_continuous(
      name = expression("Density difference from all dates (" * 10^-4 * ")"),
      labels = scales::label_number(scale = 10000, accuracy = 1),
      expand = ggplot2::expansion(mult = 0.03)
    ) +
    ggplot2::labs(x = "Years cal BP") +
    ggplot2::theme_minimal(base_size = 9) +
    ggplot2::theme(
      legend.position = "bottom",
      strip.placement = "outside",
      strip.background = ggplot2::element_blank(),
      strip.text.y.left = ggplot2::element_text(angle = 0),
      panel.spacing.x = grid::unit(3, "lines"),
      panel.spacing.y = grid::unit(0.7, "lines")
    )
}
