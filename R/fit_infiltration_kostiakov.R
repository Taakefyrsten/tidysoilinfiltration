#' Fit the Kostiakov (1932) cumulative infiltration model
#'
#' Fits the Kostiakov power model to cumulative infiltration data:
#' \deqn{I(t) = a \cdot t^b \quad (a > 0,\ 0 < b < 1)}
#'
#' The model is linearised as \eqn{\log I = \log a + b \log t} to derive
#' starting values, then refined with `nls()` on the original scale.
#'
#' The instantaneous infiltration rate corresponding to this model is
#' \eqn{f(t) = a \cdot b \cdot t^{b-1}}, which decreases monotonically with
#' time when \eqn{0 < b < 1}. Note that the Kostiakov model does not approach
#' a finite steady-state value (\eqn{f \to 0} as \eqn{t \to \infty}), so it
#' should not be used to estimate Ksat.
#'
#' The first row within each group typically has `t = 0`, which would produce
#' a zero or undefined logarithm. Rows with `time == 0` or `infiltration == 0`
#' are automatically excluded from fitting.
#'
#' If `data` is grouped, the model is fitted independently per group.
#'
#' @param data A data frame or tibble, optionally grouped.
#' @param infiltration_col Bare column name of cumulative infiltration depth
#'   (cm). Typically `.infiltration` from [infiltration_cumulative()].
#' @param time_col Bare column name of elapsed time (s). Use the original
#'   `time` column (not `.sqrt_time`).
#' @param workers Number of parallel workers (default 1).
#'
#' @return A tibble with one row per group containing:
#'   - Group keys (if grouped)
#'   - `.a` — Kostiakov coefficient (cm/s^b)
#'   - `.b` — Kostiakov exponent (dimensionless)
#'   - `.a_std_error`, `.b_std_error`
#'   - `.convergence`
#'
#' @references
#' Kostiakov, A. N. (1932). On the dynamics of the coefficient of
#' water-percolation in soils. *Transactions of the 6th Commission of the
#' International Society of Soil Science*, Part A, 17–21.
#'
#' @examples
#' library(tibble)
#' library(dplyr)
#'
#' dat <- tibble(
#'   time   = seq(0, 3600, 360),
#'   volume = c(500, 440, 390, 355, 328, 308, 292, 280, 271, 265, 260)
#' ) |>
#'   infiltration_cumulative(time = time, volume = volume, radius = 10)
#'
#' fit_infiltration_kostiakov(dat,
#'                            infiltration_col = .infiltration,
#'                            time_col         = time)
#'
#' @export
fit_infiltration_kostiakov <- function(data, infiltration_col, time_col,
                                       workers = 1L) {
  infilt_quo <- rlang::enquo(infiltration_col)
  time_quo   <- rlang::enquo(time_col)

  infilt_nm <- rlang::as_name(infilt_quo)
  time_nm   <- rlang::as_name(time_quo)

  for (nm in c(infilt_nm, time_nm)) {
    if (!nm %in% names(data)) {
      cli::cli_abort(c(
        "Column {.val {nm}} not found in {.arg data}.",
        "i" = "Available columns: {.val {names(data)}}."
      ))
    }
  }

  workers <- as.integer(workers)
  if (workers < 1L) workers <- 1L
  if (workers > 1L && .Platform$OS.type == "windows") {
    cli::cli_warn("Parallel fitting not supported on Windows; using workers = 1.")
    workers <- 1L
  }

  fit_one_group <- function(df, ...) {
    # Exclude t=0 and I=0 rows (undefined in log-log space)
    df <- df[df[[time_nm]] > 0 & df[[infilt_nm]] > 0, ]

    infilt_vec <- df[[infilt_nm]]
    time_vec   <- df[[time_nm]]

    if (length(infilt_vec) < 3L) {
      cli::cli_warn("Insufficient positive observations for Kostiakov fit (need >= 3).")
      return(.kostiakov_na_row())
    }

    # Log-linear starting values
    log_fit <- stats::lm(log(infilt_vec) ~ log(time_vec))
    a_start <- max(exp(stats::coef(log_fit)[1]), 1e-6)
    b_start <- min(max(stats::coef(log_fit)[2], 0.01), 0.99)

    tryCatch(
      {
        fit <- stats::nls(
          formula = infiltration ~ a * time^b,
          data    = data.frame(infiltration = infilt_vec, time = time_vec),
          start   = list(a = a_start, b = b_start),
          control = stats::nls.control(maxiter = 200, tol = 1e-6)
        )
        tidy_fit <- broom::tidy(fit)
        params   <- stats::setNames(tidy_fit$estimate, tidy_fit$term)
        se       <- stats::setNames(tidy_fit$std.error, tidy_fit$term)

        tibble::tibble(
          .a           = params[["a"]],
          .b           = params[["b"]],
          .a_std_error = se[["a"]],
          .b_std_error = se[["b"]],
          .convergence = TRUE
        )
      },
      error = function(e) {
        cli::cli_warn(c(
          "Kostiakov model did not converge.",
          "i" = "Original error: {conditionMessage(e)}"
        ))
        .kostiakov_na_row()
      }
    )
  }

  is_grouped <- dplyr::is_grouped_df(data)

  if (!is_grouped) return(fit_one_group(data))

  if (workers == 1L) {
    return(dplyr::group_modify(data, fit_one_group) |> dplyr::ungroup())
  }

  group_dfs  <- dplyr::group_split(data)
  group_keys <- dplyr::group_keys(data)
  fits       <- parallel::mclapply(group_dfs, fit_one_group, mc.cores = workers)
  dplyr::bind_cols(group_keys, dplyr::bind_rows(fits))
}

.kostiakov_na_row <- function() {
  tibble::tibble(
    .a           = NA_real_,
    .b           = NA_real_,
    .a_std_error = NA_real_,
    .b_std_error = NA_real_,
    .convergence = FALSE
  )
}
