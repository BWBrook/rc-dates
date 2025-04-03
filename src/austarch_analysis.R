# Set the working directory to project root and import custom functions
setwd("C:/git/rc-dates")
source("./src/austarch_func.r")

# Load the raw AustArch data, exclude irrelevant columns and standardise names
austarch_df <- load_austarch_data("./data/Austarch_1-3_and_IDASQ_28Nov13-1.csv")

# First filtering step: radiocarbon method, occupation-related, valid ages/errors, excluding known problematic entries
austarch_filter_1_df <- filter_austarch_initial(austarch_df)

# Second filtering step: retaining only robust, occupation-associated material and site types, explicitly removing unusable entries
austarch_filter_2_df <- filter_austarch_material_site(austarch_filter_1_df)

# Apply the final site filter explicitly:
austarch_final_df <- filter_sites_min_dates(austarch_filter_2_df, min_dates = 5)

# Check final filtered dataset and write to file:
length(unique(austarch_final_df$SITE))
str(austarch_final_df)
write.csv(austarch_final_df, "./data/austarch_filtered.csv", row.names = FALSE)
