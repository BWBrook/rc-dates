library(patchwork)

setwd("C:/git/rc-dates")
source("./src/austarch_filtering.R") # Functions to filter the AustArch database
source("./src/austarch_sampling.R") # Functions for subsampling
source("./src/austarch_methods.R") # Functions for data analysis
source("./src/austarch_display.R") # Functions for plots and tables

p_oldest_50 <- plot_rebin(rebin_summary_df(read_csv("data/simulation_summary_oldest_50.csv")), 
                          show_xlabel=F, show_ylabel=T, annot_label="Oldest")
p_youngest_50 <- plot_rebin(rebin_summary_df(read_csv("data/simulation_summary_youngest_50.csv")), 
                          show_xlabel=F, show_ylabel=T, annot_label="Youngest")
p_bracketed_50 <- plot_rebin(rebin_summary_df(read_csv("data/simulation_summary_bracketed_50.csv")), 
                          show_xlabel=F, show_ylabel=T, annot_label="Bracketed")
p_singleton_50 <- plot_rebin(rebin_summary_df(read_csv("data/simulation_summary_singleton_50.csv")), 
                          show_xlabel=F, show_ylabel=T, annot_label="random-1")
p_multiton_50 <- plot_rebin(rebin_summary_df(read_csv("data/simulation_summary_multiton_50.csv")), 
                          show_xlabel=T, show_ylabel=T, annot_label="random-5")
p_oldest_100 <- plot_rebin(rebin_summary_df(read_csv("data/simulation_summary_oldest_100.csv")), 
                          show_xlabel=F, show_ylabel=F, annot_label="Oldest")
p_youngest_100 <- plot_rebin(rebin_summary_df(read_csv("data/simulation_summary_youngest_100.csv")), 
                          show_xlabel=F, show_ylabel=F, annot_label="Youngest")
p_bracketed_100 <- plot_rebin(rebin_summary_df(read_csv("data/simulation_summary_bracketed_100.csv")), 
                          show_xlabel=F, show_ylabel=F, annot_label="Bracketed")
p_singleton_100 <- plot_rebin(rebin_summary_df(read_csv("data/simulation_summary_singleton_100.csv")), 
                          show_xlabel=F, show_ylabel=F, annot_label="random-1")
p_multiton_100 <- plot_rebin(rebin_summary_df(read_csv("data/simulation_summary_multiton_100.csv")), 
                          show_xlabel=T, show_ylabel=F, annot_label="random-5")
# 1. Build two header “plots” that contain only the text
p_hdr1 <- ggplot() +
  annotate("text", x = 0.5, y = 0,
           label = "50% of sites re-sampled",
           size  = 5) +
  theme_void()  # no axes, no panel

p_hdr2 <- ggplot() +
  annotate("text", x = 0.5, y = 0,
           label = "100% of sites re-sampled",
           size  = 5) +
  theme_void()

# 2. Gather your 10 real plots in row-major order
plots <- list(
  p_hdr1,           p_hdr2,            # the two headers
  p_oldest_50,      p_oldest_100,
  p_youngest_50,    p_youngest_100,
  p_bracketed_50,   p_bracketed_100,
  p_singleton_50,   p_singleton_100,
  p_multiton_50,    p_multiton_100
)

# 3. Tell patchwork how to lay them out:
#    6 rows (1 header + 5 data), 2 columns
panel <- wrap_plots(plots, ncol = 2, nrow = 6,
                    # give the header row a smaller height
                    heights = c(0.2, rep(1, 5))
)

# 4. Save as vector PDF
ggsave("panel_with_column_titles.pdf", panel,
       width  = 12,   height = 24,   # adjust to taste
       device = cairo_pdf)
