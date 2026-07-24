find_archive_script <- function() {
  candidates <- c(
    "scripts/create_review_package_archive.sh",
    "../../scripts/create_review_package_archive.sh"
  )
  existing <- candidates[file.exists(candidates)]
  if (length(existing) == 0L) return(candidates[[1L]])
  normalizePath(existing[[1L]], winslash = "/", mustWork = TRUE)
}

test_that("review-package archive replacement removes stale entries", {
  skip_if(Sys.which("bash") == "")
  skip_if(Sys.which("zip") == "")
  skip_if(Sys.which("unzip") == "")

  root <- tempfile("review-archive-")
  package <- file.path(root, "rc_review_package")
  archive <- file.path(root, "rc_review_package.zip")
  dir.create(package, recursive = TRUE)
  writeLines("retain", file.path(package, "retain.txt"))
  writeLines("remove", file.path(package, "obsolete-identifying-file.txt"))

  script <- find_archive_script()
  skip_if_not(file.exists(script), "archive builder is not distributed in review package")
  first <- system2("bash", c(shQuote(script), shQuote(package), shQuote(archive)))
  expect_identical(first, 0L)

  unlink(file.path(package, "obsolete-identifying-file.txt"))
  writeLines("updated", file.path(package, "retain.txt"))
  second <- system2("bash", c(shQuote(script), shQuote(package), shQuote(archive)))
  expect_identical(second, 0L)

  entries <- system2("unzip", c("-Z1", shQuote(archive)), stdout = TRUE)
  expect_true("rc_review_package/retain.txt" %in% entries)
  expect_false(any(grepl("obsolete-identifying-file", entries, fixed = TRUE)))
})
