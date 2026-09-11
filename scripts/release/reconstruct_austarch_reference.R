#!/usr/bin/env Rscript

# Reconstruct the 976-record AustArch simulation reference from the deposited
# source table. This is a faithful, explicit translation of the workflow in
# commit 4cedbb3 (src/austarch_analysis.R and src/austarch_func.R), later kept
# as scripts/legacy/austarch_filtering.R and austarch_methods.R.
#
# Source collection: https://doi.org/10.5284/1027216
# Download page:
# https://archaeologydataservice.ac.uk/archives/view/austarch_na_2014/downloads.cfm
# Required file: Austarch_1-3_and_IDASQ_28Nov13-1.csv
#
# Usage:
#   Rscript reconstruct_austarch_reference.R INPUT.csv OUTPUT.csv

source_sha256 <- c(
  # Repository's original 2025 import; verified to reproduce the accepted
  # output under the pinned runtime.
  repository_import = "67cf7f5b10662165544d5a7525ac56b65d109530c51ca00030d39c8275b4fd1d",
  # Fresh ADS download obtained for the 2026 provenance audit. Its 976 accepted
  # records match the source fields used here, but full replay still requires
  # the output checksum gate below.
  ads_2026_download = "bb37e887a57c87173ac5e7b25b034886a6509646a03650eeda559653bcbdb583"
)
output_sha256 <- "2f1b5ccc40038f9e30bce643d57191c545c98448266fcaab3b11c9a33059c70a"

abort <- function(...) stop(sprintf(...), call. = FALSE)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) {
  abort("Usage: Rscript reconstruct_austarch_reference.R INPUT.csv OUTPUT.csv")
}
input_path <- normalizePath(args[[1]], mustWork = TRUE)
output_path <- normalizePath(args[[2]], mustWork = FALSE)
if (identical(input_path, output_path)) abort("Input and output paths must differ.")

required_versions <- c(
  R = "4.5.3",
  rcarbon = "1.5.2",
  readr = "2.2.0",
  dplyr = "1.2.0",
  stringr = "1.6.0",
  digest = "0.6.39"
)
actual_versions <- c(
  R = paste(R.version$major, R.version$minor, sep = "."),
  vapply(names(required_versions)[-1L], function(x) {
    if (!requireNamespace(x, quietly = TRUE)) return(NA_character_)
    as.character(utils::packageVersion(x))
  }, character(1))
)
if (!identical(unname(actual_versions), unname(required_versions))) {
  detail <- paste(
    sprintf("%s required=%s actual=%s", names(required_versions),
            required_versions, actual_versions),
    collapse = "; "
  )
  abort("Runtime does not match the accepted environment: %s", detail)
}

actual_source_sha256 <- digest::digest(
  file = input_path, algo = "sha256", serialize = FALSE
)
source_match <- names(source_sha256)[match(actual_source_sha256, source_sha256)]
if (is.na(source_match)) {
  abort(
    "Input SHA-256 is not a recognized source object: observed %s",
    actual_source_sha256
  )
}

raw <- suppressWarnings(readr::read_csv(
  input_path,
  num_threads = 1,
  show_col_types = FALSE,
  col_types = readr::cols_only(
    ADSID = readr::col_integer(),
    LONGITUDE = readr::col_double(),
    LATITUDE = readr::col_double(),
    SITE = readr::col_character(),
    SITE_TYPE = readr::col_character(),
    LAB_CODE = readr::col_character(),
    AGE = readr::col_double(),
    ERROR = readr::col_double(),
    MATERIAL = readr::col_character(),
    METHOD = readr::col_character(),
    `Data pertinent for time-series analysis or calibration` = readr::col_character(),
    `Open or Closed Site` = readr::col_character(),
    `Directly Related to occupation? Yes/Unknown` = readr::col_character(),
    RECORD_SOURCE = readr::col_character(),
    DATE_ISSUES = readr::col_character()
  )
)) |>
  dplyr::rename(
    TIME_SERIES_RELEVANT = `Data pertinent for time-series analysis or calibration`,
    SITE_STATUS = `Open or Closed Site`,
    OCCUPATION_RELATED = `Directly Related to occupation? Yes/Unknown`
  ) |>
  dplyr::mutate(dplyr::across(
    c(SITE, SITE_TYPE, MATERIAL),
    ~ stringr::str_replace_all(.x, "\\s+", "_")
  ))

if (nrow(raw) != 5522L || anyNA(raw$ADSID) || anyDuplicated(raw$ADSID)) {
  abort("Deposited source structure failed the 5,522-row unique-ADSID check.")
}

date_issue_exclusions <- c(
  "Date is considered erroneous - see Notes",
  paste0(
    "Date not associated with human activity, or is problematic for ",
    "time-series analysis - see Notes"
  )
)

initial <- raw |>
  dplyr::filter(
    METHOD == "Radiocarbon",
    OCCUPATION_RELATED != "N",
    AGE >= 500 & AGE <= 20000,
    ERROR > 0,
    !(DATE_ISSUES %in% date_issue_exclusions)
  ) |>
  dplyr::select(-DATE_ISSUES)

