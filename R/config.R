## Configuration helpers for the rc-dates compendium
##
## These helpers read a YAML config (via the {config} package) if present,
## and otherwise fall back to sensible defaults suitable for a fast, toy
## dataset workflow. Configured relative paths stay relative so cached targets
## remain portable across WSL and macOS checkouts.

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

default_simulation_config <- function() {
  list(
    mode = "demo",
    precomputed = list(
      dir = "data",
      pattern = "^simulation_summary_.*\\.csv$"
    ),
    demo = list(
      iterations = 2L,
      seed = 1234L,
      site_proportions = c(0.5, 1.0),
      strategies = c("oldest", "youngest", "bracketed", "singleton", "multiton"),
      singleton_n = 1L,
      multiton_n = 3L
    )
  )
}

#' Read project configuration
#'
#' Reads `config/config.yml` using `{config}` if available; otherwise returns
#' an internal default configuration suitable for local development and tests.
#' Relative paths are normalised but kept relative for portable target caching.
#'
#' @param active Name of the active config (defaults to `Sys.getenv("R_CONFIG_ACTIVE", "default")`).
#' @return A named list with configuration values.
#' @export
cfg_read <- function(active = Sys.getenv("R_CONFIG_ACTIVE", unset = "default")) {
  import::from("here", "here")
  import::from("fs", "is_absolute_path", "path_norm")

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
      ),
      branching = list(
        site = list(include = NULL, exclude = NULL, limit = NULL)
      ),
      report = list(
        site_figures = list(include = NULL, exclude = NULL, limit = 12L, montage = TRUE, ncol = 3L)
      ),
      simulate = default_simulation_config()
    )
  }

  # Normalise common path entries without baking the checkout root into targets.
  normalise <- function(x) {
    if (is.character(x) && length(x) == 1L) {
      if (is_absolute_path(x)) return(x)
      return(path_norm(x))
    }
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

  # Backfill branching/report defaults
  if (is.null(cfg$branching) || !is.list(cfg$branching)) cfg$branching <- list()
  if (is.null(cfg$branching$site) || !is.list(cfg$branching$site)) cfg$branching$site <- list()
  if (is.null(cfg$branching$site$include)) cfg$branching$site$include <- NULL
  if (is.null(cfg$branching$site$exclude)) cfg$branching$site$exclude <- NULL
  if (is.null(cfg$branching$site$limit))   cfg$branching$site$limit   <- NULL

  if (is.null(cfg$report) || !is.list(cfg$report)) cfg$report <- list()
  if (is.null(cfg$report$site_figures) || !is.list(cfg$report$site_figures)) cfg$report$site_figures <- list()
  sf <- cfg$report$site_figures
  if (is.null(sf$include)) sf$include <- NULL
  if (is.null(sf$exclude)) sf$exclude <- NULL
  if (is.null(sf$limit))   sf$limit   <- 12L
  if (is.null(sf$montage)) sf$montage <- TRUE
  if (is.null(sf$ncol))    sf$ncol    <- 3L
  cfg$report$site_figures <- sf

  if (is.null(cfg$simulate) || !is.list(cfg$simulate)) cfg$simulate <- list()
  sim_defaults <- default_simulation_config()
  if (is.null(cfg$simulate$mode)) {
    if (!is.null(cfg$simulate$use_precomputed)) {
      cfg$simulate$mode <- if (isTRUE(cfg$simulate$use_precomputed)) "precomputed" else "none"
    } else {
      cfg$simulate$mode <- sim_defaults$mode
    }
  }
  cfg$simulate$mode <- tolower(as.character(cfg$simulate$mode))
  if (!(cfg$simulate$mode %in% c("demo", "precomputed", "none"))) {
    stop("simulate.mode must be one of: demo, precomputed, none", call. = FALSE)
  }

  if (is.null(cfg$simulate$precomputed) || !is.list(cfg$simulate$precomputed)) cfg$simulate$precomputed <- list()
  if (is.null(cfg$simulate$precomputed$dir) && !is.null(cfg$simulate$dir)) cfg$simulate$precomputed$dir <- cfg$simulate$dir
  if (is.null(cfg$simulate$precomputed$pattern) && !is.null(cfg$simulate$pattern)) cfg$simulate$precomputed$pattern <- cfg$simulate$pattern
  if (is.null(cfg$simulate$precomputed$dir)) cfg$simulate$precomputed$dir <- sim_defaults$precomputed$dir
  if (is.null(cfg$simulate$precomputed$pattern)) cfg$simulate$precomputed$pattern <- sim_defaults$precomputed$pattern
  cfg$simulate$precomputed$dir <- normalise(cfg$simulate$precomputed$dir)

  if (is.null(cfg$simulate$demo) || !is.list(cfg$simulate$demo)) cfg$simulate$demo <- list()
  if (is.null(cfg$simulate$demo$iterations)) cfg$simulate$demo$iterations <- sim_defaults$demo$iterations
  if (is.null(cfg$simulate$demo$seed)) cfg$simulate$demo$seed <- sim_defaults$demo$seed
  if (is.null(cfg$simulate$demo$site_proportions)) cfg$simulate$demo$site_proportions <- sim_defaults$demo$site_proportions
  if (is.null(cfg$simulate$demo$strategies)) cfg$simulate$demo$strategies <- sim_defaults$demo$strategies
  if (is.null(cfg$simulate$demo$singleton_n)) cfg$simulate$demo$singleton_n <- sim_defaults$demo$singleton_n
  if (is.null(cfg$simulate$demo$multiton_n)) cfg$simulate$demo$multiton_n <- sim_defaults$demo$multiton_n

  cfg
}
