# Set the working directory to project root and import custom functions
setwd("C:/git/rc-dates")

source("./src/austarch_filtering.R") # Functions to filter the AustArch database
source("./src/austarch_display.R") # Functions for plots and tables
source("./src/austarch_sampling.R") # Functions for subsampling
source("./src/austarch_methods.R") # Functions for data analysis

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
  min_dates = 5
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
source("./src/austarch_filtering.R") # Functions to filter the AustArch database
source("./src/austarch_display.R") # Functions for plots and tables
source("./src/austarch_sampling.R") # Functions for subsampling
source("./src/austarch_methods.R") # Functions for data analysis

# Need to run 1000 iterations for all the strategies for 50%
out <- run_sampling_workflow(
  df         = austarch_df,
  strategy   = "bracketed",    # random, oldest, youngest, bracketed
  n_iter     = 10,          # 10 for testing, 1000 for full sampling
  n_samples  = 1,           # set at 1 unless multiton-random
  proportion = NULL,         # NULL for 100% of sites sampled, 0.5 for 50%
  seed       = 1234
)
plot_summarised_curves(out$rebinned)

# Save raw output (450 MB so don't typically save these)
# write.csv(out$raw, "data/simulation_raw_50.csv", row.names = FALSE)
write.csv(out$summary, "data/simulation_summary_50.csv", row.names = FALSE)

# Save plot
png(paste0("figs/curves_", prefix, ".png"), width = 900, height = 600)
print(plot_summarised_curves(out$rebinned))
dev.off()

# Optional: save cloud
# png(paste0("figs/cloud_", prefix, ".png"), width = 900, height = 600)
# print(plot_density_cloud(out$raw, alpha = 0.05))
# dev.off()


library(dplyr)

index = 1; n_site = 4
# 1. Pick four sites (here simply the first four in your full dataset)
sites <- unique(austarch_df$SITE)[index:(index+n_site-1)]

# 2. Subset the full data to those four sites
df <- austarch_df %>% 
  filter(SITE %in% sites)

# 3. Build a one‐iteration site_subset_df that biases exactly two sites
site_subset_df <- tibble(
  iteration = 1,
  SITE      = sites[index:(index+(n_site/2)-1)]
)

# 4. Call the low‐level simulation directly so you can inspect indices
raw <- run_site_simulation(
  df             = df,
  site_subset_df = site_subset_df,
  strategy       = "oldest",  # try “random” here
  n_iter         = 1,
  n_samples      = 1,
  seed           = 1234
)


#write.csv(df,"df.csv", row.names=F)

# 5. Examine which row_indices were actually sampled vs carried through
#    (everything outside your two biased sites should show up as “other”)
#    We’ll regenerate the index_df by hand for clarity:
idx <- generate_index_dataframe(
  df             = df,
  strategy       = "random",
  n_samples      = 1,
  site_subset_df = site_subset_df,
  iteration      = 1
)

# 6. Inspect
print(site_subset_df)
print(idx)
# Check counts per site:
idx %>% count(SITE)   # should have 1 row for each of the two biased sites
df %>% 
  filter(!SITE %in% site_subset_df$SITE) %>% 
  count(SITE)           # should return full counts for the other two sites




