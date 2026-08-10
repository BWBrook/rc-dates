## AustArch data loading and filtering helpers (pure functions)

#' Load and clean AustArch radiocarbon dataset from CSV
#'
#' Reads relevant columns, standardises field names, and replaces whitespace
#' with underscores in select categorical fields.
#'
#' @param filepath Path to the CSV file.
#' @return A tibble containing the cleaned dataset.
load_austarch_data <- function(filepath) {
  if (length(filepath) != 1L || !file.exists(filepath)) {
    rlang::abort(
      paste("AustArch input file does not exist:", filepath),
      class = "rcdates_data_error"
    )
  }
  suppressWarnings({
    austarch_df <- readr::read_csv(
      filepath,
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
    ) |>
      dplyr::rename(
        TIME_SERIES_RELEVANT = `Data pertinent for time-series analysis or calibration`,
        SITE_STATUS = `Open or Closed Site`,
        OCCUPATION_RELATED = `Directly Related to occupation? Yes/Unknown`
      ) |>
      dplyr::mutate(dplyr::across(
        c(SITE, SITE_TYPE, MATERIAL),
        ~ stringr::str_replace_all(., "\\s+", "_")
      ))
  })
  austarch_df
}

#' Apply initial quality filters to radiocarbon dataset
#'
#' Retains only radiocarbon entries with valid ages, errors, and contextual relevance.
#'
#' @param df Dataframe of AustArch records.
#' @return A filtered dataframe excluding problematic or invalid records.
filter_austarch_initial <- function(df) {
  df |>
    dplyr::filter(
      METHOD == "Radiocarbon",
      OCCUPATION_RELATED != "N",
      AGE >= 500 & AGE <= 20000,
      ERROR > 0,
      !(DATE_ISSUES %in% c(
        "Date is considered erroneous - see Notes",
        "Date not associated with human activity, or is problematic for time-series analysis - see Notes"
      ))
    ) |>
    dplyr::select(-DATE_ISSUES)
}

#' Filter AustArch data by material type and site context
#'
#' Restricts to approved materials and site types, and valid radiocarbon ranges.
#'
#' @param df Dataframe of filtered AustArch records.
#' @return A cleaned dataframe restricted to valid materials and site types.
filter_austarch_material_site <- function(df) {
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
    "Oven_Mound",
    "Burial_in_Midden", "Burial_in_Rockshelter"
  )

  df |>
    dplyr::filter(
      MATERIAL %in% valid_materials,
      SITE_TYPE %in% valid_site_types,
      TIME_SERIES_RELEVANT != "Unusuable",
      (AGE - 5 * ERROR) >= 0,
      (AGE + 5 * ERROR) <= 55000
    )
}

#' Filter calibrated dates to a defined calendar year range
#' @param calibrated_dates A CalDates object.
#' @param min_calBP Minimum calendar BP (default = 100).
#' @param max_calBP Maximum calendar BP (default = 20000).
#' @return A CalDates object containing only dates overlapping the defined range.
filter_calibrated_dates_by_range <- function(calibrated_dates, min_calBP = 100, max_calBP = 20000) {
  pick_time_col <- function(df) {
    nms <- names(df)
    nms_low <- tolower(nms)
    cand <- c("calbp", "cal_year_bp", "yearbp", "year", "time")
    for (c in cand) {
      i <- which(nms_low == c)[1]
      if (length(i) == 1 && !is.na(i)) return(nms[[i]])
    }
    nms[[1]]
  }
  retained_ids <- names(calibrated_dates$grids)[
    vapply(
      calibrated_dates$grids,
      function(x) {
        tcol <- pick_time_col(x)
        any(x[[tcol]] >= min_calBP & x[[tcol]] <= max_calBP)
      },
      logical(1)
    )
  ]

  filtered_metadata <- calibrated_dates$metadata[calibrated_dates$metadata$DateID %in% retained_ids, ]
  filtered_grids <- calibrated_dates$grids[retained_ids]

  filtered_calmatrix <- if (!is.null(calibrated_dates$calmatrix) && is.matrix(calibrated_dates$calmatrix)) {
    calibrated_dates$calmatrix[, retained_ids, drop = FALSE]
  } else {
    NULL
  }

  filtered <- list(
    metadata = filtered_metadata,
    grids = filtered_grids,
    calmatrix = filtered_calmatrix
  )
  class(filtered) <- "CalDates"
  filtered
}
