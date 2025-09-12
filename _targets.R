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
        fit <- calibrate_and_spd(
          df_g,
          time_range = cfg$calibration$time_range,
          terrestrial_curve = cfg$calibration$terrestrial_curve,
          marine_curve = cfg$calibration$marine_curve
        )
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
      fd_from_weighted_means(
        df_g,
        bin_width = 100,
        min_age = min(cfg$calibration$time_range),
        max_age = max(cfg$calibration$time_range)
      ) |>
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
      kde_from_weighted_means(
        df_g,
        from = min(cfg$calibration$time_range),
        to   = max(cfg$calibration$time_range),
        bw = 100, n = 256
      ) |>
        dplyr::mutate(SITE_TYPE = g)
    },
    pattern = map(group_levels),
    iteration = "vector",
    description = "KDE tibble per SITE_TYPE."
  ),

  # SITE-level dynamic branching
  targets::tar_target(
    site_levels,
    filter_levels_by_cfg(
      sort(unique(validated_strict$SITE)),
      include = cfg$branching$site$include,
      exclude = cfg$branching$site$exclude,
      limit   = cfg$branching$site$limit
    ),
    description = "Distinct SITE values for SITE-level grouping (config-filtered)."
  ),

  targets::tar_target(
    site_spd_summary,
    {
      s <- site_levels
      df_s <- validated_strict[validated_strict$SITE == s, , drop = FALSE]
      if (nrow(df_s) == 0) {
        tibble::tibble(calBP = numeric(0), PrDens = numeric(0), SITE = s)
      } else {
        fit <- calibrate_and_spd(
          df_s,
          time_range = cfg$calibration$time_range,
          terrestrial_curve = cfg$calibration$terrestrial_curve,
          marine_curve = cfg$calibration$marine_curve
        )
        tbl <- spd_to_tibble(fit$spd)
        tbl$SITE <- s
        tbl
      }
    },
    pattern = map(site_levels),
    iteration = "vector",
    description = "SPD tibble per SITE."
  ),

  targets::tar_target(
    site_fd_summary,
    {
      s <- site_levels
      df_s <- weighted_means[weighted_means$SITE == s, , drop = FALSE]
      if (nrow(df_s) == 0) return(NULL)
      fd_from_weighted_means(
        df_s,
        bin_width = 100,
        min_age = min(cfg$calibration$time_range),
        max_age = max(cfg$calibration$time_range)
      ) |>
        dplyr::mutate(SITE = s)
    },
    pattern = map(site_levels),
    iteration = "vector",
    description = "FD tibble per SITE."
  ),

  targets::tar_target(
    site_kde_summary,
    {
      s <- site_levels
      df_s <- weighted_means[weighted_means$SITE == s, , drop = FALSE]
      if (nrow(df_s) == 0) return(NULL)
      kde_from_weighted_means(
        df_s,
        from = min(cfg$calibration$time_range),
        to   = max(cfg$calibration$time_range),
        bw = 100, n = 256
      ) |>
        dplyr::mutate(SITE = s)
    },
    pattern = map(site_levels),
    iteration = "vector",
    description = "KDE tibble per SITE."
  ),

  targets::tar_target(
    fig_methods_by_site,
    {
      s <- site_levels
      ads <- validated_strict$ADSID[validated_strict$SITE == s]
      cds <- subset_caldates_by_adsid(calibrated, ads)
      fs::dir_create("figs")
      safe_name <- gsub("[^A-Za-z0-9_]+", "_", s)
      out <- fs::path("figs", paste0("methods_site_", safe_name, ".png"))
      if (length(cds$metadata$DateID) == 0) {
        ggplot2::ggsave(out, ggplot2::ggplot() + ggplot2::labs(title = paste("No data for", s)), width = 8, height = 5, dpi = 150)
        return(out)
      }

      # SPD
      grid_cols <- tryCatch({ if (length(cds$grids) > 0) names(cds$grids[[1]]) else character(0) }, error = function(e) character(0))
      message(sprintf("[SITE:%s] first grid cols: %s", s, paste(grid_cols, collapse = ", ")))
      spd_tbl <- tryCatch({ spd_to_tibble(spd_from_caldates(cds, time_range = cfg$calibration$time_range)) },
                          error = function(e) { message(sprintf("[SITE:%s] spd_to_tibble failed: %s", s, e$message)); tibble::tibble(calBP = numeric(0), PrDens = numeric(0)) })
      if (!all(c("calBP", "PrDens") %in% names(spd_tbl))) {
        if (!"calBP" %in% names(spd_tbl) && length(spd_tbl) >= 1) spd_tbl$calBP <- spd_tbl[[1]]
        if (!"PrDens" %in% names(spd_tbl) && length(spd_tbl) >= 2) spd_tbl$PrDens <- spd_tbl[[2]]
        spd_tbl <- spd_tbl[, intersect(c("calBP", "PrDens"), names(spd_tbl)), drop = FALSE]
      }
      message(sprintf("[SITE:%s] spd cols: %s", s, paste(names(spd_tbl), collapse = ", ")))

      # FD
      df_s <- weighted_means[weighted_means$SITE == s, , drop = FALSE]
      fd_tbl <- tryCatch({
        if (nrow(df_s) > 0) {
          fd_from_weighted_means(
            df_s,
            min_age = min(cfg$calibration$time_range),
            max_age = max(cfg$calibration$time_range)
          )
        } else {
          tibble::tibble(bin = numeric(0), value = numeric(0))
        }
      }, error = function(e) { message(sprintf("[SITE:%s] fd_from_weighted_means failed: %s", s, e$message)); tibble::tibble(bin = numeric(0), value = numeric(0)) })
      message(sprintf("[SITE:%s] fd cols: %s", s, paste(names(fd_tbl), collapse = ", ")))

      # KDE
      kde_tbl <- tryCatch({
        if (nrow(df_s) > 0) {
          kde_from_weighted_means(
            df_s,
            from = min(cfg$calibration$time_range),
            to   = max(cfg$calibration$time_range)
          )
        } else {
          tibble::tibble(calBP = numeric(0), density = numeric(0))
        }
      }, error = function(e) { message(sprintf("[SITE:%s] kde_from_weighted_means failed: %s", s, e$message)); tibble::tibble(calBP = numeric(0), density = numeric(0)) })
      if (!all(c("calBP", "density") %in% names(kde_tbl))) {
        if (!"calBP" %in% names(kde_tbl) && length(kde_tbl) >= 1) kde_tbl$calBP <- kde_tbl[[1]]
        if (!"density" %in% names(kde_tbl) && length(kde_tbl) >= 2) kde_tbl$density <- kde_tbl[[2]]
        kde_tbl <- kde_tbl[, intersect(c("calBP", "density"), names(kde_tbl)), drop = FALSE]
      }
      message(sprintf("[SITE:%s] kde cols: %s", s, paste(names(kde_tbl), collapse = ", ")))

      p <- tryCatch(
        plot_methods_overlay(spd_tbl, fd_tbl, kde_tbl, smooth_fd = TRUE, smooth_window = 3),
        error = function(e) ggplot2::ggplot() + ggplot2::labs(title = paste("Plotting error for", s, "-", e$message))
      )
      try({ ggplot2::ggsave(out, p, width = 8, height = 5, dpi = 150) }, silent = TRUE)
      out
    },
    pattern = map(site_levels),
    iteration = "vector",
    format = "file",
    description = "Per-SITE SPD/FD/KDE overlay figures (dynamic)."
  ),

  # Selected site figures for report (subset based on config)
  targets::tar_target(
    selected_site_figs,
    filter_paths_by_cfg(
      as.character(unlist(fig_methods_by_site, use.names = FALSE)),
      include = cfg$report$site_figures$include,
      exclude = cfg$report$site_figures$exclude,
      limit   = cfg$report$site_figures$limit
    ),
    description = "Subset of per-SITE figure paths for report inclusion."
  ),

  # Montage of selected site figures (if magick available)
  targets::tar_target(
    fig_methods_by_site_montage,
    {
      import::from("fs", "path")
      fs::dir_create("figs")
      out <- path("figs", "methods_sites_montage.png")
      fps <- selected_site_figs
      ok <- FALSE
      if (length(fps) > 0 && requireNamespace("magick", quietly = TRUE)) {
        ok <- isTRUE(tryCatch({
          imgs <- magick::image_read(fps)
          ncol <- cfg$report$site_figures$ncol
          if (is.null(ncol) || is.na(ncol)) ncol <- 3L
          ncol <- max(1L, as.integer(ncol))
          montage <- magick::image_montage(imgs, tile = paste0(ncol, "x"))
          magick::image_write(montage, path = out, format = "png")
          file.exists(out)
        }, error = function(e) FALSE))
      }
      if (!ok) {
        gr <- ggplot2::ggplot() + ggplot2::labs(title = "Montage not created (no images or magick missing)")
        ggplot2::ggsave(out, gr, width = 8, height = 5, dpi = 150)
      }
      out
    },
    format = "file",
    description = "Montage image of selected per-SITE figures."
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
      # Inspect first grid column names before SPD
      grid_cols <- tryCatch({
        if (length(cds$grids) > 0) names(cds$grids[[1]]) else character(0)
      }, error = function(e) character(0))
      message(sprintf("[%s] first grid cols: %s", g, paste(grid_cols, collapse = ", ")))

      spd_tbl <- tryCatch({
        spd_obj <- spd_from_caldates(cds, time_range = cfg$calibration$time_range)
        spd_to_tibble(spd_obj)
      }, error = function(e) {
        message(sprintf("[%s] spd_to_tibble failed: %s", g, e$message))
        tibble::tibble(calBP = numeric(0), PrDens = numeric(0))
      })
      # Normalise SPD column names defensively
      if (!all(c("calBP", "PrDens") %in% names(spd_tbl))) {
        if (!"calBP" %in% names(spd_tbl) && length(spd_tbl) >= 1) spd_tbl$calBP <- spd_tbl[[1]]
        if (!"PrDens" %in% names(spd_tbl) && length(spd_tbl) >= 2) spd_tbl$PrDens <- spd_tbl[[2]]
        spd_tbl <- spd_tbl[, intersect(c("calBP", "PrDens"), names(spd_tbl)), drop = FALSE]
      }
      # Debugging: print column names to aid troubleshooting if plotting fails
      message(sprintf("[%s] spd cols: %s", g, paste(names(spd_tbl), collapse = ", ")))
      df_g <- weighted_means[weighted_means$SITE_TYPE == g, , drop = FALSE]
      fd_tbl <- tryCatch({
        if (nrow(df_g) > 0) {
          fd_from_weighted_means(
            df_g,
            min_age = min(cfg$calibration$time_range),
            max_age = max(cfg$calibration$time_range)
          )
        } else {
          tibble::tibble(bin = numeric(0), value = numeric(0))
        }
      }, error = function(e) {
        message(sprintf("[%s] fd_from_weighted_means failed: %s", g, e$message))
        tibble::tibble(bin = numeric(0), value = numeric(0))
      })
      message(sprintf("[%s] fd cols: %s", g, paste(names(fd_tbl), collapse = ", ")))
      kde_tbl <- tryCatch({
        if (nrow(df_g) > 0) {
          kde_from_weighted_means(
            df_g,
            from = min(cfg$calibration$time_range),
            to   = max(cfg$calibration$time_range)
          )
        } else {
          tibble::tibble(calBP = numeric(0), density = numeric(0))
        }
      }, error = function(e) {
        message(sprintf("[%s] kde_from_weighted_means failed: %s", g, e$message))
        tibble::tibble(calBP = numeric(0), density = numeric(0))
      })
      # Normalise KDE column names defensively
      if (!all(c("calBP", "density") %in% names(kde_tbl))) {
        if (!"calBP" %in% names(kde_tbl) && length(kde_tbl) >= 1) kde_tbl$calBP <- kde_tbl[[1]]
        if (!"density" %in% names(kde_tbl) && length(kde_tbl) >= 2) kde_tbl$density <- kde_tbl[[2]]
        kde_tbl <- kde_tbl[, intersect(c("calBP", "density"), names(kde_tbl)), drop = FALSE]
      }
      message(sprintf("[%s] kde cols: %s", g, paste(names(kde_tbl), collapse = ", ")))
      p <- tryCatch(
        plot_methods_overlay(spd_tbl, fd_tbl, kde_tbl, smooth_fd = TRUE, smooth_window = 3),
        error = function(e) ggplot2::ggplot() + ggplot2::labs(title = paste("Plotting error for", g, "-", e$message))
      )
      ok <- tryCatch({
        ggplot2::ggsave(out, p, width = 8, height = 5, dpi = 150)
        TRUE
      }, error = function(e) {
        message(sprintf("[%s] ggsave failed: %s", g, e$message))
        ggplot2::ggsave(out, ggplot2::ggplot() + ggplot2::labs(title = paste("Placeholder for", g, "-", e$message)), width = 8, height = 5, dpi = 150)
        FALSE
      })
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
    calibrate_and_spd(
      validated_strict,
      time_range = cfg$calibration$time_range,
      terrestrial_curve = cfg$calibration$terrestrial_curve,
      marine_curve = cfg$calibration$marine_curve
    ),
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
    fd_from_weighted_means(
      weighted_means,
      bin_width = 100,
      min_age = min(cfg$calibration$time_range),
      max_age = max(cfg$calibration$time_range)
    ),
    description = "Frequency distribution from weighted mean calibrated ages."
  ),
  targets::tar_target(
    kde_summary,
    kde_from_weighted_means(
      weighted_means,
      from = min(cfg$calibration$time_range),
      to   = max(cfg$calibration$time_range),
      bw = 100, n = 512
    ),
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
