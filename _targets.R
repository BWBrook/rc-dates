# {targets} pipeline for rc-dates (minimal AustArch flow)

targets::tar_option_set(
  seed = 1L,
  packages = character(0) # we use explicit namespace qualifiers/import::from within functions
)

# Source helpers
targets::tar_source("R")

list(
  # Configuration
  targets::tar_target(
    cfg,
    cfg_read(),
    description = "Project configuration (paths, compute flags)."
  ),

  # Manifest and raw file paths
  targets::tar_target(
    raw_manifest,
    read_manifest(cfg$data$manifest),
    description = "CSV manifest of input files."
  ),

  # Grouping by SITE_TYPE (dynamic branching)
  targets::tar_target(
    group_levels,
    sort(unique(validated_strict$SITE_TYPE)),
    description = "Distinct SITE_TYPE values for grouping."
  ),

  targets::tar_target(
    group_spd_summary,
    {
      g <- group_levels
      df_g <- validated_strict[validated_strict$SITE_TYPE == g, , drop = FALSE]
      if (nrow(df_g) == 0) {
        tibble::tibble(calBP = numeric(0), PrDens = numeric(0), SITE_TYPE = g)
      } else {
        fit <- calibrate_and_spd(df_g) # uses consistent 651–11650 window
        tbl <- spd_to_tibble(fit$spd)
        tbl$SITE_TYPE <- g
        tbl
      }
    },
    pattern = map(group_levels),
    iteration = "vector",
    description = "SPD tibble per SITE_TYPE."
  ),

  targets::tar_target(
    group_fd_summary,
    {
      g <- group_levels
      df_g <- weighted_means[weighted_means$SITE_TYPE == g, , drop = FALSE]
      if (nrow(df_g) == 0) return(NULL)
      fd_from_weighted_means(df_g, bin_width = 100, min_age = 651, max_age = 11650) |>
        dplyr::mutate(SITE_TYPE = g)
    },
    pattern = map(group_levels),
    iteration = "vector",
    description = "FD tibble per SITE_TYPE."
  ),

  targets::tar_target(
    group_kde_summary,
    {
      g <- group_levels
      df_g <- weighted_means[weighted_means$SITE_TYPE == g, , drop = FALSE]
      if (nrow(df_g) == 0) return(NULL)
      kde_from_weighted_means(df_g, from = 651, to = 11650, bw = 100, n = 256) |>
        dplyr::mutate(SITE_TYPE = g)
    },
    pattern = map(group_levels),
    iteration = "vector",
    description = "KDE tibble per SITE_TYPE."
  ),

  # Figures (overall and per group)
  targets::tar_target(
    fig_methods_overall,
    {
      p <- plot_methods_overlay(spd_summary, fd_summary, kde_summary, smooth_fd = TRUE, smooth_window = 3)
      fs::dir_create("figs")
      out <- fs::path("figs", "methods_overall.png")
      ggplot2::ggsave(out, p, width = 8, height = 5, dpi = 150)
      out
    },
    format = "file",
    description = "Overall SPD/FD/KDE overlay figure."
  ),

  targets::tar_target(
    fig_methods_by_site_type,
    {
      g <- group_levels
      ads <- validated_strict$ADSID[validated_strict$SITE_TYPE == g]
      cds <- subset_caldates_by_adsid(calibrated, ads)
      fs::dir_create("figs")
      safe_name <- gsub("[^A-Za-z0-9_]+", "_", g)
      out <- fs::path("figs", paste0("methods_", safe_name, ".png"))
      if (length(cds$metadata$DateID) == 0) {
        # Write a placeholder file to satisfy format = "file"
        ggplot2::ggsave(out, ggplot2::ggplot() + ggplot2::labs(title = paste("No data for", g)), width = 8, height = 5, dpi = 150)
        return(out)
      }
      spd_tbl <- spd_to_tibble(rcarbon::spd(cds, timeRange = c(11650, 651), spdnormalised = TRUE))
      df_g <- weighted_means[weighted_means$SITE_TYPE == g, , drop = FALSE]
      fd_tbl <- fd_from_weighted_means(df_g)
      kde_tbl <- kde_from_weighted_means(df_g)
      p <- plot_methods_overlay(spd_tbl, fd_tbl, kde_tbl, smooth_fd = TRUE, smooth_window = 3)
      ggplot2::ggsave(out, p, width = 8, height = 5, dpi = 150)
      out
    },
    pattern = map(group_levels),
    iteration = "vector",
    format = "file",
    description = "Per-SITE_TYPE SPD/FD/KDE overlay figures."
  ),
  targets::tar_target(
    raw_files,
    raw_manifest$path,
    format = "file",
    description = "Resolved input file paths (tracked as files)."
  ),

  # Ingest raw table(s)
  targets::tar_target(
    raw_tbl,
    {
      import::from("dplyr", "bind_rows")
      tbls <- lapply(raw_files, load_austarch_data)
      bind_rows(tbls)
    },
    description = "Ingested raw data as tibble from all input files."
  ),

  # Validation / filtering
  targets::tar_target(
    validated,
    raw_tbl |>
      filter_austarch_initial() |>
      filter_austarch_material_site(),
    description = "Cleaned/validated AustArch tibble."
  ),

  # Strict schema and constraint validation (gates downstream steps)
  targets::tar_target(
    validated_strict,
    {
      validate_austarch_schema(validated)
      validated
    },
    description = "Schema-validated AustArch tibble (strict checks)."
  ),

  # Intermediate storage (Arrow preferred; CSV fallback)
  targets::tar_target(
    interim_parquet,
    {
      import::from("fs", "dir_create", "path")
      out_dir <- cfg$outputs$dir
      dir_create(path(out_dir, "interim"))
      out_file <- path(out_dir, "interim", if (isTRUE(cfg$compute$use_arrow)) "validated_strict.parquet" else "validated_strict.csv")
      if (isTRUE(cfg$compute$use_arrow) && requireNamespace("arrow", quietly = TRUE)) {
        arrow::write_parquet(validated_strict, out_file)
      } else {
        readr::write_csv(validated_strict, out_file)
      }
      out_file
    },
    format = "file",
    description = "Intermediate normalised storage of validated data."
  ),

  # Model fit / SPD summary (Holocene range)
  targets::tar_target(
    model_fit,
    calibrate_and_spd(validated_strict),
    description = "Calibrated dates and SPD summary object (651–11650 cal BP)."
  ),

  # Expose CalDates separately (avoid recalibration elsewhere)
  targets::tar_target(
    calibrated,
    model_fit$calibrated,
    description = "CalDates object from the full validated dataset."
  ),

  # Weighted means and site-level filter (min_dates=1 for toy dataset)
  targets::tar_target(
    weighted_means,
    filter_sites_min_calibrated_dates(validated_strict, calibrated, min_dates = 1),
    description = "Validated data with weighted_mean_calBP and site min-date filter applied."
  ),

  # Method summaries
  targets::tar_target(
    spd_summary,
    spd_to_tibble(model_fit$spd),
    description = "SPD grid as a tibble (calBP, PrDens)."
  ),
  targets::tar_target(
    fd_summary,
    fd_from_weighted_means(weighted_means, bin_width = 100, min_age = 651, max_age = 11650),
    description = "Frequency distribution from weighted mean calibrated ages."
  ),
  targets::tar_target(
    kde_summary,
    kde_from_weighted_means(weighted_means, from = 651, to = 11650, bw = 100, n = 512),
    description = "Kernel density estimate from weighted mean calibrated ages."
  ),

  # Report rendering: render to same directory as source file
  targets::tar_target(
    report,
    {
      qmd <- "reports/paper.qmd"
      out_dir <- dirname(qmd)
      # Render with Quarto if available; otherwise write a simple placeholder HTML
      has_quarto <- requireNamespace("quarto", quietly = TRUE) && !is.na(tryCatch(quarto::quarto_path(), error = function(e) NA))
      base <- tools::file_path_sans_ext(basename(qmd))
      html <- file.path(out_dir, paste0(base, ".html"))
      ok <- FALSE
      if (has_quarto) {
        ok <- isTRUE(tryCatch({
          quarto::quarto_render(input = qmd, quiet = TRUE)
          file.exists(html)
        }, error = function(e) FALSE))
      }
      if (!ok) {
        writeLines("<html><body><p>Report placeholder (Quarto not available or render failed).</p></body></html>", html)
      }
      html
    },
    format = "file",
    description = "Rendered Quarto report artifact."
  )
)
