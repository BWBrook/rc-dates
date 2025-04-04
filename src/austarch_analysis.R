# Set the working directory to project root and import custom functions
setwd("C:/git/rc-dates")

source("./src/austarch_filtering.R") # Functions to filter the AustArch database

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
hist(austarch_final_calibrated_df$weighted_mean_calBP)
#write.csv(austarch_final_calibrated_df, "./data/austarch_filtered.csv", row.names = FALSE)

#####

source("./src/austarch_display.R") # Functions for plots and tables

plot_radiocarbon_vs_calibrated(austarch_final_calibrated_df)
summarise_calibrated_dataset(austarch_final_calibrated_df)

#####
source("./src/austarch_methods.R") # Functions for data analysis

austarch_final_calibrated <- subset_caldates_by_adsid(
  cal_dates = austarch_calibrated_filtered,
  adsids = austarch_final_calibrated_df$ADSID
)

baseline_spd <- generate_spd_baseline(austarch_calibrated_filtered)
baseline_fd <- generate_fd_baseline(austarch_final_calibrated_df)
baseline_kde <- generate_kde_baseline(austarch_final_calibrated_df)

plot_baseline_methods(
  spd_obj = baseline_spd,
  fd_df = baseline_fd,
  kde_df = baseline_kde,
  smooth_fd = TRUE,
  smooth_window = 5,
  standardize = TRUE
)

