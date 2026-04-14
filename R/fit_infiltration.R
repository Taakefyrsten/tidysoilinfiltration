#' Fit the Philip two-term infiltration model
#'
#' Fits the Philip (1957) two-term polynomial to cumulative infiltration data to
#' extract the hydraulic conductivity proxy C₁ and sorptivity proxy C₂:
#' \deqn{I = C_2 \sqrt{t} + C_1 t}
#'
#' The fit uses ordinary least squares on the linearised form
#' `I ~ sqrt_time + I(sqrt_time^2)` (with intercept), matching published
#' methodology (infiltrodiscR, Zhang 1997 tables).
#'
#' **Interpretation by mode:**
#' - **Minidisk**: C₁ feeds into [hydraulic_conductivity_minidisk()] via
#'   `K(h) = C₁ / A`.
#' - **Ring (ponded)**: C₁ ≈ Ksat at steady state.
#' - **BeerKan**: C₁ provides a quick Philip estimate before running the full
#'   [fit_best()] algorithm.
#'
#' If `data` is grouped with [dplyr::group_by()], the model is fitted
#' independently for each group, returning one row per group in the result.
#' Parallel fitting across groups is available on Unix-like systems via
#' `workers > 1`.
#'
#' @param data A data frame or tibble, optionally grouped with
#'   [dplyr::group_by()].
#' @param infiltration_col Bare column name of cumulative infiltration depth
#'   (cm). Typically `.infiltration` from [infiltration_cumulative()] or
#'   [beerkan_cumulative()].
#' @param sqrt_time_col Bare column name of the square root of elapsed time
#'   (s^0.5). Typically `.sqrt_time`.
#' @param workers Number of parallel workers. Defaults to `1` (sequential).
#'   Values > 1 use [parallel::mclapply()] on Unix; silently reduced to `1` on
#'   Windows.
#'
#' @return A tibble with one row per group (or one row for ungrouped data)
#'   containing:
#'   - Group keys (if input was grouped)
#'   - `.C1` — quadratic coefficient (cm/s), the time-proportional term
#'   - `.C2` — linear coefficient (cm/s^0.5), the sorptivity term
#'   - `.C1_std_error`, `.C2_std_error` — standard errors
#'   - `.convergence` — `TRUE` if `lm()` succeeded
#'
#' @references
#' Philip, J. R. (1957). The theory of infiltration: 4. Sorptivity and algebraic
#' infiltration equations. *Soil Science*, 84(3), 257–264.
#'
#' Zhang, R. (1997). Determination of soil sorptivity and hydraulic conductivity
#' from the disk infiltrometer. *Soil Science Society of America Journal*,
#' 61(4), 1024–1030. <https://doi.org/10.2136/sssaj1997.03615995006100060008x>
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
#' fit_infiltration(dat,
#'                  infiltration_col = .infiltration,
#'                  sqrt_time_col    = .sqrt_time)
#'
#' # Grouped: one row per sample
#' multi <- tibble(
#'   sample = rep(c("A", "B"), each = 11),
#'   time   = rep(seq(0, 300, 30), 2),
#'   volume = c(95, 89, 86, 83, 80, 77, 74, 73, 71, 69, 67,
#'              83, 77, 64, 61, 58, 45, 42, 35, 29, 17, 15)
#' ) |>
#'   group_by(sample) |>
#'   infiltration_cumulative(time = time, volume = volume)
#'
#' fit_infiltration(multi,
#'                  infiltration_col = .infiltration,
#'                  sqrt_time_col    = .sqrt_time)
#'
#' @export
fit_infiltration <- function(data, infiltration_col, sqrt_time_col, workers = 1L) {
  infilt_quo    <- rlang::enquo(infiltration_col)
  sqrt_time_quo <- rlang::enquo(sqrt_time_col)

  infilt_nm    <- rlang::as_name(infilt_quo)
  sqrt_time_nm <- rlang::as_name(sqrt_time_quo)

  if (!infilt_nm %in% names(data)) {
    cli::cli_abort(c(
      "Column {.val {infilt_nm}} not found in {.arg data}.",
      "i" = "Available columns: {.val {names(data)}}."
    ))
  }
  if (!sqrt_time_nm %in% names(data)) {
    cli::cli_abort(c(
      "Column {.val {sqrt_time_nm}} not found in {.arg data}.",
      "i" = "Available columns: {.val {names(data)}}."
    ))
  }

  workers <- as.integer(workers)
  if (workers < 1L) workers <- 1L
  if (workers > 1L && .Platform$OS.type == "windows") {
    cli::cli_warn(c(
      "Parallel fitting is not supported on Windows.",
      "i" = "Falling back to {.code workers = 1} (sequential)."
    ))
    workers <- 1L
  }

  # Core fit for a single group -----------------------------------------------
  fit_one_group <- function(df, ...) {
    infilt_vec    <- df[[infilt_nm]]
    sqrt_time_vec <- df[[sqrt_time_nm]]

    fit_df <- data.frame(
      .infilt    = infilt_vec,
      .sqrt_time = sqrt_time_vec
    )

    tryCatch(
      {
        fit     <- stats::lm(.infilt ~ .sqrt_time + I(.sqrt_time^2), data = fit_df)
        tidy_fit <- broom::tidy(fit)
        params  <- stats::setNames(tidy_fit$estimate, tidy_fit$term)
        se      <- stats::setNames(tidy_fit$std.error, tidy_fit$term)

        tibble::tibble(
          .C2            = params[[".sqrt_time"]],
          .C1            = params[["I(.sqrt_time^2)"]],
          .C2_std_error  = se[[".sqrt_time"]],
          .C1_std_error  = se[["I(.sqrt_time^2)"]],
          .convergence   = TRUE
        )
      },
      error = function(e) {
        cli::cli_warn(c(
          "Philip two-term fit did not converge.",
          "i" = "Original error: {conditionMessage(e)}"
        ))
        tibble::tibble(
          .C2           = NA_real_,
          .C1           = NA_real_,
          .C2_std_error = NA_real_,
          .C1_std_error = NA_real_,
          .convergence  = FALSE
        )
      }
    )
  }

  # Dispatch ------------------------------------------------------------------
  is_grouped <- dplyr::is_grouped_df(data)

  if (!is_grouped) {
    return(fit_one_group(data))
  }

  if (workers == 1L) {
    return(dplyr::group_modify(data, fit_one_group) |> dplyr::ungroup())
  }

  group_dfs  <- dplyr::group_split(data)
  group_keys <- dplyr::group_keys(data)

  fits <- parallel::mclapply(group_dfs, fit_one_group, mc.cores = workers)

  dplyr::bind_cols(group_keys, dplyr::bind_rows(fits))
}


