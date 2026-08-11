## Common-membership empirical reference -----------------------------------

manuscript_primary_materials <- function() {
  c(
    "Charcoal", "Charcoal_from_hearth", "Scattered_charcoal",
    "Wood_charcoal", "Carbonised_wood", "Burnt_wood", "Charred_wood", "Wood"
  )
}

#' Restrict the empirical benchmark to terrestrial charcoal and wood
#' @param data Tracked AustArch reference data.
#' @param occupation_status Accepted occupation-relation codes.
#' @return Filtered data in stable input order.
filter_manuscript_primary_reference <- function(
  data,
  occupation_status = c("Y", "U")
) {
  required <- c(
    "ADSID", "SITE", "MATERIAL", "TIME_SERIES_RELEVANT",
    "OCCUPATION_RELATED", "AGE", "ERROR"
  )
  if (!is.data.frame(data) || !all(required %in% names(data)) ||
      anyDuplicated(data$ADSID) || any(!is.finite(data$AGE)) ||
      any(!is.finite(data$ERROR) | data$ERROR <= 0)) {
    rlang::abort(
      "The empirical reference table is invalid or lacks required fields.",
      class = "rcdates_manuscript_figure_error"
    )
  }
  if (length(occupation_status) < 1L ||
      any(!occupation_status %in% c("Y", "U"))) {
    rlang::abort(
      "Occupation status must contain Y, U, or both.",
      class = "rcdates_manuscript_figure_error"
    )
  }
  data[
    data$TIME_SERIES_RELEVANT == "Terrestrial" &
      data$MATERIAL %in% manuscript_primary_materials() &
      data$OCCUPATION_RELATED %in% occupation_status,
    ,
    drop = FALSE
  ]
}

#' Attach calibrated posterior summaries to the empirical reference
#' @param data Reference data aligned by ADSID.
#' @param calibrated CalDates object containing full calibrated grids.
#' @param min_age Young analysis-window boundary.
#' @param max_age Old analysis-window boundary.
#' @return Reference data with posterior median, mean, and in-window mass.
annotate_manuscript_calibration <- function(
  data,
  calibrated,
  min_age = 651,
  max_age = 11650
) {
  ids <- as.character(data$ADSID)
  grid_ids <- names(calibrated$grids)
  metadata_ids <- as.character(calibrated$metadata$DateID)
  calibration_summary <- summary(calibrated)
  if (anyDuplicated(ids) || anyDuplicated(grid_ids) ||
      !setequal(ids, grid_ids) || length(metadata_ids) != nrow(calibration_summary) ||
      !"MedianBP" %in% colnames(calibration_summary)) {
    rlang::abort(
      "Calibrated grids do not align one-to-one with the empirical reference.",
      class = "rcdates_manuscript_figure_error"
    )
  }
  medians <- calibration_summary[, "MedianBP"]
  names(medians) <- metadata_ids
  means <- vapply(calibrated$grids, function(grid) {
    sum(grid$calBP * grid$PrDens)
  }, numeric(1))
  in_window_mass <- vapply(calibrated$grids, function(grid) {
    keep <- grid$calBP >= min_age & grid$calBP <= max_age
    sum(grid$PrDens[keep])
  }, numeric(1))

  data$calibrated_median_calBP <- unname(medians[ids])
  data$weighted_mean_calBP <- unname(means[ids])
  data$posterior_mass_in_window <- unname(in_window_mass[ids])
  values <- unlist(
    data[c(
      "calibrated_median_calBP", "weighted_mean_calBP",
      "posterior_mass_in_window"
    )],
    use.names = FALSE
  )
  if (any(!is.finite(values)) ||
      any(data$posterior_mass_in_window < 0 | data$posterior_mass_in_window > 1)) {
    rlang::abort(
      "Calibrated posterior summaries are invalid.",
      class = "rcdates_manuscript_figure_error"
    )
  }
  data
}

#' Apply the common calendar-membership and per-site replication gates
#' @param data Calibrated empirical reference.
#' @param buffer Calendar-year buffer inside both analysis boundaries.
#' @param mass_threshold Minimum posterior mass inside the analysis window.
#' @param min_dates Minimum eligible dates per retained site.
#' @param min_age Young analysis-window boundary.
#' @param max_age Old analysis-window boundary.
#' @return Common-membership empirical reference.
filter_manuscript_common_membership <- function(
  data,
  buffer = 100,
  mass_threshold = 0.8,
  min_dates = 5L,
  min_age = 651,
  max_age = 11650
) {
  required <- c(
    "SITE", "calibrated_median_calBP", "weighted_mean_calBP",
    "posterior_mass_in_window"
  )
  valid <- all(required %in% names(data)) &&
    all(is.finite(c(buffer, mass_threshold, min_dates, min_age, max_age))) &&
    buffer >= 0 && min_age + buffer < max_age - buffer &&
    mass_threshold >= 0 && mass_threshold <= 1 &&
    min_dates >= 1L && min_dates == as.integer(min_dates)
  if (!valid) {
    rlang::abort(
      "Common-membership specification is invalid.",
      class = "rcdates_manuscript_figure_error"
    )
  }
  eligible <- data$calibrated_median_calBP >= min_age + buffer &
    data$calibrated_median_calBP <= max_age - buffer &
    data$posterior_mass_in_window >= mass_threshold
  counts <- table(as.character(data$SITE[eligible]))
  retained_sites <- names(counts[counts >= as.integer(min_dates)])
  out <- data[
    eligible & as.character(data$SITE) %in% retained_sites,
    ,
    drop = FALSE
  ]
  if (nrow(out) == 0L || length(retained_sites) == 0L ||
      min(table(out$SITE)) < min_dates) {
    rlang::abort(
      "The common-membership gate retained no valid replicated reference set.",
      class = "rcdates_manuscript_figure_error"
    )
  }
  out
}
