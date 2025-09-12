## SPD/FD/KDE summaries and helpers (pure functions)

#' Convert an rcarbon SPD object to a tibble
#' @param spd_obj An SPD object from rcarbon::spd().
#' @return Tibble with columns calBP and PrDens.
#' @export
spd_to_tibble <- function(spd_obj) {
  import::from("tibble", "as_tibble", "tibble")
  df <- as_tibble(spd_obj$grid)
  nms <- names(df)
  nms_low <- tolower(trimws(nms))
  # Candidate names (lower case)
  time_candidates <- c("calbp", "cal_year_bp", "calyearbp", "yearbp", "year", "time")
  dens_candidates <- c("prdens", "density", "value", "spd")

  find_actual <- function(candidates) {
    for (cand in candidates) {
      idx <- which(nms_low == cand)[1]
      if (length(idx) == 1 && !is.na(idx)) return(nms[[idx]])
    }
    NA_character_
  }

  tcol <- find_actual(time_candidates)
  dcol <- find_actual(dens_candidates)
  if (is.na(tcol)) tcol <- nms[[1]]
  if (is.na(dcol)) {
    # pick first column that's not tcol, or fallback to first
    d_idx <- which(nms != tcol)[1]
    dcol <- if (length(d_idx) == 1 && !is.na(d_idx)) nms[[d_idx]] else nms[[1]]
  }

  tibble(calBP = as.numeric(df[[tcol]]), PrDens = as.numeric(df[[dcol]]))
}

#' Frequency distribution (FD) from weighted mean calibrated ages
#' @param df Dataframe with column `weighted_mean_calBP`.
#' @param bin_width Bin width in cal BP (default 100).
#' @param min_age Minimum cal BP to include (default 651).
#' @param max_age Maximum cal BP to include (default 11650).
#' @return Tibble with columns bin and value (density per unit cal BP).
#' @export
fd_from_weighted_means <- function(df, bin_width = 100, min_age = 651, max_age = 11650) {
  import::from("dplyr", "mutate", "filter", "count", "arrange", "select")
  df |>
    mutate(bin = floor(.data$weighted_mean_calBP / bin_width) * bin_width) |>
    filter(bin >= min_age & bin <= max_age) |>
    count(bin, name = "n") |>
    mutate(value = n / sum(n) / bin_width) |>
    select(bin, value) |>
    arrange(bin)
}

#' KDE from weighted mean calibrated ages
#' @param df Dataframe with column `weighted_mean_calBP`.
#' @param from Minimum cal BP (default 651).
#' @param to Maximum cal BP (default 11650).
#' @param bw Gaussian bandwidth (default 100).
#' @param n Number of evaluation points (default 512).
#' @return Tibble with columns calBP and density.
#' @export
kde_from_weighted_means <- function(df, from = 651, to = 11650, bw = 100, n = 512) {
  import::from("stats", "density")
  import::from("tibble", "tibble")
  x <- df$weighted_mean_calBP
  if (length(x) < 2 || all(is.na(x))) {
    return(tibble(calBP = numeric(0), density = numeric(0)))
  }
  kd <- density(x, from = from, to = to, bw = bw, n = n)
  tibble(calBP = kd$x, density = kd$y)
}
