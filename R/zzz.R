## Deprecated package-like load hooks (no-op)
##
## This compendium avoids global side effects. Reproducibility and options are
## handled within the pipeline (_targets.R) and tests. This file remains only to
## prevent accidental side effects during interactive work.

.onLoad <- function(libname, pkgname) { invisible(TRUE) }
