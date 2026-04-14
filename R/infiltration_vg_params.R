#' Look up Van Genuchten parameters from the Minidisk reference table
#'
#' Appends Van Genuchten shape parameters (n, α) and the tabulated A value to
#' each row of `data` by matching texture class and suction level against the
#' built-in [minidisk_vg_params] lookup table (Decagon Devices, Inc., 2005).
#'
#' The lookup table covers 12 USDA texture classes and suction levels of 0.5,
#' 1, 2, 3, 4, 5, 6, and 7 cm (all for a disc radius of 2.25 cm). For the
#' BeerKan experiment (null pressure head), pass `suction = 0` — the function
#' will return the tabulated shape parameters (n, α) while setting `.A` to
#' `NA`, as A is not defined at zero suction in the Decagon table.
#'
#' @param data A data frame or tibble.
#' @param texture Bare column name or character scalar; USDA texture class
#'   (lowercase, e.g. `"clay loam"`). Must match one of the 12 classes in
#'   [minidisk_vg_params].
#' @param suction Bare column name, numeric scalar, or character scalar
#'   (e.g. `"2cm"`); suction level in cm. Must match one of 0.5, 1, 2, 3, 4,
#'   5, 6, or 7 cm for full lookup. Pass `0` to retrieve only shape parameters.
#'
#' @return The input `data` as a tibble with three additional columns:
#'   - `.n` — Van Genuchten n parameter (dimensionless, > 1)
#'   - `.alpha` — Van Genuchten α parameter (1/cm)
#'   - `.A` — tabulated A value for a 2.25 cm disc; `NA` when suction is 0
#'
#' @seealso [minidisk_vg_params] for the full lookup table,
#'   [parameter_A_zhang()] to compute A analytically from n and α.
#'
#' @references
#' Decagon Devices, Inc. (2005). *Mini Disk Infiltrometer User's Manual*.
#'
#' @examples
#' library(tibble)
#'
#' soils <- tibble(
#'   site    = c("A", "B"),
#'   texture = c("sandy loam", "clay loam"),
#'   suction = c(4, 2)
#' )
#' infiltration_vg_params(soils, texture = texture, suction = suction)
#'
#' # Scalar suction
#' infiltration_vg_params(soils, texture = texture, suction = 3)
#'
#' # Character suction string
#' soils2 <- tibble(texture = "loam", suction = "2cm")
#' infiltration_vg_params(soils2, texture = texture, suction = suction)
#'
#' # For BeerKan: retrieve shape params only (A is NA at suction = 0)
#' beerkan_meta <- tibble(texture = "sandy loam", theta_s = 0.45, theta_i = 0.1)
#' infiltration_vg_params(beerkan_meta, texture = texture, suction = 0)
#'
#' @export
infiltration_vg_params <- function(data, texture, suction) {
  texture_quo <- rlang::enquo(texture)
  suction_quo <- rlang::enquo(suction)

  texture_vec <- resolve_arg_chr(texture_quo, data, "texture")
  suction_raw <- resolve_arg(suction_quo, data, "suction")

  # Parse character suction strings like "2cm" -> 2
  suction_vec <- parse_suction(suction_raw)

  out <- tibble::as_tibble(data)
  nr  <- nrow(out)

  # Recycle scalars to match number of rows
  if (length(texture_vec) == 1L) texture_vec <- rep(texture_vec, nr)
  if (length(suction_vec) == 1L) suction_vec <- rep(suction_vec, nr)

  # Validate texture classes
  valid_textures <- unique(minidisk_vg_params$texture)
  bad_tex <- setdiff(unique(texture_vec), valid_textures)
  if (length(bad_tex) > 0) {
    cli::cli_abort(c(
      "Unknown texture class(es): {.val {bad_tex}}.",
      "i" = "Valid classes: {.val {valid_textures}}."
    ))
  }

  # Validate suction levels (allow 0 for BeerKan shape-param-only lookup)
  valid_suctions <- c(0, unique(minidisk_vg_params$suction_cm))
  bad_suc <- setdiff(unique(suction_vec), valid_suctions)
  if (length(bad_suc) > 0) {
    cli::cli_abort(c(
      "Suction level(s) not found in lookup table: {.val {bad_suc}} cm.",
      "i" = "Available levels: {.val {unique(minidisk_vg_params$suction_cm)}} cm.",
      "i" = "Use suction = 0 to retrieve only shape parameters (n, alpha)."
    ))
  }

  # Build a per-row key tibble and join
  key_df <- tibble::tibble(
    .row_id_   = seq_len(nrow(out)),
    .texture_  = texture_vec,
    .suction_  = suction_vec
  )

  # Rows where suction == 0 get n and alpha from any suction row (constant per texture)
  # Split into suction-0 (shape only) and normal rows
  idx_zero   <- which(suction_vec == 0)
  idx_normal <- which(suction_vec != 0)

  result_n     <- rep(NA_real_, nrow(out))
  result_alpha <- rep(NA_real_, nrow(out))
  result_A     <- rep(NA_real_, nrow(out))

  # Normal rows: full join
  if (length(idx_normal) > 0) {
    lkp_normal <- dplyr::left_join(
      key_df[idx_normal, , drop = FALSE],
      minidisk_vg_params,
      by = c(".texture_" = "texture", ".suction_" = "suction_cm")
    )
    result_n[idx_normal]     <- lkp_normal$n
    result_alpha[idx_normal] <- lkp_normal$alpha
    result_A[idx_normal]     <- lkp_normal$A
  }

  # Zero-suction rows: shape params only (pick first row per texture)
  if (length(idx_zero) > 0) {
    shape_only <- minidisk_vg_params |>
      dplyr::group_by(texture) |>
      dplyr::slice(1) |>
      dplyr::ungroup() |>
      dplyr::select(texture, n, alpha)

    lkp_zero <- dplyr::left_join(
      key_df[idx_zero, , drop = FALSE],
      shape_only,
      by = c(".texture_" = "texture")
    )
    result_n[idx_zero]     <- lkp_zero$n
    result_alpha[idx_zero] <- lkp_zero$alpha
    # result_A stays NA
  }

  out$.n     <- result_n
  out$.alpha <- result_alpha
  out$.A     <- result_A
  out
}

