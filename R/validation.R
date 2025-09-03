## Schema and value validation for AustArch datasets

#' Validate schema and key constraints for AustArch data
#'
#' Verifies required columns, basic types, and value constraints expected after
#' initial filtering. Returns the input data frame invisibly on success and
#' aborts with class `rcdates_schema_error` on failure.
#'
#' @param x A data frame (post-filtered AustArch data).
#' @return `x` invisibly if validation passes.
#' @export
validate_austarch_schema <- function(x) {
  import::from("checkmate", "assert_data_frame", "test_integerish", "test_double", "test_character")
  import::from("rlang", "abort")

  assert_data_frame(x, min.cols = 10L, min.rows = 1L)

  # Required columns post-rename in load_austarch_data()
  required <- c(
    "ADSID", "LONGITUDE", "LATITUDE", "SITE", "SITE_TYPE", "LAB_CODE",
    "AGE", "ERROR", "MATERIAL", "METHOD", "TIME_SERIES_RELEVANT",
    "SITE_STATUS", "OCCUPATION_RELATED", "RECORD_SOURCE"
  )
  require_columns(x, required, class = "rcdates_schema_error")

  problems <- character(0)

  # Types (vectorised checks)
  if (!test_integerish(x$ADSID, any.missing = FALSE)) problems <- c(problems, "ADSID must be integerish and non-missing")
  if (!test_double(x$LONGITUDE, any.missing = FALSE)) problems <- c(problems, "LONGITUDE must be numeric and non-missing")
  if (!test_double(x$LATITUDE, any.missing = FALSE)) problems <- c(problems, "LATITUDE must be numeric and non-missing")
  if (!test_character(x$SITE, any.missing = FALSE)) problems <- c(problems, "SITE must be character and non-missing")
  if (!test_character(x$SITE_TYPE, any.missing = FALSE)) problems <- c(problems, "SITE_TYPE must be character and non-missing")
  if (!test_character(x$LAB_CODE, any.missing = FALSE)) problems <- c(problems, "LAB_CODE must be character and non-missing")
  if (!test_double(x$AGE, any.missing = FALSE)) problems <- c(problems, "AGE must be numeric and non-missing")
  if (!test_double(x$ERROR, any.missing = FALSE)) problems <- c(problems, "ERROR must be numeric and non-missing")
  if (!test_character(x$MATERIAL, any.missing = FALSE)) problems <- c(problems, "MATERIAL must be character and non-missing")
  if (!test_character(x$METHOD, any.missing = FALSE)) problems <- c(problems, "METHOD must be character and non-missing")
  if (!test_character(x$TIME_SERIES_RELEVANT, any.missing = FALSE)) problems <- c(problems, "TIME_SERIES_RELEVANT must be character and non-missing")
  if (!test_character(x$SITE_STATUS, any.missing = FALSE)) problems <- c(problems, "SITE_STATUS must be character and non-missing")
  if (!test_character(x$OCCUPATION_RELATED, any.missing = FALSE)) problems <- c(problems, "OCCUPATION_RELATED must be character and non-missing")
  if (!test_character(x$RECORD_SOURCE, any.missing = FALSE)) problems <- c(problems, "RECORD_SOURCE must be character and non-missing")

  # Key value constraints (post-initial filters)
  if (!all(x$METHOD == "Radiocarbon")) problems <- c(problems, "All rows must have METHOD == 'Radiocarbon'")
  if (!all(x$AGE >= 500 & x$AGE <= 20000)) problems <- c(problems, "AGE must be within [500, 20000] BP after filtering")
  if (!all(x$ERROR > 0)) problems <- c(problems, "ERROR must be strictly positive")
  # Physically plausible ranges used in prior filters
  if (!all((x$AGE - 5 * x$ERROR) >= 0)) problems <- c(problems, "AGE - 5*ERROR must be >= 0")
  if (!all((x$AGE + 5 * x$ERROR) <= 55000)) problems <- c(problems, "AGE + 5*ERROR must be <= 55000")
  # Uniqueness of ADSID
  if (length(unique(x$ADSID)) != nrow(x)) problems <- c(problems, "ADSID must be unique per row")

  if (length(problems) > 0) {
    abort(paste0("Schema validation failed:\n- ", paste(problems, collapse = "\n- ")), class = "rcdates_schema_error")
  }

  invisible(x)
}
