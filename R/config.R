## Configuration helpers for the rc-dates compendium
##
## These helpers read a YAML config (via the {config} package) if present,
## and otherwise fall back to sensible defaults suitable for a fast, toy
## dataset workflow. Paths are resolved via here::here() for portability.

#' Absolute path resolver
#'
#' Resolve a path relative to the project root using `here::here()` unless
#' it is already absolute.
#' @param path Character scalar path.
#' @return Absolute path as a character scalar.
#' @examples
#' # resolve_path("inst/extdata/austarch_example.csv")
resolve_path <- function(path) {
  import::from("checkmate", "assert_string")
  import::from("here", "here")
  import::from("fs", "is_absolute_path")
  assert_string(path, na.ok = FALSE)
  if (is_absolute_path(path)) {
    return(path)
  }
  here(path)
}

#' Read project configuration
#'
#' Reads `config/config.yml` using `{config}` if available; otherwise returns
#' an internal default configuration suitable for local development and tests.
#' All relative paths are resolved to absolute paths.
#'
#' @param active Name of the active config (defaults to `Sys.getenv("R_CONFIG_ACTIVE", "default")`).
#' @return A named list with configuration values.
#' @export
cfg_read <- function(active = Sys.getenv("R_CONFIG_ACTIVE", unset = "default")) {
  import::from("here", "here")

  cfg_path <- here("config", "config.yml")
  if (file.exists(cfg_path)) {
    cfg <- config::get(config = active, file = cfg_path)
  } else {
    cfg <- list(
      data = list(
        manifest = "metadata/data_manifest.csv",
        example = "inst/extdata/austarch_example.csv"
      ),
      outputs = list(dir = "outputs"),
      compute = list(use_arrow = TRUE, write_parquet = TRUE),
      calibration = list(
        terrestrial_curve = "shcal20",
        marine_curve = "marine20",
        time_range = c(651L, 11650L)
      )
    )
  }

  # Normalise common path entries if present
  normalise <- function(x) {
    if (is.character(x) && length(x) == 1L) return(resolve_path(x))
    x
  }

  if (!is.null(cfg$data$manifest)) cfg$data$manifest <- normalise(cfg$data$manifest)
  if (!is.null(cfg$data$example))  cfg$data$example  <- normalise(cfg$data$example)
  if (!is.null(cfg$outputs$dir))   cfg$outputs$dir   <- normalise(cfg$outputs$dir)

  # Backfill calibration defaults if missing in user config
  if (is.null(cfg$calibration) || !is.list(cfg$calibration)) cfg$calibration <- list()
  if (is.null(cfg$calibration$terrestrial_curve)) cfg$calibration$terrestrial_curve <- "shcal20"
  if (is.null(cfg$calibration$marine_curve))      cfg$calibration$marine_curve      <- "marine20"
  if (is.null(cfg$calibration$time_range))        cfg$calibration$time_range        <- c(651L, 11650L)

  cfg
}
