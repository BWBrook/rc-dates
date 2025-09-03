## SPD/FD/KDE summaries and helpers (pure functions)

#' Convert an rcarbon SPD object to a tibble
#' @param spd_obj An SPD object from rcarbon::spd().
#' @return Tibble with columns calBP and PrDens.
#' @export
spd_to_tibble <- function(spd_obj) {
  import::from("tibble", "as_tibble", "tibble")
  df <- as_tibble(spd_obj$grid)
  nms <- names(df)
  # Try common time column names first
  time_candidates <- c("calBP", "calbp", "CalBP", "cal_year_bp", "calYearBP", "yearBP", "year", "time")
  dens_candidates <- c("PrDens", "prdens", "Density", "density", "value", "spd")

  pick_first <- function(cands, nms) {
    cands[which(tolower(cands) %in% tolower(nms))[1]]
  }
  tcol <- pick_first(time_candidates, nms)
  dcol <- pick_first(dens_candidates, nms)
  if (is.na(tcol)) tcol <- nms[[1]]
  if (is.na(dcol)) dcol <- nms[[max(2, length(nms))]]

  tibble(calBP = df[[tcol]], PrDens = as.numeric(df[[dcol]]))
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
  kd <- density(df$weighted_mean_calBP, from = from, to = to, bw = bw, n = n)
  tibble(calBP = kd$x, density = kd$y)
}
