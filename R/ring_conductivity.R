#' Estimate saturated hydraulic conductivity from ponded ring infiltration
#'
#' A convenience wrapper that combines [infiltration_cumulative()],
#' [infiltration_rate()], and [fit_infiltration_horton()] into a single
#' pipeline step. Takes raw time–volume readings from a ponded ring
#' infiltrometer and returns Horton (1940) model parameters, where `.fc`
#' (the asymptotic final rate) is an estimate of **field-saturated hydraulic
#' conductivity Kfs**.
#'
#' The Horton model is:
#' \deqn{f(t) = f_c + (f_0 - f_c) \cdot e^{-k t}}
#'
#' where \eqn{f_c} ≈ Kfs (cm/s), \eqn{f_0} is the initial infiltration rate,
#' and \eqn{k} (1/s) is the exponential decay constant.
#'
#' **When to use the step-by-step approach instead:** If you want to visualise
#' the raw cumulative infiltration curve or the rate decay before fitting, call
#' [infiltration_cumulative()], [infiltration_rate()], and
#' [fit_infiltration_horton()] individually.
#'
#' @param data A data frame or tibble, optionally grouped with
#'   [dplyr::group_by()]. If grouped, the model is fitted independently per
#'   group.
#' @param time Bare column name; elapsed time in seconds.
#' @param volume Bare column name; water volume in the reservoir (mL),
#'   decreasing as water infiltrates.
#' @param radius Ring radius in cm. No default — ring sizes vary and a silent
#'   wrong value would produce incorrect Kfs estimates.
#' @param workers Number of parallel workers passed to
#'   [fit_infiltration_horton()]. Defaults to `1`. Values > 1 use
#'   `parallel::mclapply()` (Unix only).
#'
#' @return A tibble with one row per group containing:
#'   - Group keys (if grouped)
#'   - `.fc` — final/steady-state infiltration rate ≈ Kfs (cm/s)
#'   - `.f0` — initial infiltration rate (cm/s)
#'   - `.k` — exponential decay constant (1/s)
#'   - `.fc_std_error`, `.f0_std_error`, `.k_std_error`
#'   - `.convergence` — logical; `TRUE` if NLS converged
#'
#' @seealso [fit_infiltration_horton()], [infiltration_cumulative()],
#'   [infiltration_rate()], [minidisk_conductivity()]
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
#' # Single ring — 100 cm ring radius, 1-hour run
#' ring <- tibble(
#'   time   = seq(0, 3600, 360),
#'   volume = c(500, 440, 390, 355, 328, 308, 292, 280, 271, 265, 260)
#' )
#'
#' ring_conductivity(ring, time = time, volume = volume, radius = 10)
#'
#' # Multi-site: one group_by feeds the full pipeline
#' multi <- tibble(
#'   site   = rep(c("A", "B"), each = 11),
#'   time   = rep(seq(0, 3600, 360), 2),
#'   volume = c(
#'     500, 440, 390, 355, 328, 308, 292, 280, 271, 265, 260,
#'     500, 450, 410, 375, 348, 328, 313, 302, 294, 288, 284
#'   )
#' )
#'
#' multi |>
#'   group_by(site) |>
#'   ring_conductivity(time = time, volume = volume, radius = 10)
#'
#' @export
ring_conductivity <- function(data, time, volume, radius, workers = 1L) {
  time_quo   <- rlang::enquo(time)
  volume_quo <- rlang::enquo(volume)

  check_positive(radius, "radius")

  data |>
    infiltration_cumulative(
      time   = !!time_quo,
      volume = !!volume_quo,
      radius = radius
    ) |>
    infiltration_rate(
      time_col        = !!time_quo,
      infiltration_col = .infiltration
    ) |>
    fit_infiltration_horton(
      rate_col = .rate,
      time_col = .time_mid,
      workers  = workers
    )
}
