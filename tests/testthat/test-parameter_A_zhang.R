library(tibble)

test_that("appends .A column and output is tibble", {
  df     <- tibble(n = 1.89, alpha = 0.075, suction = 4)
  result <- parameter_A_zhang(df, n = n, alpha = alpha, suction = suction)
  expect_s3_class(result, "tbl_df")
  expect_true(".A" %in% names(result))
})

test_that("A matches tabulated value for sandy loam at 4 cm (within 5%)", {
  # Table value: 3.954 (from minidisk_vg_params)
  df     <- tibble(n = 1.89, alpha = 0.075, suction = 4)
  result <- parameter_A_zhang(df, n = n, alpha = alpha, suction = suction)
  expect_equal(result$.A, 3.954, tolerance = 0.05)
})

test_that("negative suction is treated as positive (absolute value)", {
  df_pos <- tibble(n = 1.56, alpha = 0.036, suction = 2)
  df_neg <- tibble(n = 1.56, alpha = 0.036, suction = -2)
  r_pos  <- parameter_A_zhang(df_pos, n = n, alpha = alpha, suction = suction)
  r_neg  <- parameter_A_zhang(df_neg, n = n, alpha = alpha, suction = suction)
  expect_equal(r_pos$.A, r_neg$.A)
})

test_that("scalar and column arguments give same result", {
  df <- tibble(n = 1.56, alpha = 0.036, suction = 2)
  r_col    <- parameter_A_zhang(df, n = n, alpha = alpha, suction = suction)
  r_scalar <- parameter_A_zhang(df, n = 1.56, alpha = 0.036, suction = 2)
  expect_equal(r_col$.A, r_scalar$.A)
})

test_that("n <= 1 gives error", {
  df <- tibble(n = 0.9, alpha = 0.036, suction = 2)
  expect_error(
    parameter_A_zhang(df, n = n, alpha = alpha, suction = suction),
    regexp = "greater than 1"
  )
})

test_that("non-positive radius gives error", {
  df <- tibble(n = 1.56, alpha = 0.036, suction = 2)
  expect_error(
    parameter_A_zhang(df, n = n, alpha = alpha, suction = suction, radius = 0),
    regexp = "strictly positive"
  )
})
