import::from("readr", read_csv, cols_only, col_integer, col_double, col_character)
import::from("dplyr", rename, mutate, select, filter, across, count, inner_join)
import::from("stringr", str_replace_all)
import::from("magrittr", "%>%")

#' Load and clean AustArch radiocarbon dataset from CSV
#'
#' Reads relevant columns, standardises field names, and replaces whitespace with underscores.
#'
#' @param filepath Path to the CSV file.
#' @return A tibble containing the cleaned dataset.
load_austarch_data <- function(filepath) {
  suppressWarnings({
    austarch_df <- read_csv(
      filepath,
      col_types = cols_only(
        ADSID = col_integer(),
        LONGITUDE = col_double(),
        LATITUDE = col_double(),
        SITE = col_character(),
        SITE_TYPE = col_character(),
        LAB_CODE = col_character(),
        AGE = col_double(),
        ERROR = col_double(),
        MATERIAL = col_character(),
        METHOD = col_character(),
        `Data pertinent for time-series analysis or calibration` = col_character(),
        `Open or Closed Site` = col_character(),
        `Directly Related to occupation? Yes/Unknown` = col_character(),
        RECORD_SOURCE = col_character(),
        DATE_ISSUES = col_character()
      )
    ) %>%
      rename(
        TIME_SERIES_RELEVANT = `Data pertinent for time-series analysis or calibration`,
        SITE_STATUS = `Open or Closed Site`,
        OCCUPATION_RELATED = `Directly Related to occupation? Yes/Unknown`
      ) %>%
      mutate(across(c(SITE, SITE_TYPE, MATERIAL), 
                    ~str_replace_all(., "\\s+", "_")))
  })

  return(austarch_df)
}

#' Apply initial quality filters to radiocarbon dataset
#'
#' Retains only radiocarbon entries with valid ages, errors, and contextual relevance.
#'
#' @param df Dataframe of AustArch records.
#' @return A filtered dataframe excluding problematic or invalid records.
filter_austarch_initial <- function(df) {
  df_filtered <- df %>%
    filter(
      METHOD == "Radiocarbon",
      OCCUPATION_RELATED != "N",
      AGE >= 500 & AGE <= 20000,
      ERROR > 0,
      !(DATE_ISSUES %in% c(
        "Date is considered erroneous - see Notes",
        "Date not associated with human activity, or is problematic for time-series analysis - see Notes"
      ))
    ) %>%
    select(-DATE_ISSUES)  # drop DATE_ISSUES explicitly after filtering

  return(df_filtered)
}

#' Filter AustArch data by material type and site context
#'
#' Retains only samples from approved materials and archaeological contexts, and within valid radiocarbon ranges.
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

  # Explicitly exclude problematic dates outside calibration curve range
  df_filtered <- df %>%
    filter(
      MATERIAL %in% valid_materials,
      SITE_TYPE %in% valid_site_types,
      TIME_SERIES_RELEVANT != "Unusuable",
      (AGE - 5 * ERROR) >= 0,          # ensure dates not below 0 BP
      (AGE + 5 * ERROR) <= 55000       # ensure dates not beyond curve limit (55 ka BP)
    )

  return(df_filtered)
}

#' Filter calibrated dates to a defined calendar year range
#'
#' Removes dates with no probability mass in the target interval.
#'
#' @param calibrated_dates A CalDates object.
#' @param min_calBP Minimum calendar BP (default = 100).
#' @param max_calBP Maximum calendar BP (default = 20000).
#' @return A CalDates object containing only dates overlapping the defined range.
filter_calibrated_dates_by_range <- function(calibrated_dates, min_calBP = 100, max_calBP = 20000) {
  retained_ids <- names(calibrated_dates$grids)[
    sapply(calibrated_dates$grids, function(x) {
      any(x$calBP >= min_calBP & x$calBP <= max_calBP)
    })
  ]

  # Subset metadata and grids
  filtered_metadata <- calibrated_dates$metadata[calibrated_dates$metadata$DateID %in% retained_ids, ]
  filtered_grids <- calibrated_dates$grids[retained_ids]

  # Handle calMatrix gracefully
  filtered_calmatrix <- if (!is.null(calibrated_dates$calmatrix) && is.matrix(calibrated_dates$calmatrix)) {
    calibrated_dates$calmatrix[, retained_ids, drop = FALSE]
  } else {
    NULL
  }

  # Rebuild CalDates object
  filtered_calibrated_dates <- list(
    metadata = filtered_metadata,
    grids = filtered_grids,
    calmatrix = filtered_calmatrix
  )

  class(filtered_calibrated_dates) <- "CalDates"
  return(filtered_calibrated_dates)
}

#' Retain sites with a minimum number of calibrated dates
#'
#' Adds weighted mean calibrated age to each row and filters out low-count sites.
#'
#' @param original_df Original filtered dataset.
#' @param calibrated_dates A CalDates object.
#' @param min_dates Minimum number of dates per site (default = 5).
#' @return A dataframe with only robustly sampled sites.
filter_sites_min_calibrated_dates <- function(original_df, calibrated_dates, min_dates = 5) {
  # Extract calibrated ADSIDs
  retained_ids <- as.numeric(calibrated_dates$metadata$DateID)

  # Filter original df to match those calibrated dates
  df_filtered <- original_df %>%
    filter(ADSID %in% retained_ids)

  # Calculate weighted mean calibrated age per date
  weighted_means <- sapply(calibrated_dates$grids, function(grid) {
    sum(grid$calBP * grid$PrDens)
  })

  # Add weighted means as a column back into the filtered df
  df_filtered <- df_filtered %>%
    mutate(weighted_mean_calBP = weighted_means[as.character(ADSID)])

  # Drop the redundant RECORD_SOURCE column
  df_filtered <- df_filtered %>%
    select(-RECORD_SOURCE)

  # Filter to sites with at least min_dates
  df_final <- df_filtered %>%
    count(SITE) %>%
    filter(n >= min_dates) %>%
    inner_join(df_filtered, by = "SITE")

  return(df_final)
}

#' Subset a CalDates object using a vector of ADSIDs
#'
#' Filters metadata, grids, and calMatrix of a CalDates object to include only the specified ADSIDs.
#' Returns a new, valid CalDates object.
#'
#' @param cal_dates A CalDates object (from rcarbon)
#' @param adsids A character or numeric vector of ADSIDs to retain
#' @return A subset CalDates object containing only the specified dates
subset_caldates_by_adsid <- function(cal_dates, adsids) {
  adsids <- as.character(adsids)  # Ensure consistent ID format

  subset_metadata <- cal_dates$metadata[cal_dates$metadata$DateID %in% adsids, ]
  subset_grids <- cal_dates$grids[adsids]

  subset_calmatrix <- if (!is.null(cal_dates$calmatrix) && is.matrix(cal_dates$calmatrix)) {
    cal_dates$calmatrix[, adsids, drop = FALSE]
  } else {
    NULL
  }

  subset_cal_dates <- list(
    metadata = subset_metadata,
    grids = subset_grids,
    calmatrix = subset_calmatrix
  )

  class(subset_cal_dates) <- "CalDates"
  return(subset_cal_dates)
}
