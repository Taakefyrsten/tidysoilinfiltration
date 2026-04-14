#' Compute unsaturated hydraulic conductivity from Minidisk data
#'
#' Calculates the unsaturated hydraulic conductivity at the applied tension
#' using the Zhang (1997) relationship:
#' \deqn{K(h) = \frac{C_1}{A}}
#'
#' where C₁ is the quadratic coefficient from [fit_infiltration()] and A is the
#' shape parameter from [infiltration_vg_params()] or [parameter_A_zhang()].
#'
#' @param data A data frame or tibble.
#' @param C1 Bare column name or scalar; the quadratic (time-proportional)
#'   coefficient from the Philip two-term fit (cm/s). Typically `.C1` from
#'   [fit_infiltration()].
#' @param A Bare column name or scalar; the A parameter (cm). Typically `.A`
#'   from [infiltration_vg_params()] or [parameter_A_zhang()].
#'
#' @return The input `data` as a tibble with one additional column `.K_h`
#'   (cm/s).
#'
#' @references
#' Zhang, R. (1997). Determination of soil sorptivity and hydraulic conductivity
#' from the disk infiltrometer. *Soil Science Society of America Journal*,
#' 61(4), 1024–1030. <https://doi.org/10.2136/sssaj1997.03615995006100060008x>
#'
#' @examples
#' library(tibble)
#'
#' results <- tibble(site = c("A", "B"), .C1 = c(0.004, 0.009), .A = c(3.91, 6.27))
#' hydraulic_conductivity_minidisk(results, C1 = .C1, A = .A)
#'
#' @export
hydraulic_conductivity_minidisk <- function(data, C1, A) {
  C1_quo <- rlang::enquo(C1)
  A_quo  <- rlang::enquo(A)

  .C1 <- resolve_arg(C1_quo, data, "C1")
  .A  <- resolve_arg(A_quo,  data, "A")

  check_positive(.A, "A")

  out       <- tibble::as_tibble(data)
  out$.K_h  <- .C1 / .A
  out
}
