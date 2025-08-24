# Bootstrap project dependencies using renv + pak

message("[bootstrap] Starting bootstrap...")

# Set a reliable CRAN mirror early (independent of package .onLoad)
options(repos = c(CRAN = "https://packagemanager.posit.co/cran/latest"))

ensure_pkg <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg)
}

ensure_pkg("renv")

has_lock <- file.exists("renv.lock")
if (!has_lock) {
  message("[bootstrap] No renv.lock found; initialising renv (bare).")
  renv::init(bare = TRUE)
}

# Ensure pak is available for fast installs
ensure_pkg("pak")

base_pkgs <- c(
  # runtime
  "targets","tarchetypes","dplyr","readr","purrr","tidyr","sf","terra",
  "arrow","duckdb","config","qs","lgr","progressr","vroom","yaml",
  "checkmate","janitor","dotenv",
  # dev / tooling
  "testthat","lintr","styler","quarto","roxygen2","rcmdcheck",
  "future","future.batchtools","devtools","pak","renv","pkgdown"
)

message("[bootstrap] Installing base packages with pak (this may take a while)...")
install_with_fallback <- function(pkgs) {
  pkgs <- unique(pkgs)
  ok <- FALSE
  err <- NULL
  try({
    # Install to the active renv project library if available
    libpath <- tryCatch(renv::paths$library(), error = function(e) .libPaths()[1])
    pak::pak(pkgs, ask = FALSE, lib = libpath)
    ok <- TRUE
  }, silent = TRUE)
  if (!ok) {
    message("[bootstrap] pak install failed; falling back to install.packages for CRAN pkgs.")
    tryCatch(
      install.packages(pkgs, dependencies = TRUE),
      error = function(e) {
        message("[bootstrap] install.packages() fallback failed: ", conditionMessage(e))
        stop(e)
      }
    )
  }
}

install_with_fallback(base_pkgs)

# Ensure project library has all transitive deps (copy from user lib if needed)
if (requireNamespace("renv", quietly = TRUE)) {
  try(renv::hydrate(prompt = FALSE), silent = TRUE)
}

# Targeted source fallback for some transitive pure-R deps on Windows
for (pkg in c("R.methodsS3", "R.oo", "R.utils")) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message("[bootstrap] Attempting source install for ", pkg, " ...")
    try(install.packages(pkg, type = "source", dependencies = TRUE), silent = TRUE)
  }
}

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

message("[bootstrap] Done.")
