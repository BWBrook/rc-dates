import::from("dplyr", mutate, select, group_by, ungroup, row_number, slice_sample, slice_min, slice_max, bind_rows, filter, pull)
import::from("tibble", tibble)
import::from("purrr", map_dfr)

#' Helper function: 
#' Sample n random dates per site
#' Returns a dataframe with columns SITE, sample, and row_index
sample_random_n <- function(df, n) {
  df %>%
    group_by(SITE) %>%
    slice_sample(n = n, replace = FALSE) %>%
    mutate(sample = row_number()) %>%
    ungroup() %>%
    select(SITE, sample, row_index)
}

#' Helper function: 
#' Sample a single oldest or youngest date per site
#' Returns a dataframe with SITE, sample, and row_index
sample_extreme <- function(df, type = "min") {
  df %>%
    group_by(SITE) %>%
    {
      if (type == "min") slice_min(., AGE, n = 1, with_ties = FALSE)
      else               slice_max(., AGE, n = 1, with_ties = FALSE)
    } %>%
    ungroup() %>%
    mutate(sample = 1L) %>%
    select(SITE, sample, row_index)
}

#' Generate row index samples for subsampling strategies, optionally using a site subset
#'
#' Samples rows from a site-strategy only for the specified subset of sites per iteration.
#' If no subset is provided, defaults to sampling all sites (100% scenario).
#'
#' @param df Full dataset (e.g., austarch_final_calibrated_df)
#' @param n_iter Number of iterations
#' @param strategy One of: "random", "oldest", "youngest"
#' @param n Number of samples per site (default = 1)
#' @param seed Random seed for reproducibility
#' @param site_subset_df Optional dataframe of sampled sites per iteration (from generate_site_subset_df)
#' @return A tidy dataframe of sampled row indices
generate_index_dataframe <- function(
  df,
  n_iter        = 1000,
  strategy      = "random",
  n_samples     = 1,
  seed          = NULL,
  site_subset_df= NULL,
  iteration     = NULL
) {
  if (!is.null(seed)) set.seed(seed)
  df <- df %>% mutate(row_index = as.integer(row_number()))

  # If caller has pre‐filtered site_subset_df and given us the iteration number,
  # just do one pass and tag with that iteration:
  if (!is.null(site_subset_df) && !is.null(iteration)) {
    sites_this_iter <- site_subset_df$SITE
    df_sub <- df %>% filter(SITE %in% sites_this_iter)
    sampled <- switch(strategy,
      "random"    = sample_random_n(df_sub, n_samples),
      "oldest"    = sample_extreme(df_sub, "max"),
      "youngest"  = sample_extreme(df_sub, "min"),
      "bracketed" = bind_rows(
                       sample_extreme(df_sub, "max") %>% mutate(sample = 1),
                       sample_extreme(df_sub, "min") %>% mutate(sample = 2)
                     ),
      stop("Unknown strategy: ", strategy)
    )
    return(
      sampled %>% mutate(iteration = iteration)
    )
  }

  # Otherwise fall back to the old multi‐iteration logic:
  results <- vector("list", n_iter)
  all_sites <- unique(df$SITE)
  for (i in seq_len(n_iter)) {
    sites_this_iter <-
      if (!is.null(site_subset_df)) {
        site_subset_df %>% filter(iteration == i) %>% pull(SITE)
      } else {
        all_sites
      }
    df_sub  <- df %>% filter(SITE %in% sites_this_iter)
    sampled <- switch(strategy,
      "random"    = sample_random_n(df_sub, n_samples),
      "oldest"    = sample_extreme(df_sub, "max"),
      "youngest"  = sample_extreme(df_sub, "min"),
      "bracketed" = bind_rows(
                       sample_extreme(df_sub, "max") %>% mutate(sample = 1),
                       sample_extreme(df_sub, "min") %>% mutate(sample = 2)
                     ),
      stop("Unknown strategy: ", strategy)
    )
    results[[i]] <- sampled %>% mutate(iteration = i)
  }
  bind_rows(results)
}

#' Generate random subsets of sites for partial subsampling (e.g., 50%, 75%)
#'
#' For each iteration, randomly selects a proportion of sites to apply a sampling strategy to.
#' Returns a tidy dataframe listing which sites are sampled per iteration.
#'
#' @param sites A character vector of site names (e.g., unique(austarch_final_calibrated_df$SITE)).
#' @param proportion Proportion of sites to sample per iteration (default = 0.5).
#' @param n_iter Number of iterations (default = 1000).
#' @param seed Optional seed for reproducibility.
#' @return A tibble with columns: iteration, SITE.
generate_site_subset_df <- function(sites, proportion = 0.5, n_iter = 1000, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  n_sites <- length(sites)
  n_sample <- round(n_sites * proportion)
  map_dfr(seq_len(n_iter), function(i) {
    tibble(
      iteration = i,
      SITE      = sample(sites, n_sample)
    )
  })
}
