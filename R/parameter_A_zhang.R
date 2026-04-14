#' Compute the Zhang (1997) A parameter for Minidisk analysis
#'
#' Calculates the shape parameter A from the analytical expression proposed by
#' Zhang (1997), using Van Genuchten parameters n and α together with the
#' applied suction and disc radius:
#'
#' \deqn{A = \frac{11.65 \cdot (n^{0.1} - 1) \cdot
#'   \exp\!\bigl(B(n) \cdot (n - 1.9) \cdot \alpha \cdot |h|\bigr)}
#'   {(\alpha \cdot r_0)^{0.91}}}
#'
#' where \eqn{B(n) = 7.5} if \eqn{n < 1.9} and \eqn{B(n) = 2.92} otherwise.
#'
#' All column arguments accept bare column names or scalar numeric values,
#' following the tidy evaluation convention of the TidySoils ecosystem.
#'
#' @param data A data frame or tibble.
#' @param n Van Genuchten n parameter (dimensionless, must be > 1). Bare column
#'   name or scalar.
#' @param alpha Van Genuchten α parameter (1/cm, must be > 0). Bare column name
#'   or scalar.
#' @param suction Applied suction in cm (absolute value used internally). Bare
#'   column name or scalar.
#' @param radius Disc radius in cm. Defaults to `2.25` (Minidisk standard).
#'
#' @return The input `data` as a tibble with one additional column `.A`.
#'
#' @references
#' Zhang, R. (1997). Determination of soil sorptivity and hydraulic conductivity
#' from the disk infiltrometer. *Soil Science Society of America Journal*,
#' 61(4), 1024–1030. <https://doi.org/10.2136/sssaj1997.03615995006100060008x>
#'
#' @examples
#' library(tibble)
#'
#' soils <- tibble(
#'   site   = c("A", "B"),
#'   n      = c(1.89, 1.56),
#'   alpha  = c(0.075, 0.036),
#'   suction = c(4, 2)
#' )
#'
#' # Using bare column names
#' parameter_A_zhang(soils, n = n, alpha = alpha, suction = suction)
#'
#' # Scalar suction, column n and alpha
#' parameter_A_zhang(soils, n = n, alpha = alpha, suction = 3)
#'
#' # Non-standard disc radius
#' parameter_A_zhang(soils, n = n, alpha = alpha, suction = suction, radius = 3)
#'
#' @export
parameter_A_zhang <- function(data, n, alpha, suction, radius = 2.25) {
  n_quo       <- rlang::enquo(n)
  alpha_quo   <- rlang::enquo(alpha)
  suction_quo <- rlang::enquo(suction)

  .n       <- resolve_arg(n_quo,       data, "n")
  .alpha   <- resolve_arg(alpha_quo,   data, "alpha")
  .suction <- resolve_arg(suction_quo, data, "suction")

  check_n_gt_one(.n)
  check_positive(.alpha, "alpha")
  check_positive(radius, "radius")

  # Absolute suction value (sign convention: positive = suction)
  h_abs <- abs(.suction)

  # B coefficient is soil-dependent on n
  B <- ifelse(.n < 1.9, 7.5, 2.92)

  out    <- tibble::as_tibble(data)
  out$.A <- (11.65 * (.n^0.1 - 1) * exp(B * (.n - 1.9) * .alpha * h_abs)) /
            ((.alpha * radius)^0.91)
  out
}
