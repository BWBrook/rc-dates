import::from("dplyr", mutate, select, group_by, ungroup, row_number, slice_sample, slice_min, slice_max, bind_rows, filter, pull)
import::from("tibble", tibble)

#' Helper function: 
#' Sample n random dates per site
#' Returns a dataframe with columns SITE, sample, and row_index
sample_random_n <- function(df, n) {
  df %>%
    mutate(row_index = as.integer(row_number())) %>%
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
    mutate(row_index = as.integer(row_number())) %>%
    group_by(SITE) %>%
    {
      if (type == "min") slice_min(., AGE, n = 1, with_ties = FALSE)
      else if (type == "max") slice_max(., AGE, n = 1, with_ties = FALSE)
      else stop("Invalid type: must be 'min' or 'max'")
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
generate_index_dataframe <- function(df, n_iter = 1000, strategy = "random", n = 1, seed = NULL, site_subset_df = NULL) {
  if (!is.null(seed)) set.seed(seed)

  df <- df %>% mutate(row_index = as.integer(row_number()))
  all_sites <- unique(df$SITE)
  results <- vector("list", n_iter)

  for (i in seq_len(n_iter)) {
    sites_this_iter <- if (!is.null(site_subset_df)) {
      site_subset_df %>% filter(iteration == i) %>% pull(SITE)
    } else {
      all_sites
    }

    df_sub <- df %>% filter(SITE %in% sites_this_iter)

    sampled <- switch(strategy,
      "random" = sample_random_n(df_sub, n),
      "oldest" = sample_extreme(df_sub, type = "min"),
      "youngest" = sample_extreme(df_sub, type = "max"),
      stop("Unknown strategy: ", strategy)
    )

    results[[i]] <- sampled %>% mutate(iteration = i)
  }

  bind_rows(results)
}

#' Generate row indices for deterministic subsampling strategies
#'
#' Selects the oldest, youngest, or bracketed (oldest + youngest) dates per site with no iteration.
#'
#' @param df Full dataset with all rows (e.g., austarch_final_calibrated_df).
#' @param strategy One of: "oldest", "youngest", "bracketed".
#' @return A tidy dataframe with SITE, sample, row_index, and iteration = 1.
generate_deterministic_index_df <- function(df, strategy = "oldest") {
  df <- df %>% mutate(row_index = as.integer(row_number()))

  if (strategy == "oldest") {
    df %>%
      group_by(SITE) %>%
      slice_max(AGE, n = 1, with_ties = FALSE) %>%
      ungroup() %>%
      mutate(sample = 1L, iteration = 1L) %>%
      select(SITE, sample, row_index, iteration)

  } else if (strategy == "youngest") {
    df %>%
      group_by(SITE) %>%
      slice_min(AGE, n = 1, with_ties = FALSE) %>%
      ungroup() %>%
      mutate(sample = 1L, iteration = 1L) %>%
      select(SITE, sample, row_index, iteration)

  } else if (strategy == "bracketed") {
    df <- df %>% mutate(row_index = as.integer(row_number()))  # ensure this is still correct

    oldest <- df %>%
      group_by(SITE) %>%
      slice_max(AGE, n = 1, with_ties = FALSE) %>%
      mutate(sample = 1L)

    youngest <- df %>%
      group_by(SITE) %>%
      slice_min(AGE, n = 1, with_ties = FALSE) %>%
      mutate(sample = 2L)

    bind_rows(oldest, youngest) %>%
      ungroup() %>%
      mutate(iteration = 1L) %>%
      select(SITE, sample, row_index, iteration)
  } else {
    stop("Unknown deterministic strategy: ", strategy)
  }
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
#' @return A dataframe with columns: iteration, SITE.
generate_site_subset_df <- function(sites, proportion = 0.5, n_iter = 1000, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)

  n_sites <- length(sites)
  n_sample <- round(n_sites * proportion)
  results <- vector("list", n_iter)

  for (i in seq_len(n_iter)) {
    sampled_sites <- sample(sites, n_sample, replace = FALSE)
    results[[i]] <- tibble(
      iteration = i,
      SITE = sampled_sites
    )
  }

  bind_rows(results)
}

#' Construct the full per-iteration dataset for a partial sampling strategy
#'
#' Combines sampled rows from selected sites with full rows from the remaining sites.
#'
#' @param df Full calibrated dataset (e.g., austarch_final_calibrated_df)
#' @param sampled_index_df Row indices from generate_index_dataframe()
#' @param sampled_sites_df Site list per iteration from generate_site_subset_df()
#' @param iteration Iteration number to extract
#' @return A dataframe of rows for calibration/analysis
construct_sampled_dataset <- function(df, sampled_index_df, sampled_sites_df, iteration) {
  df <- df %>% mutate(row_index = as.integer(row_number()))
  all_sites <- unique(df$SITE)

  # Get sites sampled this iteration
  sampled_sites <- sampled_sites_df %>%
    filter(iteration == !!iteration) %>%
    pull(SITE)

  # Sites not sampled = get all their rows
  full_sites <- setdiff(all_sites, sampled_sites)

  full_rows <- df %>%
    filter(SITE %in% full_sites) %>%
    mutate(iteration = iteration, sample = NA_integer_) %>%
    select(SITE, sample, row_index, iteration)

  # Rows sampled under subsampling strategy
  sampled_rows <- sampled_index_df %>%
    filter(iteration == !!iteration)

  bind_rows(sampled_rows, full_rows)
}
