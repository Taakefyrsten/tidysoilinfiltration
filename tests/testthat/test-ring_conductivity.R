library(tibble)
library(dplyr)

# Data generated from Horton model: I(t) = fc*t + (f0-fc)/k*(1-exp(-k*t)),
# V(t) = 500 - I(t)*pi*r^2 with r=10 cm. Exact parameter recovery expected.
# Site A: fc=2e-4, f0=1e-3, k=1e-3
# Site B: fc=1.5e-4, f0=5e-4, k=8e-4
make_ring <- function() {
  tibble(
    time   = seq(0, 3600, 360),
    volume = c(500.0, 401.4, 325.8, 266.2, 217.7, 177.1,
               141.9, 110.6,  81.8,  54.9,  29.3)
  )
}

make_multi_ring <- function() {
  tibble(
    site   = rep(c("A", "B"), each = 11),
    time   = rep(seq(0, 3600, 360), 2),
    volume = c(
      500.0, 401.4, 325.8, 266.2, 217.7, 177.1, 141.9, 110.6,  81.8,  54.9,  29.3,
      500.0, 448.6, 405.9, 369.6, 338.1, 310.3, 285.2, 262.1, 240.6, 220.2, 200.6
    )
  )
}

test_that("ring_conductivity returns Horton parameter columns", {
  result <- ring_conductivity(make_ring(), time = time, volume = volume, radius = 10)
  expect_true(all(c(".fc", ".f0", ".k", ".convergence") %in% names(result)))
})

test_that("ring_conductivity .fc is positive when model converges", {
  result <- ring_conductivity(make_ring(), time = time, volume = volume, radius = 10)
  expect_true(result$.convergence)
  expect_true(result$.fc > 0)
})

test_that("ring_conductivity .fc < .f0 (rate decays toward steady state)", {
  result <- ring_conductivity(make_ring(), time = time, volume = volume, radius = 10)
  expect_true(result$.fc < result$.f0)
})

test_that("grouped ring_conductivity returns one row per group", {
  result <- make_multi_ring() |>
    group_by(site) |>
    ring_conductivity(time = time, volume = volume, radius = 10)

  expect_equal(nrow(result), 2L)
  expect_setequal(result$site, c("A", "B"))
  expect_true(all(result$.convergence))
  expect_true(all(result$.fc > 0))
})

test_that("ring_conductivity result matches step-by-step pipeline", {
  # Wrapper should be exactly equivalent to calling the three functions manually
  step_by_step <- make_ring() |>
    infiltration_cumulative(time = time, volume = volume, radius = 10) |>
    infiltration_rate(time_col = time, infiltration_col = .infiltration) |>
    fit_infiltration_horton(rate_col = .rate, time_col = .time_mid)

  wrapper <- ring_conductivity(make_ring(), time = time, volume = volume, radius = 10)

  expect_equal(wrapper$.fc, step_by_step$.fc, tolerance = 1e-10)
  expect_equal(wrapper$.f0, step_by_step$.f0, tolerance = 1e-10)
  expect_equal(wrapper$.k,  step_by_step$.k,  tolerance = 1e-10)
})

test_that("non-positive radius gives an error", {
  expect_error(
    ring_conductivity(make_ring(), time = time, volume = volume, radius = 0),
    regexp = "strictly positive"
  )
})
