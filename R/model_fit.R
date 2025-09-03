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
#' @return A list with elements `calibrated` (CalDates) and `spd` (rcarbon SPD object).
#' @export
calibrate_and_spd <- function(df, time_range = c(651L, 11650L)) {
  import::from("rcarbon", "calibrate", "spd")
  import::from("rlang", "abort")

  if (!all(c("ADSID", "AGE", "ERROR") %in% names(df))) {
    abort("Input data missing required columns ADSID/AGE/ERROR", class = "rcdates_model_error")
  }

  # Determine calibration curves: default to intcal20 unless explicitly marine
  env <- if ("TIME_SERIES_RELEVANT" %in% names(df)) tolower(df$TIME_SERIES_RELEVANT) else NA_character_
  curves <- ifelse(!is.na(env) & grepl("marine", env), "marine20", "intcal20")

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

  tr_desc <- c(tr_max, tr_min)
  spd_obj <- spd(cds, timeRange = tr_desc, spdnormalised = TRUE)
  list(calibrated = cds, spd = spd_obj)
}
