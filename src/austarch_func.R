# Explicit import of required functions
import::from("readr", read_csv, cols_only, col_integer, col_double, col_character)
import::from("dplyr", rename, mutate, select, filter, across, group_by, ungroup, n)
import::from("stringr", str_replace_all)
import::from("magrittr", "%>%")

# Load AustArch data (including DATE_ISSUES temporarily)
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

# First filtering sweep
filter_austarch_initial <- function(df) {
  df_filtered <- df %>%
    filter(
      METHOD == "Radiocarbon",
      OCCUPATION_RELATED != "N",
      AGE >= 1000 & AGE <= 12000,
      ERROR > 0,
      !(DATE_ISSUES %in% c(
        "Date is considered erroneous - see Notes",
        "Date not associated with human activity, or is problematic for time-series analysis - see Notes"
      ))
    ) %>%
    select(-DATE_ISSUES)  # drop DATE_ISSUES explicitly after filtering

  return(df_filtered)
}

# Second filtering step (material, site_type, and unusable time series)
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

  df_filtered <- df %>%
    filter(
      MATERIAL %in% valid_materials,
      SITE_TYPE %in% valid_site_types,
      TIME_SERIES_RELEVANT != "Unusuable"  # explicitly remove Unusuable entries
    )

  return(df_filtered)
}

# Choose only sites with ≥5 dates
filter_sites_min_dates <- function(df, min_dates = 5) {
  df_filtered <- df %>%
    group_by(SITE) %>%
    filter(n() >= min_dates) %>%
    ungroup()

  return(df_filtered)
}
