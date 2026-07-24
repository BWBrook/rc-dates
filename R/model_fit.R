## Model utilities: calibration and SPD summary

#' Calibrate AustArch dates and compute SPD
#'
#' Uses rcarbon to calibrate dates based on AGE/ERROR and a simple rule for
#' calibration curves (marine vs terrestrial), then summarizes the summed
#' probability distribution (SPD) over a default range.
#'
#' @param df Tibble produced by validation filters, containing AGE, ERROR, ADSID,
#'   and TIME_SERIES_RELEVANT at minimum.
#' @param time_range Integer vector length 2: c(min_calBP, max_calBP).
#' @param terrestrial_curve Character scalar (e.g., "shcal20").
#' @param marine_curve Character scalar (e.g., "marine20").
#' @return A list with elements `calibrated` (CalDates) and `spd` (rcarbon SPD object).
#' @export
calibrate_and_spd <- function(df, time_range = c(651L, 11650L), terrestrial_curve = "shcal20", marine_curve = "marine20") {
  import::from("rcarbon", "calibrate", "spd")
  import::from("rlang", "abort")

  if (!all(c("ADSID", "AGE", "ERROR") %in% names(df))) {
    abort("Input data missing required columns ADSID/AGE/ERROR", class = "rcdates_model_error")
  }

  # Determine calibration curves using helper
  env <- if ("TIME_SERIES_RELEVANT" %in% names(df)) df$TIME_SERIES_RELEVANT else rep(NA_character_, nrow(df))
  curves <- choose_calibration_curves(env, terrestrial_curve = terrestrial_curve, marine_curve = marine_curve)

  cds <- calibrate(
    x = as.numeric(df$AGE),
    errors = as.numeric(df$ERROR),
    ids = as.character(df$ADSID),
    calCurves = curves,
    normalised = TRUE
  )

  # Ensure filtering uses increasing bounds, but SPD gets decreasing (as rcarbon expects)
  tr_min <- min(time_range)
  tr_max <- max(time_range)
  cds <- filter_calibrated_dates_by_range(cds, min_calBP = tr_min, max_calBP = tr_max)

  spd_obj <- spd_from_caldates(cds, time_range = c(tr_min, tr_max))
  list(calibrated = cds, spd = spd_obj)
}

#' Choose calibration curves given environment labels
#' @param env Character vector (e.g., values of TIME_SERIES_RELEVANT)
#' @param terrestrial_curve Default curve for non-marine contexts
#' @param marine_curve Default curve for marine contexts
#' @return Character vector of curves
#' @export
choose_calibration_curves <- function(env, terrestrial_curve = "shcal20", marine_curve = "marine20") {
  env_low <- tolower(env)
  ifelse(!is.na(env_low) & grepl("marine", env_low), marine_curve, terrestrial_curve)
}

#' SPD from a CalDates object using a time range
#' @param cds A CalDates object
#' @param time_range Integer vector length 2: c(min_calBP, max_calBP)
#' @return An SPD object
#' @export
spd_from_caldates <- function(cds, time_range = c(651L, 11650L)) {
  import::from("rcarbon", "spd")
  tr_min <- min(time_range)
  tr_max <- max(time_range)
  if (length(cds$grids) == 0L) {
    return(list(grid = data.frame(calBP = numeric(0), PrDens = numeric(0))))
  }
  spd(cds, timeRange = c(tr_max, tr_min), spdnormalised = TRUE)
}
