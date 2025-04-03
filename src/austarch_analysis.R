# Set the working directory to project root and import custom functions
setwd("C:/git/rc-dates")
source("./src/austarch_func.r")

# Load the raw AustArch data, exclude irrelevant columns and standardise names
austarch_df <- load_austarch_data("./data/Austarch_1-3_and_IDASQ_28Nov13-1.csv")

# First filtering step: radiocarbon method, occupation-related, valid ages/errors, excluding known problematic entries
austarch_filter_1_df <- filter_austarch_initial(austarch_df)

# Second filtering step: retaining only robust, occupation-associated material and site types, explicitly removing unusable entries
austarch_filter_2_df <- filter_austarch_material_site(austarch_filter_1_df)

# Explicitly filter calibrated dates
austarch_calibrated_dates <- calibrate_dates(austarch_filter_2_df)

austarch_calibrated_filtered <- filter_calibrated_dates_by_range(
  austarch_calibrated_dates, 
  min_calBP = 651, 
  max_calBP = 11650 # Holocene boundary, and 11 ka span
)

# Select only sites with at least 5 dates within the calibrated Holocene dates
austarch_final_calibrated_df <- filter_sites_min_calibrated_dates(
  original_df = austarch_filter_2_df,
  calibrated_dates = austarch_calibrated_filtered,
  min_dates = 5
)

# Check explicitly final results
length(unique(austarch_final_calibrated_df$SITE))
str(austarch_final_calibrated_df)

write.csv(austarch_final_calibrated_df, "./data/austarch_filtered.csv", row.names = FALSE)
