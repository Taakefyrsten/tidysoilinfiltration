# Changelog

## tidysoilinfiltration 1.1.0

### New functions

- [`minidisk_conductivity()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/minidisk_conductivity.md)
  — convenience wrapper combining
  [`infiltration_vg_params()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/infiltration_vg_params.md),
  optionally
  [`parameter_A_zhang()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/parameter_A_zhang.md),
  and
  [`hydraulic_conductivity_minidisk()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/hydraulic_conductivity_minidisk.md)
  into a single pipeline step. Accepts `method = "tabulated"` (default,
  Decagon lookup) or `method = "zhang"` (analytical A via Zhang 1997).
  Reduces the Minidisk pipeline from 7 steps to 4 and eliminates the
  double
  [`group_by()`](https://dplyr.tidyverse.org/reference/group_by.html).
- [`ring_conductivity()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/ring_conductivity.md)
  — convenience wrapper combining
  [`infiltration_cumulative()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/infiltration_cumulative.md),
  [`infiltration_rate()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/infiltration_rate.md),
  and
  [`fit_infiltration_horton()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/fit_infiltration_horton.md)
  into one call. Takes raw time–volume readings from a ponded ring
  infiltrometer and returns Horton parameters including `.fc` ≈ Kfs.
  Supports the same
  [`group_by()`](https://dplyr.tidyverse.org/reference/group_by.html)
  workflow as all other package functions.

### Bug fixes

- [`infiltration_cumulative()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/infiltration_cumulative.md)
  and
  [`infiltration_rate()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/infiltration_rate.md)
  previously stripped
  [`group_by()`](https://dplyr.tidyverse.org/reference/group_by.html)
  grouping via an internal
  [`as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html)
  call, requiring users to re-group before calling
  [`fit_infiltration()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/fit_infiltration.md).
  Both functions now preserve grouping through the pipeline, so a single
  [`group_by()`](https://dplyr.tidyverse.org/reference/group_by.html) is
  sufficient for the entire multi-site workflow.

------------------------------------------------------------------------

## tidysoilinfiltration 1.0.0

Initial release.

### New functions

- [`infiltration_cumulative()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/infiltration_cumulative.md)
  — convert time–volume readings from Minidisk or ring infiltrometers to
  cumulative infiltration depth I(t) and √t. Fully group-aware.
- [`beerkan_cumulative()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/beerkan_cumulative.md)
  — convert BeerKan pour-event data (fixed volumes, infiltration times)
  to cumulative I(t). Group-aware via
  [`cumsum()`](https://rdrr.io/r/base/cumsum.html).
- [`infiltration_rate()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/infiltration_rate.md)
  — compute mean interval infiltration rates and midpoint times from
  cumulative data. Group-aware.
- [`fit_infiltration()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/fit_infiltration.md)
  — fit the Philip (1957) two-term polynomial `I = C₂√t + C₁t` by OLS.
  Returns C₁ (conductivity proxy) and C₂ (sorptivity proxy). Supports
  parallel fitting across groups.
- [`infiltration_vg_params()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/infiltration_vg_params.md)
  — look up Van Genuchten n, α, and A from the Decagon Devices (2005)
  table by texture class and suction. Pass `suction = 0` for BeerKan
  (shape parameters only; `.A` is `NA`).
- [`parameter_A_zhang()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/parameter_A_zhang.md)
  — compute the Zhang (1997) A parameter analytically from n, α,
  suction, and disc radius. Fully vectorised.
- [`hydraulic_conductivity_minidisk()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/hydraulic_conductivity_minidisk.md)
  — compute K(h) = C₁ / A.
- [`fit_infiltration_horton()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/fit_infiltration_horton.md)
  — fit the Horton (1940) exponential rate decay model by NLS. Returns
  fc ≈ Ksat, f₀, k.
- [`fit_infiltration_kostiakov()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/fit_infiltration_kostiakov.md)
  — fit the Kostiakov (1932) power model `I = a t^b` by NLS. Returns a,
  b.
- [`fit_best()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/fit_best.md)
  — implement the BEST algorithm (Lassabatère et al., 2006). Estimates
  Ks, S, and α from BeerKan cumulative data using the Haverkamp et
  al. (1994) quasi-exact implicit model. Three fitting methods:
  `"steady"` (default), `"slope"`, `"intercept"`. Supports parallel
  fitting.

### Datasets

- `minidisk_vg_params` — long-format tibble (96 rows × 5 columns) of Van
  Genuchten parameters n, α, and A for 12 USDA texture classes at 8
  suction levels (0.5–7 cm). Source: Decagon Devices, Inc. (2005), via
  infiltrodiscR.

### Notes

- All functions are pipe-compatible (data frame as first argument,
  returns tibble) and use tidy evaluation for column arguments.
- Fully vectorised backends — no R-level loops — suitable for
  raster-scale workflows at millions of cells.
- Parallel fitting via
  [`parallel::mclapply()`](https://rdrr.io/r/parallel/mclapply.html) on
  Unix-like systems (`workers` argument on all `fit_*` functions).
