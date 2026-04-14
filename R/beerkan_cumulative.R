#' Compute cumulative infiltration from BeerKan pour-event data
#'
#' Converts raw BeerKan experiment data — where a fixed volume is poured
#' repeatedly and the time for each pour to infiltrate is recorded — into
#' cumulative I(t) pairs suitable for `fit_infiltration()` or `fit_best()`.
#'
#' The BeerKan protocol records data in the **inverted** direction compared to
#' standard ring and Minidisk experiments:
#' - **Standard / Minidisk**: volume measured at fixed time steps
#' - **BeerKan**: time measured for each fixed-volume pour to disappear
#'
#' Cumulative quantities are computed as:
#' \deqn{t_i = \sum_{j=1}^{i} \Delta t_j}
#' \deqn{I_i = \frac{\sum_{j=1}^{i} V_j}{\pi r^2}}
#'
#' The function is **group-aware**: if `data` is grouped with
#' [dplyr::group_by()], cumulative sums are computed independently within each
#' group (using `dplyr::mutate()` with `cumsum()`).
#'
#' @param data A data frame or tibble. Passed as the first argument so the
#'   function is compatible with `|>` and `%>%` pipes.
#' @param volume_col Bare column name; volume poured in each event (mL). The
#'   volume may vary between pours (e.g. 100 mL for most, 50 mL for the last).
#' @param time_col Bare column name; time for that pour to completely infiltrate
#'   (seconds).
#' @param radius Ring radius in cm. No default is provided because ring size
#'   varies; always pass the actual radius to avoid silent errors.
#'
#' @return The input `data` as a tibble with four additional columns:
#'   - `.cumulative_time` — cumulative infiltration time (s)
#'   - `.sqrt_time` — square root of `.cumulative_time` (s^0.5); provided for
#'     compatibility with [fit_infiltration()]
#'   - `.cumulative_volume` — cumulative volume infiltrated (mL)
#'   - `.infiltration` — cumulative infiltration depth (cm)
#'
#' @references
#' Lassabatère, L., Angulo-Jaramillo, R., Soria Ugalde, J. M., Cuenca, R.,
#' Braud, I., & Haverkamp, R. (2006). Beerkan estimation of soil transfer
#' parameters through infiltration experiments—BEST. *Soil Science Society of
#' America Journal*, 70(2), 521–532.
#' <https://doi.org/10.2136/sssaj2005.0026>
#'
#' @examples
#' library(tibble)
#' library(dplyr)
#'
#' # Single BeerKan run — 100 mL poured each time
#' run <- tibble(
#'   pour   = 1:8,
#'   volume = 100,          # mL per pour (fixed)
#'   time   = c(12, 18, 24, 30, 34, 35, 35, 36)  # s to infiltrate
#' )
#' beerkan_cumulative(run, volume_col = volume, time_col = time, radius = 5)
#'
#' # Multiple sites with group_by
#' runs <- tibble(
#'   site   = rep(c("S1", "S2"), each = 5),
#'   volume = 100,
#'   time   = c(10, 14, 18, 21, 22, 25, 35, 45, 50, 51)
#' )
#' runs |>
#'   group_by(site) |>
#'   beerkan_cumulative(volume_col = volume, time_col = time, radius = 5)
#'
#' @export
beerkan_cumulative <- function(data, volume_col, time_col, radius) {
  volume_quo <- rlang::enquo(volume_col)
  time_quo   <- rlang::enquo(time_col)

  volume_nm <- rlang::as_name(volume_quo)
  time_nm   <- rlang::as_name(time_quo)

  if (!volume_nm %in% names(data)) {
    cli::cli_abort(c(
      "Column {.val {volume_nm}} not found in {.arg data}.",
      "i" = "Available columns: {.val {names(data)}}."
    ))
  }
  if (!time_nm %in% names(data)) {
    cli::cli_abort(c(
      "Column {.val {time_nm}} not found in {.arg data}.",
      "i" = "Available columns: {.val {names(data)}}."
    ))
  }
  if (missing(radius)) {
    cli::cli_abort(c(
      "{.arg radius} is required for {.fn beerkan_cumulative}.",
      "i" = "Ring size varies by experiment; always pass the actual ring radius (cm)."
    ))
  }

  check_positive(radius, "radius")

  area <- pi * radius^2

  data |>
    dplyr::mutate(
      .cumulative_time   = cumsum(.data[[time_nm]]),
      .sqrt_time         = sqrt(.cumulative_time),
      .cumulative_volume = cumsum(.data[[volume_nm]]),
      .infiltration      = .cumulative_volume / area
    ) |>
    tibble::as_tibble()
}