# Resolve a quosure to a character vector or scalar (for texture).
resolve_arg_chr <- function(quo, data, arg_name) {
  expr <- rlang::get_expr(quo)

  if (rlang::is_symbol(expr)) {
    nm <- rlang::as_string(expr)
    if (nm %in% names(data)) {
      val <- data[[nm]]
      if (!is.character(val)) {
        cli::cli_abort(c(
          "{.arg {arg_name}} must be a character column or scalar.",
          "x" = "Column {.val {nm}} has class {.cls {class(val)}}."
        ))
      }
      return(val)
    }
  }

  val <- rlang::eval_tidy(quo, data = data)
  if (!is.character(val)) {
    cli::cli_abort(c(
      "{.arg {arg_name}} must be a character column name or a character scalar.",
      "x" = "Got an object of class {.cls {class(val)}}."
    ))
  }
  val
}

# Parse numeric or character suction to numeric cm.
parse_suction <- function(x) {
  if (is.character(x)) {
    # Strip non-numeric characters (e.g. "2cm" -> 2, "0.5 cm" -> 0.5)
    num <- suppressWarnings(as.numeric(gsub("[^0-9.]", "", x)))
    if (any(is.na(num))) {
      cli::cli_abort(c(
        "Could not parse {.arg suction} as a numeric value.",
        "x" = "Problematic value(s): {.val {x[is.na(num)]}}.",
        "i" = "Provide suction as numeric (cm) or as a string like {.val {'2cm'}}."
      ))
    }
    return(num)
  }
  x
}