valid_materials <- c(
  "Charcoal", "Charcoal_from_hearth", "Scattered_charcoal",
  "Wood_charcoal", "Carbonised_wood", "Burnt_wood", "Charred_wood", "Wood",
  "Human_bone_collagen",
  "Freshwater_mussel_shell", "Freshwater_shell", "Freshwater_mollusc_shell",
  "Marine_shell", "Anadara_granosa_shell", "Anadara_sp._shell",
  "Anadara_trapezia_shell", "Turbo_sp._shell", "Melo_sp._Shell",
  "Terebralia_sp._shell", "Cellana_sp._shell", "Marine_shell_(oyster)",
  "Gafrarium_tumidum_shell", "Polymesoda_erosa_shell", "Ostrea_angasi_shell"
)
valid_site_types <- c(
  "Midden", "Shell_midden", "Shell_mound", "Shell_mound/midden",
  "Earth/shell_mound", "Earth_mound", "Midden_complex", "Midden/mound",
  "Rockshelter", "Rockshelter_with_midden_deposits",
  "Rockshelter_(contains_midden_type_deposits)",
  "Karst_Cave_with_midden_deposits", "Rockshelter_(hearth)",
  "Rockshelter_with_midden_deposit_(Limstone)",
  "Open_site", "Open_Site_(lunette)", "Open_site_(possible_hearth)",
  "Hearth", "Hearth_within_Open_site", "Hearth_within_Rockshelter",
  "Oven_Mound", "Burial_in_Midden", "Burial_in_Rockshelter"
)

eligible <- initial |>
  dplyr::filter(
    MATERIAL %in% valid_materials,
    SITE_TYPE %in% valid_site_types,
    TIME_SERIES_RELEVANT != "Unusuable",
    AGE - 5 * ERROR >= 0,
    AGE + 5 * ERROR <= 55000
  )

calibrate_group <- function(data, curve, marine = FALSE) {
  call <- list(
    x = data$AGE,
    errors = data$ERROR,
    calCurves = curve,
    ids = as.character(data$ADSID)
  )
  if (marine) {
    call$resOffsets <- 0
    call$resErrors <- 0
  }
  do.call(rcarbon::calibrate, call)
}

terrestrial <- eligible |>
  dplyr::filter(TIME_SERIES_RELEVANT == "Terrestrial")
marine <- eligible |>
  dplyr::filter(TIME_SERIES_RELEVANT == "Marine")
if (!nrow(terrestrial) || !nrow(marine)) {
  abort("Both terrestrial and marine eligible records are required.")
}

calibrated <- rcarbon::combine(
  calibrate_group(terrestrial, "shcal20"),
  calibrate_group(marine, "marine20", marine = TRUE)
)

# Historical semantics: retain a date when its returned calibration grid has
# at least one calendar-year point inside the inclusive analysis window. This
# is posterior overlap, not a filter on the posterior mean or median.
overlap_ids <- names(calibrated$grids)[vapply(
  calibrated$grids,
  function(grid) any(grid$calBP >= 651 & grid$calBP <= 11650),
  logical(1)
)]
calibrated$metadata <- calibrated$metadata[
  calibrated$metadata$DateID %in% overlap_ids, , drop = FALSE
]
calibrated$grids <- calibrated$grids[overlap_ids]

weighted_means <- vapply(
  calibrated$grids,
  function(grid) sum(grid$calBP * grid$PrDens),
  numeric(1)
)
overlapping <- eligible |>
  dplyr::filter(ADSID %in% as.numeric(calibrated$metadata$DateID)) |>
  dplyr::mutate(
    weighted_mean_calBP = weighted_means[as.character(ADSID)]
  ) |>
  dplyr::select(-RECORD_SOURCE)

# count() orders the site groups; the left join order is part of the historical
# CSV byte identity and is therefore retained here.
site_counts <- overlapping |>
  dplyr::count(SITE) |>
  dplyr::filter(n >= 5L)
candidate <- dplyr::inner_join(site_counts, overlapping, by = "SITE")

if (nrow(candidate) != 976L || dplyr::n_distinct(candidate$SITE) != 116L ||
    anyDuplicated(candidate$ADSID) || anyNA(candidate$weighted_mean_calBP)) {
  abort(
    paste0(
      "Reconstruction failed the accepted dimensions: obtained %d records ",
      "from %d sites. Stage counts: raw=%d, initial=%d, eligible=%d, overlap=%d."
    ),
    nrow(candidate), dplyr::n_distinct(candidate$SITE), nrow(raw),
    nrow(initial), nrow(eligible), nrow(overlapping)
  )
}

output_dir <- dirname(output_path)
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
temporary_output <- tempfile("austarch-reference-", tmpdir = output_dir)
on.exit(unlink(temporary_output), add = TRUE)
utils::write.csv(candidate, temporary_output, row.names = FALSE)
actual_output_sha256 <- digest::digest(
  file = temporary_output, algo = "sha256", serialize = FALSE
)
if (!identical(actual_output_sha256, output_sha256)) {
  abort(
    paste0(
      "Dimensions match but output SHA-256 differs: expected %s; observed %s. ",
      "Do not accept this reconstruction without resolving the discrepancy."
    ),
    output_sha256, actual_output_sha256
  )
}
if (file.exists(output_path)) abort("Refusing to overwrite existing output: %s", output_path)
if (!file.rename(temporary_output, output_path)) {
  abort("Could not atomically move the validated output to %s", output_path)
}

message(sprintf(
  paste0(
    "Validated reconstruction from %s written: %d records, %d sites, SHA-256 %s. ",
    "Stage counts: raw=%d, initial=%d, eligible=%d, overlap=%d."
  ),
  source_match, nrow(candidate), dplyr::n_distinct(candidate$SITE), actual_output_sha256,
  nrow(raw), nrow(initial), nrow(eligible), nrow(overlapping)
))
