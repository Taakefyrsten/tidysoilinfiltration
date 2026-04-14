# Fit the Philip two-term infiltration model

Fits the Philip (1957) two-term polynomial to cumulative infiltration
data to extract the hydraulic conductivity proxy C₁ and sorptivity proxy
C₂: \$\$I = C_2 \sqrt{t} + C_1 t\$\$

## Usage

``` r
fit_infiltration(data, infiltration_col, sqrt_time_col, workers = 1L)
```

## Arguments

- data:

  A data frame or tibble, optionally grouped with
  [`dplyr::group_by()`](https://dplyr.tidyverse.org/reference/group_by.html).

- infiltration_col:

  Bare column name of cumulative infiltration depth (cm). Typically
  `.infiltration` from
  [`infiltration_cumulative()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/infiltration_cumulative.md)
  or
  [`beerkan_cumulative()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/beerkan_cumulative.md).

- sqrt_time_col:

  Bare column name of the square root of elapsed time (s^0.5). Typically
  `.sqrt_time`.

- workers:

  Number of parallel workers. Defaults to `1` (sequential). Values \> 1
  use [`parallel::mclapply()`](https://rdrr.io/r/parallel/mclapply.html)
  on Unix; silently reduced to `1` on Windows.

## Value

A tibble with one row per group (or one row for ungrouped data)
containing:

- Group keys (if input was grouped)

- `.C1` — quadratic coefficient (cm/s), the time-proportional term

- `.C2` — linear coefficient (cm/s^0.5), the sorptivity term

- `.C1_std_error`, `.C2_std_error` — standard errors

- `.convergence` — `TRUE` if [`lm()`](https://rdrr.io/r/stats/lm.html)
  succeeded

## Details

The fit uses ordinary least squares on the linearised form
`I ~ sqrt_time + I(sqrt_time^2)` (with intercept), matching published
methodology (infiltrodiscR, Zhang 1997 tables).

**Interpretation by mode:**

- **Minidisk**: C₁ feeds into
  [`hydraulic_conductivity_minidisk()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/hydraulic_conductivity_minidisk.md)
  via `K(h) = C₁ / A`.

- **Ring (ponded)**: C₁ ≈ Ksat at steady state.

- **BeerKan**: C₁ provides a quick Philip estimate before running the
  full
  [`fit_best()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/fit_best.md)
  algorithm.

If `data` is grouped with
[`dplyr::group_by()`](https://dplyr.tidyverse.org/reference/group_by.html),
the model is fitted independently for each group, returning one row per
group in the result. Parallel fitting across groups is available on
Unix-like systems via `workers > 1`.

## References

Philip, J. R. (1957). The theory of infiltration: 4. Sorptivity and
algebraic infiltration equations. *Soil Science*, 84(3), 257–264.

Zhang, R. (1997). Determination of soil sorptivity and hydraulic
conductivity from the disk infiltrometer. *Soil Science Society of
America Journal*, 61(4), 1024–1030.
<https://doi.org/10.2136/sssaj1997.03615995006100060008x>

## Examples

``` r
library(tibble)
library(dplyr)

dat <- tibble(
  time   = seq(0, 300, 30),
  volume = c(95, 89, 86, 83, 80, 77, 74, 73, 71, 69, 67)
) |>
  infiltration_cumulative(time = time, volume = volume)

fit_infiltration(dat,
                 infiltration_col = .infiltration,
                 sqrt_time_col    = .sqrt_time)
#> # A tibble: 1 × 5
#>      .C2     .C1 .C2_std_error .C1_std_error .convergence
#>    <dbl>   <dbl>         <dbl>         <dbl> <lgl>       
#> 1 0.0600 0.00252       0.00753      0.000396 TRUE        

# Grouped: one row per sample
multi <- tibble(
  sample = rep(c("A", "B"), each = 11),
  time   = rep(seq(0, 300, 30), 2),
  volume = c(95, 89, 86, 83, 80, 77, 74, 73, 71, 69, 67,
             83, 77, 64, 61, 58, 45, 42, 35, 29, 17, 15)
) |>
  group_by(sample) |>
  infiltration_cumulative(time = time, volume = volume)

fit_infiltration(multi,
                 infiltration_col = .infiltration,
                 sqrt_time_col    = .sqrt_time)
#> # A tibble: 1 × 5
#>      .C2     .C1 .C2_std_error .C1_std_error .convergence
#>    <dbl>   <dbl>         <dbl>         <dbl> <lgl>       
#> 1 0.0380 0.00803         0.118       0.00618 TRUE        
```
