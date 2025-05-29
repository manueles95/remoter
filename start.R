#!/usr/bin/env Rscript
library(plumber)
message("Starting plumber API...")
api <- plumb("/app/R/plumber.R")
message("Plumber loaded successfully, starting server...")
api$run(host = "0.0.0.0", port = 8000)