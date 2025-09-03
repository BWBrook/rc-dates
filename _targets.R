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

  # Model fit / SPD summary (fast by default on toy dataset)
  targets::tar_target(
    model_fit,
    calibrate_and_spd(validated_strict, time_range = c(100L, 20000L)),
    description = "Calibrated dates and SPD summary object."
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
