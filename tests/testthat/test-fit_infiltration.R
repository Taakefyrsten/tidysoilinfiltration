library(tibble)
library(dplyr)

make_philip_data <- function() {
  tibble(
    time   = seq(0, 300, 30),
    volume = c(95, 89, 86, 83, 80, 77, 74, 73, 71, 69, 67)
  ) |>
    infiltration_cumulative(time = time, volume = volume)
}

test_that("output is a tibble with C1, C2, and convergence columns", {
  result <- fit_infiltration(make_philip_data(),
                             infiltration_col = .infiltration,
                             sqrt_time_col    = .sqrt_time)
  expect_s3_class(result, "tbl_df")
  expect_true(all(c(".C1", ".C2", ".C1_std_error", ".C2_std_error",
                    ".convergence") %in% names(result)))
})

test_that("convergence is TRUE for clean data", {
  result <- fit_infiltration(make_philip_data(),
                             infiltration_col = .infiltration,
                             sqrt_time_col    = .sqrt_time)
  expect_true(result$.convergence)
})

test_that("C1 is positive for infiltrating data", {
  result <- fit_infiltration(make_philip_data(),
                             infiltration_col = .infiltration,
                             sqrt_time_col    = .sqrt_time)
  expect_gt(result$.C1, 0)
})

test_that("grouped fit returns one row per group", {
  multi <- tibble(
    sample = rep(c("A", "B"), each = 11),
    time   = rep(seq(0, 300, 30), 2),
    volume = c(95, 89, 86, 83, 80, 77, 74, 73, 71, 69, 67,
               83, 77, 64, 61, 58, 45, 42, 35, 29, 17, 15)
  ) |>
    group_by(sample) |>
    infiltration_cumulative(time = time, volume = volume)

  result <- multi |>
    group_by(sample) |>
    fit_infiltration(infiltration_col = .infiltration, sqrt_time_col = .sqrt_time)

  expect_equal(nrow(result), 2L)
  expect_true("sample" %in% names(result))
  expect_true(all(result$.convergence))
})

test_that("missing column gives informative error", {
  expect_error(
    fit_infiltration(make_philip_data(),
                     infiltration_col = bad_col,
                     sqrt_time_col    = .sqrt_time),
    regexp = "not found"
  )
})
