# Set the working directory to project root and import custom functions
setwd("C:/git/rc-dates")

source("./src/austarch_filtering.R") # Functions to filter the AustArch database
source("./src/austarch_sampling.R") # Functions for subsampling
source("./src/austarch_methods.R") # Functions for data analysis
source("./src/austarch_display.R") # Functions for plots and tables

# Load the raw AustArch data, exclude irrelevant columns and standardise names
austarch_df <- load_austarch_data("./data/Austarch_1-3_and_IDASQ_28Nov13-1.csv")

# First filtering step: radiocarbon method, occupation-related, valid ages/errors, excluding known problematic entries
austarch_df <- filter_austarch_initial(austarch_df)

# Second filtering step: retaining only robust, occupation-associated material and site types, explicitly removing unusable entries
austarch_df <- filter_austarch_material_site(austarch_df)

# Explicitly filter calibrated dates
austarch_cal_dates <- calibrate_dates(austarch_df)

austarch_cal_dates <- filter_calibrated_dates_by_range(
  austarch_cal_dates, 
  min_calBP = 651, 
  max_calBP = 11650 # Holocene boundary, and 11 ka span
)

# Select only sites with at least 5 dates within the calibrated Holocene dates
austarch_df <- filter_sites_min_calibrated_dates(
  original_df = austarch_df,
  calibrated_dates = austarch_cal_dates,
  min_dates = 1
)

# Check explicitly final results
str(austarch_df)
hist(austarch_df$weighted_mean_calBP)
#write.csv(austarch_df, "./data/austarch_filtered.csv", row.names = FALSE)

plot_radiocarbon_vs_calibrated(austarch_df)
summarise_calibrated_dataset(austarch_df)

austarch_cal_dates <- subset_caldates_by_adsid(
  cal_dates = austarch_cal_dates,
  adsids = austarch_df$ADSID
)

# This is the result for the equivalent of 0% sampling, i.e., ALL dates are used
baseline_spd <- generate_spd_baseline(austarch_cal_dates)
baseline_fd <- generate_fd_baseline(austarch_df)
baseline_kde <- generate_kde_baseline(austarch_df)

pb <- plot_baseline_methods(
  spd_obj = baseline_spd,
  fd_df = baseline_fd,
  kde_df = baseline_kde,
  smooth_fd = TRUE,
  smooth_window = 2,
  standardise = TRUE
)

# Save as vector PDF
ggsave("rc_fig1.pdf", pb, device = cairo_pdf)

#####
# Need to run 1000 iterations for all the strategies for 50% and random for 100%
out <- run_sampling_workflow(
  df         = austarch_df,
  strategy   = "oldest",    # random, oldest, youngest, bracketed
  n_iter     = 10,        # 10 for testing, 1000 for full sampling
  n_samples  = 1,           # set at 1 unless multiton-random
  proportion = NULL,         # NULL for 100% of sites sampled, 0.5 for 50%
  seed       = 1234
)
plot_summarised_curves(out$rebinned)
write.csv(out$summary, "data/simulation_summary_multiton_50.csv", row.names = FALSE)
# write.csv(out$raw, "data/simulation_raw_50.csv", row.names = FALSE) # ~450 MB

# Save plot
png("figs/curves_multiton_50.png", width = 900, height = 600)
print(plot_summarised_curves(out$rebinned))
dev.off()

# Optional: save cloud
# png("figs/cloud_random_50.png", width = 900, height = 600)
# print(plot_density_cloud(out$raw, alpha = 0.05))
# dev.off()

# Create individual plot for combined panel plot
plot_rebin(rebin_summary_df(read_csv("data/simulation_summary_multiton_50.csv")), 
           show_xlabel=T, show_ylabel=T, annot_label="Multiton")
