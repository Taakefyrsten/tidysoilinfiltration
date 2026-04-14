#' Compute cumulative infiltration from time-volume series
#'
#' Converts raw time–volume readings from a Minidisk or ring infiltrometer into
#' cumulative infiltration depth and its square root of time, ready for
#' downstream model fitting.
#'
#' Cumulative infiltration is calculated as:
#' \deqn{I = \frac{V_0 - V}{\pi r^2}}
#' where \eqn{V_0} is the initial volume (first observation within each group),
#' \eqn{V} is the volume at time \eqn{t}, and \eqn{r} is the disc or ring
#' radius.
#'
#' The function is **group-aware**: if `data` is grouped with
#' [dplyr::group_by()], the initial volume \eqn{V_0} is taken as the first
#' observation *within each group*, so multiple samples can be processed in a
#' single pipeline step.
#'
#' @param data A data frame or tibble. Passed as the first argument so the
#'   function is compatible with `|>` and `%>%` pipes.
#' @param time Bare column name or scalar numeric; elapsed time in seconds.
#' @param volume Bare column name or scalar numeric; water volume in the
#'   reservoir (mL), decreasing as water infiltrates.
#' @param radius Disc or ring radius in cm. Defaults to `2.25`, the standard
#'   Minidisk Infiltrometer radius. Pass the actual ring radius for standard
#'   ring infiltrometers.
#'
#' @return The input `data` as a tibble with three additional columns:
#'   - `.sqrt_time` — square root of elapsed time (s^0.5)
#'   - `.volume_infiltrated` — cumulative volume infiltrated from the start of
#'     the run (mL)
#'   - `.infiltration` — cumulative infiltration depth (cm)
#'
#' @references
#' Philip, J. R. (1957). The theory of infiltration: 4. Sorptivity and algebraic
#' infiltration equations. *Soil Science*, 84(3), 257–264.
#'
#' @examples
#' library(tibble)
#' library(dplyr)
#'
#' # Single sample
#' minidisk <- tibble(
#'   time   = seq(0, 300, 30),
#'   volume = c(95, 89, 86, 83, 80, 77, 74, 73, 71, 69, 67)
#' )
#' infiltration_cumulative(minidisk, time = time, volume = volume)
#'
#' # Multiple samples via group_by — initial volume taken per group
#' multi <- tibble(
#'   sample = rep(c("A", "B"), each = 11),
#'   time   = rep(seq(0, 300, 30), 2),
#'   volume = c(95, 89, 86, 83, 80, 77, 74, 73, 71, 69, 67,
#'              83, 77, 64, 61, 58, 45, 42, 35, 29, 17, 15)
#' )
#' multi |>
#'   group_by(sample) |>
#'   infiltration_cumulative(time = time, volume = volume)
#'
#' # Ring infiltrometer with 10 cm radius
#' ring <- tibble(time = seq(0, 600, 60), volume = 500 - seq(0, 200, 20))
#' infiltration_cumulative(ring, time = time, volume = volume, radius = 10)
#'
#' @export
infiltration_cumulative <- function(data, time, volume, radius = 2.25) {
  time_quo   <- rlang::enquo(time)
  volume_quo <- rlang::enquo(volume)

  time_nm   <- rlang::as_name(time_quo)
  volume_nm <- rlang::as_name(volume_quo)

  if (!time_nm %in% names(data)) {
    cli::cli_abort(c(
      "Column {.val {time_nm}} not found in {.arg data}.",
      "i" = "Available columns: {.val {names(data)}}."
    ))
  }
  if (!volume_nm %in% names(data)) {
    cli::cli_abort(c(
      "Column {.val {volume_nm}} not found in {.arg data}.",
      "i" = "Available columns: {.val {names(data)}}."
    ))
  }

  check_positive(radius, "radius")

  area <- pi * radius^2
  grps <- dplyr::group_vars(data)

  # Coerce to plain tibble first (handles data.frame input), then restore
  # groups so dplyr::first() is group-aware and grouping is preserved in output.
  tibble::as_tibble(data) |>
    dplyr::group_by(dplyr::across(dplyr::all_of(grps))) |>
    dplyr::mutate(
      .sqrt_time          = sqrt(.data[[time_nm]]),
      .volume_infiltrated = dplyr::first(.data[[volume_nm]]) - .data[[volume_nm]],
      .infiltration       = .volume_infiltrated / area
    )
}
