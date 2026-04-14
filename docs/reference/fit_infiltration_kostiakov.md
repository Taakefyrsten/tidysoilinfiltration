# Fit the Kostiakov (1932) cumulative infiltration model

Fits the Kostiakov power model to cumulative infiltration data: \$\$I(t)
= a \cdot t^b \quad (a \> 0,\\ 0 \< b \< 1)\$\$

## Usage

``` r
fit_infiltration_kostiakov(data, infiltration_col, time_col, workers = 1L)
```

## Arguments

- data:

  A data frame or tibble, optionally grouped.

- infiltration_col:

  Bare column name of cumulative infiltration depth (cm). Typically
  `.infiltration` from
  [`infiltration_cumulative()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/infiltration_cumulative.md).

- time_col:

  Bare column name of elapsed time (s). Use the original `time` column
  (not `.sqrt_time`).

- workers:

  Number of parallel workers (default 1).

## Value

A tibble with one row per group containing:

- Group keys (if grouped)

- `.a` — Kostiakov coefficient (cm/s^b)

- `.b` — Kostiakov exponent (dimensionless)

- `.a_std_error`, `.b_std_error`

- `.convergence`

## Details

The model is linearised as \\\log I = \log a + b \log t\\ to derive
starting values, then refined with
[`nls()`](https://rdrr.io/r/stats/nls.html) on the original scale.

The instantaneous infiltration rate corresponding to this model is
\\f(t) = a \cdot b \cdot t^{b-1}\\, which decreases monotonically with
time when \\0 \< b \< 1\\. Note that the Kostiakov model does not
approach a finite steady-state value (\\f \to 0\\ as \\t \to \infty\\),
so it should not be used to estimate Ksat.

The first row within each group typically has `t = 0`, which would
produce a zero or undefined logarithm. Rows with `time == 0` or
`infiltration == 0` are automatically excluded from fitting.

If `data` is grouped, the model is fitted independently per group.

## References

Kostiakov, A. N. (1932). On the dynamics of the coefficient of
water-percolation in soils. *Transactions of the 6th Commission of the
International Society of Soil Science*, Part A, 17–21.

## Examples

``` r
library(tibble)
library(dplyr)

dat <- tibble(
  time   = seq(0, 3600, 360),
  volume = c(500, 440, 390, 355, 328, 308, 292, 280, 271, 265, 260)
) |>
  infiltration_cumulative(time = time, volume = volume, radius = 10)

fit_infiltration_kostiakov(dat,
                           infiltration_col = .infiltration,
                           time_col         = time)
#> # A tibble: 1 × 5
#>       .a    .b .a_std_error .b_std_error .convergence
#>    <dbl> <dbl>        <dbl>        <dbl> <lgl>       
#> 1 0.0142 0.494      0.00457       0.0416 TRUE        
```
