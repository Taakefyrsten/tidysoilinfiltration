library(tibble)
library(dplyr)

make_beerkan <- function() {
  tibble(
    volume = 100,
    time   = c(12, 18, 24, 30, 34, 35, 35, 36)
  )
}

test_that("output is a tibble with four appended columns", {
  result <- beerkan_cumulative(make_beerkan(), volume_col = volume, time_col = time, radius = 5)
  expect_s3_class(result, "tbl_df")
  expect_true(all(c(".cumulative_time", ".sqrt_time", ".cumulative_volume",
                    ".infiltration") %in% names(result)))
})

test_that("cumulative_time is strictly increasing", {
  result <- beerkan_cumulative(make_beerkan(), volume_col = volume, time_col = time, radius = 5)
  expect_true(all(diff(result$.cumulative_time) > 0))
})

test_that("sqrt_time equals sqrt of cumulative_time", {
  result <- beerkan_cumulative(make_beerkan(), volume_col = volume, time_col = time, radius = 5)
  expect_equal(result$.sqrt_time, sqrt(result$.cumulative_time))
})

test_that("cumulative_volume equals n * volume for fixed-volume pours", {
  result <- beerkan_cumulative(make_beerkan(), volume_col = volume, time_col = time, radius = 5)
  expect_equal(result$.cumulative_volume, seq(100, 800, 100))
})

test_that("infiltration scales correctly with radius", {
  r5  <- beerkan_cumulative(make_beerkan(), volume_col = volume, time_col = time, radius = 5)
  r10 <- beerkan_cumulative(make_beerkan(), volume_col = volume, time_col = time, radius = 10)
  expect_equal(r5$.infiltration * 5^2, r10$.infiltration * 10^2)
})

test_that("grouped data accumulates independently per group", {
  runs <- tibble(
    site   = rep(c("S1", "S2"), each = 4),
    volume = 100,
    time   = c(10, 15, 18, 20, 30, 40, 45, 46)
  )
  result <- runs |>
    group_by(site) |>
    beerkan_cumulative(volume_col = volume, time_col = time, radius = 5)
  max_times <- result |> group_by(site) |> summarise(max_t = max(.cumulative_time))
  expect_equal(max_times$max_t[1], 10 + 15 + 18 + 20)
  expect_equal(max_times$max_t[2], 30 + 40 + 45 + 46)
})

test_that("missing radius argument gives informative error", {
  expect_error(
    beerkan_cumulative(make_beerkan(), volume_col = volume, time_col = time),
    regexp = "required"
  )
})
