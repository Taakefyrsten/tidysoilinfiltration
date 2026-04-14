#' Van Genuchten parameters for Minidisk Infiltrometer analysis
#'
#' A tidy long-format tibble of tabulated Van Genuchten parameters and the
#' derived A values for the Minidisk Infiltrometer (disc radius 2.25 cm),
#' covering 12 USDA texture classes at eight applied suction levels.
#'
#' @format A tibble with 96 rows and 5 columns:
#' \describe{
#'   \item{texture}{USDA texture class (character, lowercase). One of:
#'     `"sand"`, `"loamy sand"`, `"sandy loam"`, `"loam"`, `"silt"`,
#'     `"silt loam"`, `"sandy clay loam"`, `"clay loam"`,
#'     `"silty clay loam"`, `"sandy clay"`, `"silty clay"`, `"clay"`.}
#'   \item{suction_cm}{Applied suction level (numeric, cm). One of:
#'     0.5, 1, 2, 3, 4, 5, 6, 7.}
#'   \item{n}{Van Genuchten shape parameter n (dimensionless, > 1). Constant
#'     across suction levels for a given texture class.}
#'   \item{alpha}{Van Genuchten scale parameter α (1/cm). Constant across
#'     suction levels for a given texture class.}
#'   \item{A}{Tabulated A value for a disc radius of 2.25 cm (cm). Used in the
#'     Zhang (1997) relationship K(h) = C₁ / A.}
#' }
#'
#' @source Decagon Devices, Inc. (2005). *Mini Disk Infiltrometer User's
#'   Manual*. Data accessed via the
#'   [infiltrodiscR](https://github.com/biofisicasuelos/infiltrodiscR) package.
#'
#' @seealso [infiltration_vg_params()] to look up parameters by texture and
#'   suction, [parameter_A_zhang()] to compute A analytically.
#'
#' @examples
#' minidisk_vg_params
#'
#' # Subset to a single texture class
#' subset(minidisk_vg_params, texture == "sandy loam")
"minidisk_vg_params"
