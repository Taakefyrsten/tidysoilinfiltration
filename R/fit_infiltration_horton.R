#' Fit the Horton (1940) infiltration rate model
#'
#' Fits the Horton (1940) exponential decay model to infiltration rates
#' computed at discrete time intervals:
#' \deqn{f(t) = f_c + (f_0 - f_c) \cdot e^{-k t}}
#'
#' where \eqn{f_c} (cm/s) is the final/steady-state rate (≈ Ksat for ponded
#' ring experiments), \eqn{f_0} (cm/s) is the initial rate, and \eqn{k} (1/s)
#' is the decay constant.
#'
#' Inputs are typically interval rates computed with [infiltration_rate()]:
#' `.rate` (y) and `.time_mid` (x). The first row within each group has
#' `NA` values and is automatically excluded from fitting.
#'
#' Starting values are derived automatically from the data range:
#' - `f0_start` = maximum observed rate
#' - `fc_start` = minimum observed rate
#' - `k_start` = 0.01 (1/s)
#'
#' If `data` is grouped, the model is fitted independently per group. Parallel
#' fitting is available on Unix via `workers > 1`.
#'
#' @param data A data frame or tibble, optionally grouped.
#' @param rate_col Bare column name of infiltration rates (cm/s). Typically
#'   `.rate` from [infiltration_rate()].
#' @param time_col Bare column name of midpoint times (s). Typically
#'   `.time_mid` from [infiltration_rate()].
#' @param workers Number of parallel workers (default 1).
#'
#' @return A tibble with one row per group containing:
#'   - Group keys (if grouped)
#'   - `.fc` — final/steady-state rate ≈ Ksat (cm/s)
#'   - `.f0` — initial rate (cm/s)
#'   - `.k` — decay constant (1/s)
#'   - `.fc_std_error`, `.f0_std_error`, `.k_std_error`
#'   - `.convergence`
#'
#' @references
#' Horton, R. E. (1940). An approach toward a physical interpretation of
#' infiltration capacity. *Soil Science Society of America Proceedings*,
#' 5, 399–417.
#'
#' @examples
#' library(tibble)
#' library(dplyr)
#'
#' dat <- tibble(
#'   time   = seq(0, 3600, 360),
#'   volume = c(500, 440, 390, 355, 328, 308, 292, 280, 271, 265, 260)
#' ) |>
#'   infiltration_cumulative(time = time, volume = volume, radius = 10) |>
#'   infiltration_rate(time_col = time, infiltration_col = .infiltration)
#'
#' fit_infiltration_horton(dat, rate_col = .rate, time_col = .time_mid)
#'
#' @export
fit_infiltration_horton <- function(data, rate_col, time_col, workers = 1L) {
  rate_quo <- rlang::enquo(rate_col)
  time_quo <- rlang::enquo(time_col)

  rate_nm <- rlang::as_name(rate_quo)
  time_nm <- rlang::as_name(time_quo)

  for (nm in c(rate_nm, time_nm)) {
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
    # Drop NA rows (first row per group from infiltration_rate)
    df <- df[!is.na(df[[rate_nm]]) & !is.na(df[[time_nm]]), ]

    rate_vec <- df[[rate_nm]]
    time_vec <- df[[time_nm]]

    if (length(rate_vec) < 3L) {
      cli::cli_warn("Insufficient non-NA observations for Horton fit (need >= 3).")
      return(.horton_na_row())
    }

    fc_start <- max(min(rate_vec, na.rm = TRUE), 1e-10)
    f0_start <- max(rate_vec, na.rm = TRUE)
    # Estimate k from log-linear fit on excess rate: ln(f - fc) ~ -k*t
    excess   <- rate_vec - fc_start * 0.5
    excess[excess <= 0] <- 1e-15
    k_start  <- max(
      -stats::coef(stats::lm(log(excess) ~ time_vec))[[2]],
      1e-6
    )

    tryCatch(
      {
        fit <- stats::nls(
          formula = rate ~ fc + (f0 - fc) * exp(-k * time),
          data    = data.frame(rate = rate_vec, time = time_vec),
          start   = list(fc = fc_start, f0 = f0_start, k = k_start),
          control = stats::nls.control(maxiter = 200, tol = 1e-6)
        )
        tidy_fit <- broom::tidy(fit)
        params   <- stats::setNames(tidy_fit$estimate, tidy_fit$term)
        se       <- stats::setNames(tidy_fit$std.error, tidy_fit$term)

        tibble::tibble(
          .fc           = params[["fc"]],
          .f0           = params[["f0"]],
          .k            = params[["k"]],
          .fc_std_error = se[["fc"]],
          .f0_std_error = se[["f0"]],
          .k_std_error  = se[["k"]],
          .convergence  = TRUE
        )
      },
      error = function(e) {
        cli::cli_warn(c(
          "Horton model did not converge.",
          "i" = "Original error: {conditionMessage(e)}"
        ))
        .horton_na_row()
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

.horton_na_row <- function() {
  tibble::tibble(
    .fc           = NA_real_,
    .f0           = NA_real_,
    .k            = NA_real_,
    .fc_std_error = NA_real_,
    .f0_std_error = NA_real_,
    .k_std_error  = NA_real_,
    .convergence  = FALSE
  )
}
