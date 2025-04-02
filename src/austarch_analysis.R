# Set the working directory to project root and import custom functions
setwd("C:/git/rc-dates")
source("./src/austarch_func.r")

austarch_df <- load_austarch_data("./data/Austarch_1-3_and_IDASQ_28Nov13-1.csv")
head(austarch_df)
