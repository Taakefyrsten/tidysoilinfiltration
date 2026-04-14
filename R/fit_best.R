#' Fit the BEST algorithm to BeerKan cumulative infiltration data
#'
#' Implements the Beerkan Estimation of Soil Transfer parameters (BEST)
#' algorithm (Lassabatère et al., 2006) to estimate saturated hydraulic
#' conductivity Ks, sorptivity S, and the Van Genuchten scale parameter α from
#' BeerKan cumulative infiltration data.
#'
#' @section BEST algorithm:
#'
#' BEST uses the two-term approximation of the Haverkamp et al. (1994)
#' quasi-exact implicit (QEI) infiltration model. At late time (steady state)
#' the cumulative curve is linear:
#' \deqn{I(t) \approx K_s t + b}
#' where the intercept \eqn{b} encodes the sorptivity:
#' \deqn{b = \frac{S^2}{2 K_s \beta (1 - S_i)}, \quad S_i = \theta_i / \theta_s}
#'
#' Three fitting methods are available:
#'
#' - **`"steady"`** (default, recommended): Detects the steady-state portion as
#'   the last `steady_n` points (default 4; following the R-algorithm of
#'   Haverkamp et al.). Linear regression on that subset gives Ks (slope) and
#'   b (intercept), then S is back-calculated.
#' - **`"slope"`**: Estimates S from the early-time transient (slope of I vs
#'   √t on all points before the last `steady_n`), then Ks from the late-time
#'   intercept b.
#' - **`"intercept"`**: Linear regression on the full steady-state subset for
#'   both slope (→ Ks) and intercept (→ b → S), identical to `"steady"` but
#'   uses the earliest possible steady-state onset (first point where the rate
#'   change falls below `rate_tol`).
#'
#' After estimating Ks and S, the Van Genuchten α is recovered:
#' \deqn{\alpha = \frac{2 (\theta_s - \theta_i) K_s}{c_p \cdot S^2}}
#' where \eqn{c_p(n) = \bigl[(2m+1) \cdot B(m+\tfrac{1}{2},\tfrac{1}{2})\bigr]^{-1}}
#' and \eqn{m = 1 - 1/n}. This is evaluated via base R's `beta()` function —
#' no external dependencies, fully vectorised.
#'
#' @param data A data frame or tibble, optionally grouped with
#'   [dplyr::group_by()].
#' @param infiltration_col Bare column name of cumulative infiltration depth
#'   (cm). Typically `.infiltration` from [beerkan_cumulative()].
#' @param time_col Bare column name of cumulative infiltration time (s).
#'   Typically `.cumulative_time` from [beerkan_cumulative()].
#' @param theta_s Saturated volumetric water content (m³/m³ or cm³/cm³). Bare
#'   column name or scalar.
#' @param theta_i Initial volumetric water content (m³/m³ or cm³/cm³). Bare
#'   column name or scalar. Must be < `theta_s`.
#' @param n Van Genuchten shape parameter (dimensionless, must be > 1). Bare
#'   column name or scalar. Typically obtained from [infiltration_vg_params()]
#'   or supplied directly from particle-size analysis.
#' @param method Fitting method: `"steady"` (default), `"slope"`, or
#'   `"intercept"`. See the BEST algorithm section above.
#' @param beta Haverkamp β integral shape parameter (default `0.6`). Standard
#'   value from Haverkamp et al. (1994); override with calibrated values.
#' @param gamma Haverkamp γ proportionality constant for 3D lateral flow
#'   correction (default `0.75`). Not used in the current 1D implementation
#'   but retained for future 3D extension.
#' @param steady_n Number of terminal data points used to define the
#'   steady-state window for `method = "steady"` and `method = "intercept"`.
#'   Default `4` follows the R-algorithm recommendation.
#' @param workers Number of parallel workers (default `1`). Values > 1 use
#'   [parallel::mclapply()] on Unix; silently reduced to `1` on Windows.
#'
#' @return A tibble with one row per group containing:
#'   - Group keys (if grouped)
#'   - `.Ks` — saturated hydraulic conductivity (cm/s)
#'   - `.S` — sorptivity (cm/s^0.5)
#'   - `.alpha` — Van Genuchten α (1/cm)
#'   - `.Ks_std_error`, `.S_std_error` — standard errors propagated from
#'     the steady-state linear regression
#'   - `.steady_n` — number of points used for steady-state estimation
#'   - `.convergence` — `TRUE` if all estimates are finite and positive
#'
#' @note
#' θᵣ is assumed to be zero in the Sᵢ calculation (θᵢ / θₛ), which is the
#' standard BEST simplification. If you have a θᵣ estimate, pass
#' `theta_i = theta_i - theta_r` as an adjusted initial saturation.
#'
#' @references
#' Lassabatère, L., Angulo-Jaramillo, R., Soria Ugalde, J. M., Cuenca, R.,
#' Braud, I., & Haverkamp, R. (2006). Beerkan estimation of soil transfer
#' parameters through infiltration experiments—BEST. *Soil Science Society of
#' America Journal*, 70(2), 521–532.
#' <https://doi.org/10.2136/sssaj2005.0026>
#'
#' Haverkamp, R., Ross, P. J., Smettem, K. R. J., & Parlange, J.-Y. (1994).
#' Three-dimensional analysis of infiltration from the disc infiltrometer:
#' 2. Physically based infiltration equation. *Water Resources Research*,
#' 30(11), 2931–2935.
#'
#' @examples
#' library(tibble)
#' library(dplyr)
#'
#' # Single BeerKan run
#' run <- tibble(
#'   pour   = 1:10,
#'   volume = 100,
#'   time   = c(12, 18, 25, 30, 33, 34, 35, 35, 36, 35)
#' ) |>
#'   beerkan_cumulative(volume_col = volume, time_col = time, radius = 5)
#'
#' fit_best(run,
#'          infiltration_col = .infiltration,
#'          time_col         = .cumulative_time,
#'          theta_s          = 0.45,
#'          theta_i          = 0.12,
#'          n                = 1.56)
#'
#' # Multiple sites via group_by; n from texture lookup
#' meta <- tibble(
#'   site    = c("S1", "S2"),
#'   texture = c("loam", "sandy loam"),
#'   theta_s = c(0.45, 0.40),
#'   theta_i = c(0.12, 0.08)
#' ) |>
#'   infiltration_vg_params(texture = texture, suction = 0)
#'
#' @export
fit_best <- function(data, infiltration_col, time_col,
                     theta_s, theta_i, n,
                     method   = c("steady", "slope", "intercept"),
                     beta     = 0.6,
                     gamma    = 0.75,
                     steady_n = 4L,
                     workers  = 1L) {
  method <- match.arg(method)

  infilt_quo  <- rlang::enquo(infiltration_col)
  time_quo    <- rlang::enquo(time_col)
  theta_s_quo <- rlang::enquo(theta_s)
  theta_i_quo <- rlang::enquo(theta_i)
  n_quo       <- rlang::enquo(n)

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

  # Resolve scalar/column arguments to vectors per row
  .theta_s <- resolve_arg(theta_s_quo, data, "theta_s")
  .theta_i <- resolve_arg(theta_i_quo, data, "theta_i")
  .n       <- resolve_arg(n_quo,       data, "n")

  check_theta_bounds(.theta_i, .theta_s)
  check_n_gt_one(.n)
  check_positive(beta, "beta")
  check_positive(gamma, "gamma")

  steady_n <- max(as.integer(steady_n), 2L)

  workers <- as.integer(workers)
  if (workers < 1L) workers <- 1L
  if (workers > 1L && .Platform$OS.type == "windows") {
    cli::cli_warn("Parallel fitting not supported on Windows; using workers = 1.")
    workers <- 1L
  }

  # Attach resolved scalar columns while preserving group structure.
  # Strip groups first so we can assign full-length vectors, then re-apply.
  grp_vars <- dplyr::groups(data)
  nr       <- nrow(data)
  data_aug <- tibble::as_tibble(data)
  data_aug$.best_theta_s_ <- if (length(.theta_s) == 1L) rep(.theta_s, nr) else .theta_s
  data_aug$.best_theta_i_ <- if (length(.theta_i) == 1L) rep(.theta_i, nr) else .theta_i
  data_aug$.best_n_       <- if (length(.n)       == 1L) rep(.n,       nr) else .n
  if (length(grp_vars) > 0L) {
    data_aug <- dplyr::group_by(data_aug, !!!grp_vars)
  }

  # Core fit for a single group ---------------------------------------------
  fit_one_group <- function(df, ...) {
    I_vec  <- df[[infilt_nm]]
    t_vec  <- df[[time_nm]]
    ts_val <- df$.best_theta_s_[[1]]
    ti_val <- df$.best_theta_i_[[1]]
    n_val  <- df$.best_n_[[1]]

    npts <- length(I_vec)
    if (npts < steady_n + 2L) {
      cli::cli_warn(
        "Too few data points for BEST fit (have {npts}, need >= {steady_n + 2})."
      )
      return(.best_na_row(steady_n))
    }

    Si   <- ti_val / ts_val                     # relative initial saturation
    dtheta <- ts_val - ti_val

    # Steady-state indices: last `steady_n` points
    ss_idx <- (npts - steady_n + 1L):npts

    # Transient indices: everything before steady-state
    trans_idx <- seq_len(npts - steady_n)

    tryCatch(
      {
        # ---- Steady-state linear regression: I ~ Ks*t + b ------------------
        ss_I <- I_vec[ss_idx]
        ss_t <- t_vec[ss_idx]
        ss_lm <- stats::lm(ss_I ~ ss_t)
        ss_coef <- stats::coef(ss_lm)
        ss_se   <- summary(ss_lm)$coefficients[, "Std. Error"]

        Ks <- ss_coef[[2]]     # slope = Ks
        b  <- ss_coef[[1]]     # intercept = b

        Ks_se <- ss_se[[2]]
        b_se  <- ss_se[[1]]

        if (Ks <= 0) {
          cli::cli_warn("BEST: negative Ks estimated from steady-state slope; returning NA.")
          return(.best_na_row(steady_n))
        }

        if (method == "steady" || method == "intercept") {
          # S from intercept b
          # b = S^2 / (2 * Ks * beta * (1 - Si))  =>  S = sqrt(2*Ks*beta*(1-Si)*b)
          S_sq <- 2 * Ks * beta * (1 - Si) * b
          if (S_sq <= 0) {
            cli::cli_warn("BEST: negative S^2 (b may be non-positive); returning NA.")
            return(.best_na_row(steady_n))
          }
          S <- sqrt(S_sq)
          # Propagate SE: dS/dKs and dS/db via delta method (approximate)
          dS_dKs <- (beta * (1 - Si) * b) / S
          dS_db  <- (Ks  * beta * (1 - Si)) / S
          S_se   <- sqrt((dS_dKs * Ks_se)^2 + (dS_db * b_se)^2)
        } else {
          # method == "slope": S from transient I ~ sqrt(t)
          if (length(trans_idx) < 2L) {
            cli::cli_warn("BEST slope method: insufficient transient points; falling back to steady.")
            S_sq <- 2 * Ks * beta * (1 - Si) * b
            if (S_sq <= 0) return(.best_na_row(steady_n))
            S    <- sqrt(S_sq)
            S_se <- NA_real_
          } else {
            tr_I    <- I_vec[trans_idx]
            tr_sqt  <- sqrt(t_vec[trans_idx])
            tr_lm   <- stats::lm(tr_I ~ 0 + tr_sqt)   # force through origin
            S       <- max(stats::coef(tr_lm)[[1]], 1e-10)
            S_se    <- summary(tr_lm)$coefficients[1, "Std. Error"]
          }
        }

        # ---- Recover VG alpha from S and Ks ---------------------------------
        cp    <- cp_factor(n_val)
        alpha <- (2 * dtheta * Ks) / (cp * S^2)

        ok <- is.finite(Ks) && Ks > 0 &&
              is.finite(S)  && S  > 0 &&
              is.finite(alpha) && alpha > 0

        tibble::tibble(
          .Ks          = Ks,
          .S           = S,
          .alpha       = alpha,
          .Ks_std_error = Ks_se,
          .S_std_error  = if (is.null(S_se)) NA_real_ else S_se,
          .steady_n    = as.integer(steady_n),
          .convergence = ok
        )
      },
      error = function(e) {
        cli::cli_warn(c(
          "BEST fit did not converge.",
          "i" = "Original error: {conditionMessage(e)}"
        ))
        .best_na_row(steady_n)
      }
    )
  }

  # Dispatch ----------------------------------------------------------------
  is_grouped <- dplyr::is_grouped_df(data_aug)

  result <- if (!is_grouped) {
    fit_one_group(data_aug)
  } else if (workers == 1L) {
    dplyr::group_modify(data_aug, fit_one_group) |> dplyr::ungroup()
  } else {
    group_dfs  <- dplyr::group_split(data_aug)
    group_keys <- dplyr::group_keys(data_aug)
    fits       <- parallel::mclapply(group_dfs, fit_one_group, mc.cores = workers)
    dplyr::bind_cols(group_keys, dplyr::bind_rows(fits))
  }

  # Drop the auxiliary columns if they ended up in the result
  result[, !grepl("^\\.best_.*_$", names(result)), drop = FALSE]
}

.best_na_row <- function(steady_n) {
  tibble::tibble(
    .Ks           = NA_real_,
    .S            = NA_real_,
    .alpha        = NA_real_,
    .Ks_std_error = NA_real_,
    .S_std_error  = NA_real_,
    .steady_n     = as.integer(steady_n),
    .convergence  = FALSE
  )
}
