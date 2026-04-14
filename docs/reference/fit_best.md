# Fit the BEST algorithm to BeerKan cumulative infiltration data

Implements the Beerkan Estimation of Soil Transfer parameters (BEST)
algorithm (Lassabatère et al., 2006) to estimate saturated hydraulic
conductivity Ks, sorptivity S, and the Van Genuchten scale parameter α
from BeerKan cumulative infiltration data.

## Usage

``` r
fit_best(
  data,
  infiltration_col,
  time_col,
  theta_s,
  theta_i,
  n,
  method = c("steady", "slope", "intercept"),
  beta = 0.6,
  gamma = 0.75,
  steady_n = 4L,
  workers = 1L
)
```

## Arguments

- data:

  A data frame or tibble, optionally grouped with
  [`dplyr::group_by()`](https://dplyr.tidyverse.org/reference/group_by.html).

- infiltration_col:

  Bare column name of cumulative infiltration depth (cm). Typically
  `.infiltration` from
  [`beerkan_cumulative()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/beerkan_cumulative.md).

- time_col:

  Bare column name of cumulative infiltration time (s). Typically
  `.cumulative_time` from
  [`beerkan_cumulative()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/beerkan_cumulative.md).

- theta_s:

  Saturated volumetric water content (m³/m³ or cm³/cm³). Bare column
  name or scalar.

- theta_i:

  Initial volumetric water content (m³/m³ or cm³/cm³). Bare column name
  or scalar. Must be \< `theta_s`.

- n:

  Van Genuchten shape parameter (dimensionless, must be \> 1). Bare
  column name or scalar. Typically obtained from
  [`infiltration_vg_params()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/infiltration_vg_params.md)
  or supplied directly from particle-size analysis.

- method:

  Fitting method: `"steady"` (default), `"slope"`, or `"intercept"`. See
  the BEST algorithm section above.

- beta:

  Haverkamp β integral shape parameter (default `0.6`). Standard value
  from Haverkamp et al. (1994); override with calibrated values.

- gamma:

  Haverkamp γ proportionality constant for 3D lateral flow correction
  (default `0.75`). Not used in the current 1D implementation but
  retained for future 3D extension.

- steady_n:

  Number of terminal data points used to define the steady-state window
  for `method = "steady"` and `method = "intercept"`. Default `4`
  follows the R-algorithm recommendation.

- workers:

  Number of parallel workers (default `1`). Values \> 1 use
  [`parallel::mclapply()`](https://rdrr.io/r/parallel/mclapply.html) on
  Unix; silently reduced to `1` on Windows.

## Value

A tibble with one row per group containing:

- Group keys (if grouped)

- `.Ks` — saturated hydraulic conductivity (cm/s)

- `.S` — sorptivity (cm/s^0.5)

- `.alpha` — Van Genuchten α (1/cm)

- `.Ks_std_error`, `.S_std_error` — standard errors propagated from the
  steady-state linear regression

- `.steady_n` — number of points used for steady-state estimation

- `.convergence` — `TRUE` if all estimates are finite and positive

## Note

θᵣ is assumed to be zero in the Sᵢ calculation (θᵢ / θₛ), which is the
standard BEST simplification. If you have a θᵣ estimate, pass
`theta_i = theta_i - theta_r` as an adjusted initial saturation.

## BEST algorithm

BEST uses the two-term approximation of the Haverkamp et al. (1994)
quasi-exact implicit (QEI) infiltration model. At late time (steady
state) the cumulative curve is linear: \$\$I(t) \approx K_s t + b\$\$
where the intercept \\b\\ encodes the sorptivity: \$\$b = \frac{S^2}{2
K_s \beta (1 - S_i)}, \quad S_i = \theta_i / \theta_s\$\$

Three fitting methods are available:

- **`"steady"`** (default, recommended): Detects the steady-state
  portion as the last `steady_n` points (default 4; following the
  R-algorithm of Haverkamp et al.). Linear regression on that subset
  gives Ks (slope) and b (intercept), then S is back-calculated.

- **`"slope"`**: Estimates S from the early-time transient (slope of I
  vs √t on all points before the last `steady_n`), then Ks from the
  late-time intercept b.

- **`"intercept"`**: Linear regression on the full steady-state subset
  for both slope (→ Ks) and intercept (→ b → S), identical to `"steady"`
  but uses the earliest possible steady-state onset (first point where
  the rate change falls below `rate_tol`).

After estimating Ks and S, the Van Genuchten α is recovered: \$\$\alpha
= \frac{2 (\theta_s - \theta_i) K_s}{c_p \cdot S^2}\$\$ where \\c_p(n) =
\bigl\[(2m+1) \cdot B(m+\tfrac{1}{2},\tfrac{1}{2})\bigr\]^{-1}\\ and \\m
= 1 - 1/n\\. This is evaluated via base R's
[`beta()`](https://rdrr.io/r/base/Special.html) function — no external
dependencies, fully vectorised.

## References

Lassabatère, L., Angulo-Jaramillo, R., Soria Ugalde, J. M., Cuenca, R.,
Braud, I., & Haverkamp, R. (2006). Beerkan estimation of soil transfer
parameters through infiltration experiments—BEST. *Soil Science Society
of America Journal*, 70(2), 521–532.
<https://doi.org/10.2136/sssaj2005.0026>

Haverkamp, R., Ross, P. J., Smettem, K. R. J., & Parlange, J.-Y. (1994).
Three-dimensional analysis of infiltration from the disc infiltrometer:
2. Physically based infiltration equation. *Water Resources Research*,
30(11), 2931–2935.

## Examples

``` r
library(tibble)
library(dplyr)

# Single BeerKan run
run <- tibble(
  pour   = 1:10,
  volume = 100,
  time   = c(12, 18, 25, 30, 33, 34, 35, 35, 36, 35)
) |>
  beerkan_cumulative(volume_col = volume, time_col = time, radius = 5)

fit_best(run,
         infiltration_col = .infiltration,
         time_col         = .cumulative_time,
         theta_s          = 0.45,
         theta_i          = 0.12,
         n                = 1.56)
#> # A tibble: 1 × 7
#>      .Ks    .S .alpha .Ks_std_error .S_std_error .steady_n .convergence
#>    <dbl> <dbl>  <dbl>         <dbl>        <dbl>     <int> <lgl>       
#> 1 0.0360 0.263   1.29      0.000144      0.00217         4 TRUE        

# Multiple sites via group_by; n from texture lookup
meta <- tibble(
  site    = c("S1", "S2"),
  texture = c("loam", "sandy loam"),
  theta_s = c(0.45, 0.40),
  theta_i = c(0.12, 0.08)
) |>
  infiltration_vg_params(texture = texture, suction = 0)
```
