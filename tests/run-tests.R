# Run the focused scientific tests in this non-package repository.

source("tests/testthat/helper-setup.R")
testthat::test_dir("tests/testthat", reporter = "summary")
