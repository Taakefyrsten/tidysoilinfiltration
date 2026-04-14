library(tibble)
library(dplyr)

make_minidisk <- function() {
  tibble(
    time   = seq(0, 300, 30),
    volume = c(95, 89, 86, 83, 80, 77, 74, 73, 71, 69, 67)
  )
}

test_that("output is a tibble with three appended columns", {
  result <- infiltration_cumulative(make_minidisk(), time = time, volume = volume)
  expect_s3_class(result, "tbl_df")
  expect_true(all(c(".sqrt_time", ".volume_infiltrated", ".infiltration") %in% names(result)))
})

test_that("infiltration is zero at t = 0", {
  result <- infiltration_cumulative(make_minidisk(), time = time, volume = volume)
  expect_equal(result$.infiltration[1], 0)
})

test_that("infiltration is non-decreasing", {
  result <- infiltration_cumulative(make_minidisk(), time = time, volume = volume)
  expect_true(all(diff(result$.infiltration) >= 0))
})

test_that(".sqrt_time equals sqrt of time column", {
  result <- infiltration_cumulative(make_minidisk(), time = time, volume = volume)
  expect_equal(result$.sqrt_time, sqrt(seq(0, 300, 30)))
})

test_that("radius argument scales infiltration correctly", {
  r1 <- infiltration_cumulative(make_minidisk(), time = time, volume = volume, radius = 2.25)
  r2 <- infiltration_cumulative(make_minidisk(), time = time, volume = volume, radius = 4.5)
  # radius doubled -> area quadrupled -> infiltration quartered
  expect_equal(r1$.infiltration * (2.25^2), r2$.infiltration * (4.5^2))
})

test_that("grouped data uses per-group initial volume", {
  multi <- tibble(
    sample = rep(c("A", "B"), each = 11),
    time   = rep(seq(0, 300, 30), 2),
    volume = c(95, 89, 86, 83, 80, 77, 74, 73, 71, 69, 67,
               83, 77, 64, 61, 58, 45, 42, 35, 29, 17, 15)
  )
  result <- multi |>
    group_by(sample) |>
    infiltration_cumulative(time = time, volume = volume)
  zero_rows <- result |> filter(time == 0)
  expect_equal(zero_rows$.infiltration, c(0, 0))
})

test_that("missing time column gives informative error", {
  expect_error(
    infiltration_cumulative(make_minidisk(), time = bad_col, volume = volume),
    regexp = "not found"
  )
})

test_that("non-positive radius gives error", {
  expect_error(
    infiltration_cumulative(make_minidisk(), time = time, volume = volume, radius = -1),
    regexp = "strictly positive"
  )
})
