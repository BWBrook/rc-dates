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

# This is the result for the equivalent of 0% sampling, i.e., ALL dates are used
baseline_spd <- generate_spd_baseline(austarch_calibrated_filtered)
baseline_fd <- generate_fd_baseline(austarch_final_calibrated_df)
baseline_kde <- generate_kde_baseline(austarch_final_calibrated_df)

plot_baseline_methods(
  spd_obj = baseline_spd,
  fd_df = baseline_fd,
  kde_df = baseline_kde,
  smooth_fd = TRUE,
  smooth_window = 3,
  standardise = TRUE
)

# Save plot
png("figs/baseline_curves.png", width = 900, height = 600)
print(plot_baseline_methods(
  spd_obj = baseline_spd,
  fd_df = baseline_fd,
  kde_df = baseline_kde,
  smooth_fd = TRUE,
  smooth_window = 3,
  standardise = TRUE
))
dev.off()

#####

source("./src/austarch_sampling.R") # Functions for subsampling

prefix <- "multiton_100"

index_df <- generate_index_dataframe(
  df = austarch_final_calibrated_df,
  n_iter = 100,
  strategy = "random",
  n = 5,
  seed = 1234
)

simulated_curves <- run_simulation_curves_preallocated_light(
  df = austarch_final_calibrated_df,
  index_df = index_df,
  n_iter = 100,
  standardise_mode = "area"
)

# prefix <- "singleton_50"
# 
# site_subset_df_50 <- generate_site_subset_df(
#   sites = unique(austarch_final_calibrated_df$SITE),
#   proportion = 0.5,
#   n_iter = 1000,
#   seed = 1234
# )
# 
# index_df_50 <- generate_index_dataframe(
#   df = austarch_final_calibrated_df,
#   n_iter = 1000,
#   strategy = "random",
#   n = 1,
#   seed = 1234,
#   site_subset_df = site_subset_df_50
# )
# 
# simulated_curves_50 <- run_simulation_curves_partial_preallocated(
#   df = austarch_final_calibrated_df,
#   sampled_index_df = index_df_50,
#   sampled_sites_df = site_subset_df_50,
#   n_iter = 1000,
#   standardise_mode = "area"
# )
# 
# summary_df_50 <- summarise_iteration_curves(simulated_curves_50)
# plot_summarised_curves(summary_df_50)

# Save raw output (450 MB so don't typically save these)
# write.csv(simulated_curves, paste0("data/simulation_curves_", prefix, ".csv"), row.names = FALSE)

# Summarise and save
summary_df <- summarise_iteration_curves(simulated_curves)
write.csv(summary_df, paste0("data/simulation_summary_", prefix, ".csv"), row.names = FALSE)

# Create plot dataframe and do visual check
summary_df_rebinned <- rebin_summary_df(summary_df)
plot_summarised_curves(summary_df_rebinned)

# Save plot
png(paste0("figs/curves_", prefix, ".png"), width = 900, height = 600)
print(plot_summarised_curves(summary_df_rebinned))
dev.off()

# Optional: save cloud
png(paste0("figs/cloud_", prefix, ".png"), width = 900, height = 600)
print(plot_density_cloud(simulated_curves, alpha = 0.05))
dev.off()

# Temporarily save the calls here for quick reloading after changing the internal functions
source("./src/austarch_display.R") # Functions for plots and tables
source("./src/austarch_sampling.R") # Functions for subsampling
source("./src/austarch_methods.R") # Functions for data analysis

summary_df %>%
  group_by(method) %>%
  summarise(total_area = sum(mean))


simulated_curves <- run_simulation_curves(
  df = austarch_final_calibrated_df,
  index_df = index_df,
  n_iter = 1000
)
