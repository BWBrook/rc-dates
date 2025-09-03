## Plot helpers for SPD/FD/KDE overlays

#' Method palette for SPD/FD/KDE
#' @return Named character vector of hex colors.
#' @keywords internal
method_palette <- function() {
  c(
    SPD = "#1f78b4", # blue
    KDE = "#33a02c", # green
    FD  = "#e31a1c"  # red
  )
}

#' Overlay SPD/FD/KDE as a ggplot
#'
#' @param spd_tbl Tibble with columns calBP, PrDens.
#' @param fd_tbl Tibble with columns bin, value (density per unit).
#' @param kde_tbl Tibble with columns calBP, density.
#' @param smooth_fd Logical; apply moving average smoothing to FD.
#' @param smooth_window Integer kernel width for FD smoothing.
#' @param standardise_mode One of "area" (SPD area to 1) or "none".
#' @return A ggplot object.
#' @export
plot_methods_overlay <- function(spd_tbl, fd_tbl, kde_tbl, smooth_fd = TRUE, smooth_window = 3, standardise_mode = "area") {
  import::from("dplyr", "mutate", "select", "arrange", "bind_rows", "filter", "group_by", "ungroup", "case_when")
  import::from("zoo", "rollmean")
  import::from("ggplot2", "ggplot", "aes", "geom_line", "scale_color_manual", "scale_x_reverse", "scale_y_continuous", "labs", "theme_minimal")

  spd_df <- spd_tbl |>
    select(calBP, PrDens) |>
    mutate(source = "SPD")

  fd_df <- fd_tbl |>
    mutate(source = "FD", calBP = bin, PrDens = value) |>
    select(calBP, PrDens, source)

  if (smooth_fd) {
    fd_df <- fd_df |>
      arrange(calBP) |>
      mutate(PrDens = rollmean(PrDens, k = smooth_window, fill = NA, align = "center"))
  }

  kde_df <- kde_tbl |>
    mutate(source = "KDE", PrDens = density) |>
    select(calBP, PrDens, source)

  combined <- bind_rows(spd_df, fd_df, kde_df) |>
    filter(!is.na(PrDens))

  # Dynamic x-limits from available data to avoid warnings about removed rows
  x_max <- max(combined$calBP, na.rm = TRUE)
  x_min <- min(combined$calBP, na.rm = TRUE)

  if (identical(standardise_mode, "area")) {
    combined <- combined |>
      group_by(source) |>
      mutate(PrDens = case_when(source == "SPD" ~ PrDens / sum(PrDens, na.rm = TRUE), TRUE ~ PrDens)) |>
      ungroup()
  }

  ggplot(combined, aes(x = calBP, y = PrDens, color = source)) +
    geom_line(linewidth = 1) +
    scale_color_manual(values = method_palette()) +
    scale_x_reverse(limits = c(x_max, x_min), expand = c(0, 0)) +
    scale_y_continuous(expand = c(0, 0)) +
    labs(x = "Years cal BP", y = "Scaled density", color = "Method") +
    theme_minimal()
}
