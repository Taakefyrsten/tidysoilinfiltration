# Internal utilities for tidysoilinfiltration

# Resolve a quosure to either a column vector (if it names a column in `data`)
# or a scalar numeric value (if it evaluates to a number).
resolve_arg <- function(quo, data, arg_name) {
  expr <- rlang::get_expr(quo)
  env  <- rlang::get_env(quo)

  if (rlang::is_symbol(expr)) {
    nm <- rlang::as_string(expr)
    if (nm %in% names(data)) {
      return(data[[nm]])
    }
  }

  val <- rlang::eval_tidy(quo, data = data)

  if (!is.numeric(val)) {
    cli::cli_abort(c(
      "{.arg {arg_name}} must be a numeric column name or a numeric scalar.",
      "x" = "Got an object of class {.cls {class(val)}}."
    ))
  }
  val
}

# Assert all elements are strictly positive.
check_positive <- function(x, arg_name) {
  if (any(!is.finite(x)) || any(x <= 0)) {
    cli::cli_abort(c(
      "{.arg {arg_name}} must be strictly positive.",
      "x" = "Found non-positive or non-finite values."
    ))
  }
  invisible(x)
}

# Assert all elements are in (0, 1).
check_unit_interval <- function(x, arg_name) {
  if (any(!is.finite(x)) || any(x <= 0) || any(x >= 1)) {
    cli::cli_abort(c(
      "{.arg {arg_name}} must be in the open interval (0, 1).",
      "x" = "Found values outside this range."
    ))
  }
  invisible(x)
}

# Assert n > 1 (VG constraint for Mualem model).
check_n_gt_one <- function(n, arg_name = "n") {
  if (any(!is.finite(n)) || any(n <= 1)) {
    cli::cli_abort(c(
      "{.arg {arg_name}} must be greater than 1 for the Van Genuchten model.",
      "x" = "Found values <= 1."
    ))
  }
  invisible(n)
}

# Assert theta_s > theta_i (element-wise).
check_theta_bounds <- function(theta_i, theta_s) {
  if (any(theta_s <= theta_i)) {
    cli::cli_abort(c(
      "{.arg theta_s} must be greater than {.arg theta_i} for all observations.",
      "x" = "Found {sum(theta_s <= theta_i)} row(s) where this is violated."
    ))
  }
  invisible(NULL)
}

# Capillary factor cp(n) for the VG-Mualem model used in BEST alpha recovery.
# cp = 1 / [(2m + 1) * B(m + 0.5, 0.5)]  where m = 1 - 1/n
# Vectorised over n.
cp_factor <- function(n) {
  m  <- 1 - 1 / n
  # Beta function B(m + 0.5, 0.5) = gamma(m + 0.5) * gamma(0.5) / gamma(m + 1)
  cp <- 1 / ((2 * m + 1) * beta(m + 0.5, 0.5))
  cp
}
