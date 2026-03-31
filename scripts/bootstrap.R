# Bootstrap project dependencies using renv + pak

message("[bootstrap] Starting bootstrap...")

# Set a reliable CRAN mirror early (independent of package .onLoad)
options(repos = c(CRAN = "https://packagemanager.posit.co/cran/latest"))

project_renv_version <- function(path = "renv/activate.R") {
  line <- grep('version <- "', readLines(path, warn = FALSE), value = TRUE)[1]
  sub('.*"([0-9.]+)".*', "\\1", line)
}

ensure_pkg <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg)
}

ensure_project_renv <- function() {
  target <- project_renv_version()
  installed <- if (requireNamespace("renv", quietly = TRUE)) as.character(utils::packageVersion("renv")) else NA_character_
  if (!identical(installed, target)) {
    url <- sprintf("https://cran.r-project.org/src/contrib/Archive/renv/renv_%s.tar.gz", target)
    install.packages(url, repos = NULL, type = "source")
  }
}

ensure_pkg("renv")
ensure_project_renv()

has_lock <- file.exists("renv.lock")
if (!has_lock) {
  message("[bootstrap] No renv.lock found; initialising renv (bare).")
  renv::init(bare = TRUE)
}

# Ensure pak is available for fast installs
ensure_pkg("pak")
source("dependencies.R")

base_pkgs <- setdiff(project_dependencies(), "renv")
optional_pkgs <- setdiff(project_dependencies(include_optional = TRUE), project_dependencies())

message("[bootstrap] Installing base packages with pak (this may take a while)...")
install_with_fallback <- function(pkgs) {
  pkgs <- unique(pkgs)
  libpath <- tryCatch(renv::paths$library(), error = function(e) .libPaths()[1])
  ok <- FALSE
  try({
    pak::pak(pkgs, ask = FALSE, lib = libpath)
    ok <- TRUE
  }, silent = TRUE)
  if (!ok) {
    message("[bootstrap] pak install failed; falling back to install.packages for CRAN pkgs.")
    tryCatch(
      install.packages(pkgs, dependencies = TRUE, lib = libpath),
      error = function(e) {
        message("[bootstrap] install.packages() fallback failed: ", conditionMessage(e))
        stop(e)
      }
    )
  }
}

install_with_fallback(base_pkgs)

message("[bootstrap] Installing optional packages when available...")
tryCatch(
  install_with_fallback(optional_pkgs),
  error = function(e) {
    message("[bootstrap] Optional packages skipped: ", conditionMessage(e))
  }
)

# Targeted source fallback for some transitive pure-R deps on Windows
for (pkg in c("R.methodsS3", "R.oo", "R.utils")) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message("[bootstrap] Attempting source install for ", pkg, " ...")
    try(install.packages(pkg, type = "source", dependencies = TRUE), silent = TRUE)
  }
}

snapshot_requested <- tolower(Sys.getenv("RC_DATES_BOOTSTRAP_SNAPSHOT", unset = "false")) %in% c("true", "1", "yes")
if (snapshot_requested) {
  message("[bootstrap] Snapshotting lockfile with renv...")
  ## Make sure low-level deps exist in project lib before snapshot
  for (pkg in c("BH", "cpp11")) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      message("[bootstrap] Installing missing dependency ", pkg, " ...")
      tryCatch(
        renv::install(pkg),
        error = function(e) try(install.packages(pkg), silent = TRUE)
      )
    }
  }
  renv::snapshot(prompt = FALSE)
} else {
  message("[bootstrap] Skipping renv::snapshot(); set RC_DATES_BOOTSTRAP_SNAPSHOT=true to update renv.lock.")
}

message("[bootstrap] Done.")
