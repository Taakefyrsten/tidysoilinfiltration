library(tibble)
library(dplyr)

make_beerkan_run <- function() {
  tibble(
    volume = 100,
    time   = c(15, 22, 30, 38, 44, 48, 50, 51, 51, 52)
  ) |>
    beerkan_cumulative(volume_col = volume, time_col = time, radius = 5)
}

test_that("output columns are present for a single run", {
  result <- fit_best(make_beerkan_run(),
                     infiltration_col = .infiltration,
                     time_col         = .cumulative_time,
                     theta_s = 0.45, theta_i = 0.12, n = 1.56)
  expect_true(all(c(".Ks", ".S", ".alpha", ".Ks_std_error",
                    ".S_std_error", ".steady_n", ".convergence") %in% names(result)))
})

test_that("convergence is TRUE and estimates are positive for clean data", {
  result <- fit_best(make_beerkan_run(),
                     infiltration_col = .infiltration,
                     time_col         = .cumulative_time,
                     theta_s = 0.45, theta_i = 0.12, n = 1.56)
  expect_true(result$.convergence)
  expect_gt(result$.Ks,    0)
  expect_gt(result$.S,     0)
  expect_gt(result$.alpha, 0)
})

test_that("grouped fit returns one row per group", {
  runs <- tibble(
    site   = rep(c("S1", "S2"), each = 10),
    volume = 100,
    time   = c(15, 22, 30, 38, 44, 48, 50, 51, 51, 52,
               25, 35, 45, 55, 62, 67, 70, 71, 72, 72)
  ) |>
    group_by(site) |>
    beerkan_cumulative(volume_col = volume, time_col = time, radius = 5)

  result <- runs |>
    group_by(site) |>
    fit_best(infiltration_col = .infiltration, time_col = .cumulative_time,
             theta_s = 0.45, theta_i = 0.12, n = 1.56)

  expect_equal(nrow(result), 2L)
  expect_true("site" %in% names(result))
})

test_that("theta_i >= theta_s gives error", {
  expect_error(
    fit_best(make_beerkan_run(),
             infiltration_col = .infiltration,
             time_col         = .cumulative_time,
             theta_s = 0.12, theta_i = 0.45, n = 1.56),
    regexp = "theta_s.*must be greater"
  )
})

test_that("n <= 1 gives error", {
  expect_error(
    fit_best(make_beerkan_run(),
             infiltration_col = .infiltration,
             time_col         = .cumulative_time,
             theta_s = 0.45, theta_i = 0.12, n = 0.9),
    regexp = "greater than 1"
  )
})

test_that("method = 'slope' and 'steady' both return positive Ks", {
  run <- make_beerkan_run()
  r_steady <- fit_best(run, infiltration_col = .infiltration,
                       time_col = .cumulative_time,
                       theta_s = 0.45, theta_i = 0.12, n = 1.56, method = "steady")
  r_slope  <- fit_best(run, infiltration_col = .infiltration,
                       time_col = .cumulative_time,
                       theta_s = 0.45, theta_i = 0.12, n = 1.56, method = "slope")
  expect_gt(r_steady$.Ks, 0)
  expect_gt(r_slope$.Ks,  0)
})

test_that("steady_n argument controls number of points used", {
  run <- make_beerkan_run()
  r4  <- fit_best(run, infiltration_col = .infiltration,
                  time_col = .cumulative_time,
                  theta_s = 0.45, theta_i = 0.12, n = 1.56, steady_n = 4)
  r6  <- fit_best(run, infiltration_col = .infiltration,
                  time_col = .cumulative_time,
                  theta_s = 0.45, theta_i = 0.12, n = 1.56, steady_n = 6)
  expect_equal(r4$.steady_n, 4L)
  expect_equal(r6$.steady_n, 6L)
})
