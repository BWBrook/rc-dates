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
      spd_tbl <- spd_to_tibble(spd_from_caldates(cds, time_range = cfg$calibration$time_range))

      # FD
      df_s <- weighted_means[weighted_means$SITE == s, , drop = FALSE]
      fd_tbl <- if (nrow(df_s) > 0) {
        fd_from_weighted_means(
          df_s,
          min_age = min(cfg$calibration$time_range),
          max_age = max(cfg$calibration$time_range)
        )
      } else {
        tibble::tibble(bin = numeric(0), value = numeric(0))
      }

      # KDE
      kde_tbl <- if (nrow(df_s) > 0) {
        kde_from_weighted_means(
          df_s,
          from = min(cfg$calibration$time_range),
          to   = max(cfg$calibration$time_range)
        )
      } else {
        tibble::tibble(calBP = numeric(0), density = numeric(0))
      }

      p <- plot_methods_overlay(spd_tbl, fd_tbl, kde_tbl, smooth_fd = TRUE, smooth_window = 3)
      ggplot2::ggsave(out, p, width = 8, height = 5, dpi = 150)
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

      spd_tbl <- spd_to_tibble(spd_from_caldates(cds, time_range = cfg$calibration$time_range))
      df_g <- weighted_means[weighted_means$SITE_TYPE == g, , drop = FALSE]
      fd_tbl <- if (nrow(df_g) > 0) {
        fd_from_weighted_means(
          df_g,
          min_age = min(cfg$calibration$time_range),
          max_age = max(cfg$calibration$time_range)
        )
      } else {
        tibble::tibble(bin = numeric(0), value = numeric(0))
      }
      kde_tbl <- if (nrow(df_g) > 0) {
        kde_from_weighted_means(
          df_g,
          from = min(cfg$calibration$time_range),
          to   = max(cfg$calibration$time_range)
        )
      } else {
        tibble::tibble(calBP = numeric(0), density = numeric(0))
      }
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

  # Simulations: demo generation, precomputed ingestion, or none
  targets::tar_target(
    sim_mode,
    normalize_simulation_mode(cfg$simulate$mode),
    description = "Configured simulation mode."
  ),
  targets::tar_target(
    demo_sim_specs,
    if (identical(sim_mode, "demo")) build_demo_sim_specs(cfg) else tibble::tibble(),
    description = "Scenario matrix for generated demo simulation summaries."
  ),
  targets::tar_target(
    demo_sim_summary_files,
    if (identical(sim_mode, "demo")) {
      write_demo_simulation_summaries(validated_strict, cfg, demo_sim_specs)
    } else {
      character(0)
    },
    format = "file",
    description = "Generated demo simulation summary CSV files."
  ),
  targets::tar_target(
    sim_precomputed_manifest,
    if (identical(sim_mode, "precomputed")) {
      read_sim_manifest(
        cfg$simulate$precomputed$dir,
        cfg$simulate$precomputed$pattern,
        origin = "precomputed"
      )
    } else {
      empty_sim_manifest()
    },
    description = "Manifest of externally supplied simulation summary CSV files."
  ),
  targets::tar_target(
    sim_manifest,
    if (identical(sim_mode, "demo")) {
      build_sim_manifest_from_paths(demo_sim_summary_files, origin = "demo")
    } else if (identical(sim_mode, "precomputed")) {
      sim_precomputed_manifest
    } else {
      empty_sim_manifest()
    },
    description = "Unified manifest of simulation summary CSV files."
  ),
  targets::tar_target(
    sim_paths,
    sim_manifest$path,
    description = "Vector of simulation summary file paths (non-file target for branching)."
  ),
  targets::tar_target(
    sim_files,
    sim_manifest$path,
    format = "file",
    description = "Simulation summary files (tracked as file targets)."
  ),
  targets::tar_target(
    sim_tables,
    {
      sim_files
      lapply(sim_paths, read_sim_table)
    },
    iteration = "list",
    description = "Per-file tidy simulation tables."
  ),
  targets::tar_target(
    sim_all,
    {
      import::from("dplyr", "bind_rows")
      if (length(sim_tables) == 0) tibble::tibble() else bind_rows(sim_tables)
    },
    description = "All simulations bound into one tibble."
  ),
  targets::tar_target(
    sim_scenarios,
    {
      if (!("scenario" %in% names(sim_all)) || nrow(sim_all) == 0) {
        character(0)
      } else {
        sort(unique(sim_all$scenario))
      }
    },
    description = "Distinct simulation scenarios."
  ),
  targets::tar_target(
    fig_sim_overlays,
    {
      fs::dir_create("figs")
      if (nrow(sim_manifest) == 0) {
        return(character(0))
      }

      vapply(
        seq_len(nrow(sim_manifest)),
        function(i) {
          s <- sim_manifest$scenario[[i]]
          sz <- sim_manifest$size[[i]]
          df <- sim_all[sim_all$scenario == s & sim_all$size == sz, , drop = FALSE]
          out <- fs::path("figs", paste0("sim_", gsub("[^A-Za-z0-9_]+", "_", s), "_", sz, ".png"))
          if (nrow(df) == 0) {
            ggplot2::ggsave(out, ggplot2::ggplot() + ggplot2::labs(title = paste("No sim data for", s, sz)), width = 8, height = 5, dpi = 150)
          } else {
            p <- plot_sim_overlay(df)
            p <- p + ggplot2::labs(title = paste0(tools::toTitleCase(gsub("_", " ", s)), " (", sz, "% sites)"))
            ggplot2::ggsave(out, p, width = 8, height = 5, dpi = 150)
          }
          out
        },
        character(1)
      )
    },
    format = "file",
    description = "Per-scenario simulation overlay figures."
  ),
  targets::tar_target(
    fig_sim_montage,
    {
      import::from("fs", "path")
      fs::dir_create("figs")
      out <- path("figs", "simulations_montage.png")
      fps <- as.character(unlist(fig_sim_overlays, use.names = FALSE))
      ok <- FALSE
      if (length(fps) > 0 && requireNamespace("magick", quietly = TRUE)) {
        ok <- isTRUE(tryCatch({
          imgs <- magick::image_read(fps)
          montage <- magick::image_montage(imgs, tile = paste0(3, "x"))
          magick::image_write(montage, path = out, format = "png")
          file.exists(out)
        }, error = function(e) FALSE))
      }
      if (!ok) {
        ggplot2::ggsave(out, ggplot2::ggplot() + ggplot2::labs(title = "No simulation figures to montage"), width = 8, height = 5, dpi = 150)
      }
      out
    },
    format = "file",
    description = "Montage of simulation overlays."
  ),
  targets::tar_target(
    report_qmd,
    "reports/paper.qmd",
    format = "file",
    description = "Quarto report source file."
  ),
  targets::tar_target(
    report_quarto_yml,
    "quarto.yml",
    format = "file",
    description = "Project-level Quarto configuration file."
  ),

  # Report rendering: render to same directory as source file
  targets::tar_target(
    report,
    {
      list(
        cfg, validated_strict, spd_summary, fd_summary, kde_summary,
        fig_methods_overall, fig_methods_by_site_type, selected_site_figs,
        fig_methods_by_site_montage, sim_manifest, fig_sim_overlays, fig_sim_montage
      )
      qmd <- report_qmd
      report_quarto_yml
      out_dir <- dirname(qmd)
      # Render with Quarto if available; otherwise write a simple placeholder HTML
      has_quarto <- requireNamespace("quarto", quietly = TRUE) && !is.na(tryCatch(quarto::quarto_path(), error = function(e) NA))
      base <- tools::file_path_sans_ext(basename(qmd))
      html <- file.path(out_dir, paste0(base, ".html"))
      if (has_quarto) {
        quarto::quarto_render(input = qmd, quiet = TRUE)
        if (!file.exists(html)) {
          stop(sprintf("Quarto render did not produce expected output: %s", html))
        }
      } else {
        writeLines("<html><body><p>Report placeholder (Quarto not available or render failed).</p></body></html>", html)
      }
      html
    },
    format = "file",
    description = "Rendered Quarto report artifact."
  )
)
