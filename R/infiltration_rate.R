#' Compute interval infiltration rates from cumulative data
#'
#' Computes the mean infiltration rate over each consecutive time interval:
#' \deqn{f_i = \frac{I_i - I_{i-1}}{t_i - t_{i-1}}}
#'
#' The rate is assigned to the midpoint time of each interval. The first row
#' within each group has no preceding observation and returns `NA` for both
#' `.rate` and `.time_mid`.
#'
#' The function is **group-aware**: if `data` is grouped with
#' [dplyr::group_by()], differences are computed independently within each
#' group using `dplyr::lag()`.
#'
#' @param data A data frame or tibble. Passed as the first argument so the
#'   function is compatible with `|>` and `%>%` pipes.
#' @param time_col Bare column name; elapsed time in seconds. For BeerKan data,
#'   use `.cumulative_time`.
#' @param infiltration_col Bare column name; cumulative infiltration depth (cm).
#'   Typically `.infiltration` from [infiltration_cumulative()] or
#'   [beerkan_cumulative()].
#'
#' @return The input `data` as a tibble with two additional columns:
#'   - `.rate` — mean infiltration rate over the interval (cm/s); `NA` for the
#'     first row within each group
#'   - `.time_mid` — midpoint time of the interval (s); `NA` for the first row
#'
#' @examples
#' library(tibble)
#' library(dplyr)
#'
#' dat <- tibble(
#'   time   = seq(0, 300, 30),
#'   volume = c(95, 89, 86, 83, 80, 77, 74, 73, 71, 69, 67)
#' ) |>
#'   infiltration_cumulative(time = time, volume = volume)
#'
#' infiltration_rate(dat, time_col = time, infiltration_col = .infiltration)
#'
#' @export
infiltration_rate <- function(data, time_col, infiltration_col) {
  time_quo  <- rlang::enquo(time_col)
  infilt_quo <- rlang::enquo(infiltration_col)

  time_nm   <- rlang::as_name(time_quo)
  infilt_nm <- rlang::as_name(infilt_quo)

  if (!time_nm %in% names(data)) {
    cli::cli_abort(c(
      "Column {.val {time_nm}} not found in {.arg data}.",
      "i" = "Available columns: {.val {names(data)}}."
    ))
  }
  if (!infilt_nm %in% names(data)) {
    cli::cli_abort(c(
      "Column {.val {infilt_nm}} not found in {.arg data}.",
      "i" = "Available columns: {.val {names(data)}}."
    ))
  }

  data |>
    dplyr::mutate(
      .rate     = (.data[[infilt_nm]] - dplyr::lag(.data[[infilt_nm]])) /
                  (.data[[time_nm]]   - dplyr::lag(.data[[time_nm]])),
      .time_mid = (.data[[time_nm]] + dplyr::lag(.data[[time_nm]])) / 2
    ) |>
    tibble::as_tibble()
}
