## Build minidisk_vg_params ------------------------------------------------
## Source: Decagon Devices, Inc. (2005) via infiltrodiscR package
## Run once with: source("data-raw/minidisk_vg_params.R")

library(dplyr)
library(tidyr)

if (!requireNamespace("infiltrodiscR", quietly = TRUE)) {
  install.packages("infiltrodiscR")
}

data("vg_parameters_bytexture", package = "infiltrodiscR")

minidisk_vg_params <- vg_parameters_bytexture |>
  tidyr::pivot_longer(
    cols      = `0.5cm`:`7cm`,
    names_to  = "suction_cm",
    values_to = "A"
  ) |>
  dplyr::mutate(
    suction_cm = as.numeric(gsub("cm", "", suction_cm))
  ) |>
  dplyr::rename(n = n_ho) |>
  dplyr::select(texture, suction_cm, n, alpha, A)

usethis::use_data(minidisk_vg_params, overwrite = TRUE, compress = "bzip2")
