## Simulation readers, manifests, and plotting

#' Parse scenario and size from a simulation summary filename
#' @param path File path like 'data/simulation_summary_singleton_50.csv'
#' @return list(scenario=character(1), size=integer(1) or NA)
#' @export
parse_sim_filename <- function(path) {
  import::from("fs", "path_file")
  import::from("stringr", "str_match")
  fname <- path_file(path)
  m <- str_match(fname, "^simulation_summary_([^_]+)_([0-9]+)\\.csv$")
  if (!is.na(m[1, 1])) {
    list(scenario = m[1, 2], size = as.integer(m[1, 3]))
  } else {
    # Fallback: try without size
    m2 <- str_match(fname, "^simulation_summary_([^_]+)\\.csv$")
    list(scenario = ifelse(is.na(m2[1, 2]), "unknown", m2[1, 2]), size = NA_integer_)
  }
}

#' Build a manifest of available simulation summary files
#' @param dir Directory to scan
#' @param pattern Regex to match filenames
#' @param origin Source label for the manifest rows.
#' @return Tibble with columns path (absolute), scenario, size, origin.
#' @export
read_sim_manifest <- function(dir, pattern = "^simulation_summary_.*\\.csv$", origin = "precomputed") {
  import::from("fs", "dir_exists")
  import::from("here", "here")
  d <- if (dir_exists(dir)) dir else here(dir)
  files <- list.files(d, pattern = pattern, full.names = TRUE)
  build_sim_manifest_from_paths(files, origin = origin)
}

#' Read a simulation summary CSV into a tidy tibble
#' @param path Path to a CSV with columns method, calBP, mean, lower, upper
#' @return Tibble with columns method, calBP, mean, lower, upper, scenario, size
#' @export
read_sim_table <- function(path) {
  import::from("readr", "read_csv", "cols_only", "col_character", "col_double")
  import::from("dplyr", "filter", "mutate")
  import::from("tibble", "tibble")
  meta <- parse_sim_filename(path)
  tbl <- suppressWarnings(read_csv(
    path,
    num_threads = 1,
    show_col_types = FALSE,
    col_types = cols_only(
      method = col_character(),
      calBP = col_double(),
      mean = col_double(),
      lower = col_double(),
      upper = col_double()
    )
  ))
  if (!all(c("method", "calBP", "mean") %in% names(tbl))) {
    return(tibble(method = character(0), calBP = numeric(0), mean = numeric(0), lower = numeric(0), upper = numeric(0), scenario = character(0), size = integer(0)))
  }
  tbl |>
    filter(!is.na(method) & nzchar(method)) |>
    mutate(scenario = meta$scenario, size = meta$size)
}

#' Plot overlay of simulation means with optional uncertainty ribbons
#' @param df Tibble from read_sim_table (possibly rbind of multiple files), filtered to one scenario
#' @return ggplot object
#' @export
plot_sim_overlay <- function(df) {
  import::from("ggplot2", "ggplot", "aes", "geom_line", "geom_ribbon", "scale_color_manual", "scale_fill_manual", "scale_x_reverse", "labs", "theme_minimal")
  pal <- method_palette()
  ggplot(df, aes(x = calBP, y = mean, color = method, fill = method)) +
    geom_ribbon(aes(ymin = lower, ymax = upper), alpha = 0.15, linewidth = 0, show.legend = FALSE) +
    geom_line(linewidth = 1) +
    scale_color_manual(values = pal, guide = "legend") +
    scale_fill_manual(values = pal) +
    scale_x_reverse() +
    labs(x = "Years cal BP", y = "Mean density", color = "Method", title = unique(df$scenario)) +
    theme_minimal()
}
