library(tibble)
library(dplyr)

# Raw Minidisk readings (no metadata columns — they are lost after fit_infiltration())
make_minidisk_raw <- function() {
  tibble(
    time   = seq(0, 300, 30),
    volume = c(95, 89, 86, 83, 80, 77, 74, 73, 71, 69, 67)
  )
}

make_multi_raw <- function() {
  tibble(
    sample = rep(c("A", "B"), each = 11),
    time   = rep(seq(0, 300, 30), 2),
    volume = c(95, 89, 86, 83, 80, 77, 74, 73, 71, 69, 67,
               83, 77, 74, 71, 68, 65, 62, 59, 57, 55, 53)
  )
}

make_multi_meta <- function() {
  tibble(
    sample  = c("A", "B"),
    texture = c("sandy loam", "loam"),
    suction = 2
  )
}

# ── minidisk_conductivity() ────────────────────────────────────────────────────

test_that("minidisk_conductivity returns .K_h, .n, .alpha, .A", {
  result <- make_minidisk_raw() |>
    infiltration_cumulative(time, volume) |>
    fit_infiltration(.infiltration, .sqrt_time) |>
    minidisk_conductivity(texture = "sandy loam", suction = 2)

  expect_true(all(c(".K_h", ".n", ".alpha", ".A") %in% names(result)))
})

test_that("minidisk_conductivity .K_h is positive", {
  result <- make_minidisk_raw() |>
    infiltration_cumulative(time, volume) |>
    fit_infiltration(.infiltration, .sqrt_time) |>
    minidisk_conductivity(texture = "sandy loam", suction = 2)

  expect_true(result$.K_h > 0)
})

test_that("method = 'zhang' gives positive .A and .K_h, different from tabulated", {
  fitted <- make_minidisk_raw() |>
    infiltration_cumulative(time, volume) |>
    fit_infiltration(.infiltration, .sqrt_time)

  tab  <- minidisk_conductivity(fitted, texture = "sandy loam", suction = 2, method = "tabulated")
  zhan <- minidisk_conductivity(fitted, texture = "sandy loam", suction = 2, method = "zhang")

  expect_true(zhan$.A > 0)
  expect_true(zhan$.K_h > 0)
  expect_false(isTRUE(all.equal(tab$.A, zhan$.A)))
})

test_that("multi-sample pipeline requires only one group_by (via left_join for metadata)", {
  result <- make_multi_raw() |>
    group_by(sample) |>
    infiltration_cumulative(time, volume) |>
    fit_infiltration(.infiltration, .sqrt_time) |>
    left_join(make_multi_meta(), by = "sample") |>
    minidisk_conductivity(texture = texture, suction = suction)

  expect_equal(nrow(result), 2L)
  expect_setequal(result$sample, c("A", "B"))
  expect_true(all(result$.K_h > 0))
})

test_that("column-based texture and suction arguments work", {
  # Simulate data that already has texture/suction columns (e.g. after left_join)
  fitted <- make_minidisk_raw() |>
    infiltration_cumulative(time, volume) |>
    fit_infiltration(.infiltration, .sqrt_time) |>
    mutate(texture = "sandy loam", suction = 2)

  result <- minidisk_conductivity(fitted, texture = texture, suction = suction)

  expect_true(".K_h" %in% names(result))
  expect_true(result$.K_h > 0)
})

# ── Grouping preservation tests ────────────────────────────────────────────────

test_that("infiltration_cumulative preserves group_by grouping", {
  result <- make_multi_raw() |>
    group_by(sample) |>
    infiltration_cumulative(time, volume)

  expect_true(dplyr::is_grouped_df(result))
  expect_equal(dplyr::group_vars(result), "sample")
})

test_that("infiltration_rate preserves group_by grouping", {
  result <- make_multi_raw() |>
    group_by(sample) |>
    infiltration_cumulative(time, volume) |>
    infiltration_rate(time_col = time, infiltration_col = .infiltration)

  expect_true(dplyr::is_grouped_df(result))
  expect_equal(dplyr::group_vars(result), "sample")
})

test_that("ungrouped input to infiltration_cumulative returns plain tibble", {
  result <- make_minidisk_raw() |>
    infiltration_cumulative(time, volume)

  expect_false(dplyr::is_grouped_df(result))
  expect_s3_class(result, "tbl_df")
})

test_that("ungrouped input to infiltration_rate returns plain tibble", {
  result <- make_minidisk_raw() |>
    infiltration_cumulative(time, volume) |>
    infiltration_rate(time_col = time, infiltration_col = .infiltration)

  expect_false(dplyr::is_grouped_df(result))
  expect_s3_class(result, "tbl_df")
})
