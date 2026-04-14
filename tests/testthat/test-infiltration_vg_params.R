library(tibble)

test_that("lookup returns correct columns for known texture+suction", {
  df <- tibble(texture = "sandy loam", suction = 4)
  result <- infiltration_vg_params(df, texture = texture, suction = suction)
  expect_true(all(c(".n", ".alpha", ".A") %in% names(result)))
  expect_equal(result$.n,     1.89, tolerance = 1e-6)
  expect_equal(result$.alpha, 0.075, tolerance = 1e-6)
  expect_gt(result$.A, 0)
})

test_that("character suction like '2cm' is parsed correctly", {
  df <- tibble(texture = "loam", suction = "2cm")
  result <- infiltration_vg_params(df, texture = texture, suction = suction)
  ref    <- infiltration_vg_params(
    tibble(texture = "loam", suction = 2), texture = texture, suction = suction
  )
  expect_equal(result$.A, ref$.A)
})

test_that("scalar suction is recycled: both rows use suction = 2", {
  df <- tibble(texture = c("sand", "loam"), suction_col = c(2, 4))
  r_scalar <- infiltration_vg_params(df, texture = texture, suction = 2)
  # Scalar suction = 2 → .A for "loam" should match loam at suction 2
  loam_at_2 <- minidisk_vg_params[minidisk_vg_params$texture == "loam" &
                                    minidisk_vg_params$suction_cm == 2, "A", drop = TRUE]
  expect_equal(r_scalar$.A[[2]], loam_at_2)
  # .A for "sand" should match sand at suction 2 (not suction 4)
  sand_at_2 <- minidisk_vg_params[minidisk_vg_params$texture == "sand" &
                                    minidisk_vg_params$suction_cm == 2, "A", drop = TRUE]
  expect_equal(r_scalar$.A[[1]], sand_at_2)
})

test_that("suction = 0 returns n and alpha but NA for A", {
  df <- tibble(texture = "sandy loam", theta_s = 0.4)
  result <- infiltration_vg_params(df, texture = texture, suction = 0)
  expect_false(is.na(result$.n))
  expect_false(is.na(result$.alpha))
  expect_true(is.na(result$.A))
})

test_that("unknown texture class gives informative error", {
  df <- tibble(texture = "gravel", suction = 2)
  expect_error(
    infiltration_vg_params(df, texture = texture, suction = suction),
    regexp = "Unknown texture class"
  )
})

test_that("suction not in table gives informative error", {
  df <- tibble(texture = "loam", suction = 10)
  expect_error(
    infiltration_vg_params(df, texture = texture, suction = suction),
    regexp = "not found in lookup table"
  )
})
