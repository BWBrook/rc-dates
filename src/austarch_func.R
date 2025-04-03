# Explicit import of required functions
import::from("readr", read_csv, cols_only, col_integer, col_double, col_character)
import::from("dplyr", rename, mutate, select, filter, across, group_by, ungroup, n, count, inner_join, summarise, arrange, bind_rows, n_distinct)
import::from("stringr", str_replace_all)
import::from("magrittr", "%>%")
import::from("rcarbon", calibrate, combine)
import::from("ggplot2", ggplot, aes, geom_line, theme_minimal, labs, scale_x_reverse)

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

calibrate_dates <- function(df, terrestrial_curve = "shcal20", marine_curve = "marine20", reservoir_age = 0, reservoir_error = 0) {
  
  df <- df %>%
    mutate(UNIQUE_ID = as.character(ADSID)) %>%
    filter(!is.na(UNIQUE_ID))  # ensure all are present

  terrestrial_samples <- df %>% filter(TIME_SERIES_RELEVANT == "Terrestrial")
  marine_samples <- df %>% filter(TIME_SERIES_RELEVANT == "Marine")

  message("Calibrating ", nrow(terrestrial_samples), " terrestrial and ", nrow(marine_samples), " marine dates...")

  calibrated_list <- list()

  if (nrow(terrestrial_samples) > 0) {
    cal_terrestrial <- calibrate(
      x = terrestrial_samples$AGE,
      errors = terrestrial_samples$ERROR,
      calCurves = terrestrial_curve,
      ids = terrestrial_samples$UNIQUE_ID
    )
    calibrated_list <- append(calibrated_list, list(cal_terrestrial))
  }

  if (nrow(marine_samples) > 0) {
    cal_marine <- calibrate(
      x = marine_samples$AGE,
      errors = marine_samples$ERROR,
      calCurves = marine_curve,
      resOffsets = reservoir_age,
      resErrors = reservoir_error,
      ids = marine_samples$UNIQUE_ID
    )
    calibrated_list <- append(calibrated_list, list(cal_marine))
  }

  if (length(calibrated_list) == 1) {
    return(calibrated_list[[1]])
  } else {
    return(do.call(rcarbon::combine, calibrated_list))
  }
}

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

bin_age_distribution <- function(df, age_col, bin_width = 250, min_age = 0, max_age = 12000) {
  df %>%
    mutate(
      bin = floor(.data[[age_col]] / bin_width) * bin_width
    ) %>%
    filter(bin >= min_age & bin <= max_age) %>%
    count(bin) %>%
    arrange(bin)
}

plot_radiocarbon_vs_calibrated <- function(df, bin_width = 250, min_age = 0, max_age = 12000) {
  rc_bins <- bin_age_distribution(df, "AGE", bin_width, min_age, max_age)
  cal_bins <- bin_age_distribution(df, "weighted_mean_calBP", bin_width, min_age, max_age)

  rc_bins$source <- "Radiocarbon age"
  cal_bins$source <- "Calibrated weighted mean"

  combined <- bind_rows(rc_bins, cal_bins)

  ggplot(combined, aes(x = bin, y = n, color = source)) +
    geom_line(linewidth = 1) +
    scale_x_reverse(limits = c(max_age, min_age)) +
    labs(
      title = "Temporal Distribution of Radiocarbon vs Calibrated Ages",
      x = "Years cal BP",
      y = "Count per bin",
      color = "Date type"
    ) +
    theme_minimal()
}

summarise_calibrated_dataset <- function(df) {
  
  material_summary <- df %>%
    count(MATERIAL, sort = TRUE)

  site_type_summary <- df %>%
    count(SITE_TYPE, sort = TRUE)

  dates_per_site <- df %>%
    count(SITE) %>%
    arrange(desc(n))

  temporal_spread <- df %>%
    group_by(SITE) %>%
    summarise(
      min_cal = min(weighted_mean_calBP),
      max_cal = max(weighted_mean_calBP),
      span = max_cal - min_cal,
      n_dates = n(),
      .groups = "drop"
    ) %>%
    arrange(desc(span))

  summary_list <- list(
    materials = material_summary,
    site_types = site_type_summary,
    dates_per_site = dates_per_site,
    temporal_spread = temporal_spread
  )

  return(summary_list)
}
