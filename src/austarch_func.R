# Import only required functions explicitly using the import library
import::from("readr", read_csv, cols_only, col_integer, col_double, col_character)
import::from("dplyr", rename, mutate, select, across, everything)
import::from("stringr", str_replace_all)
import::from("magrittr", "%>%")

# Load and clean AustArch data function
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
        RECORD_SOURCE = col_character()
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

