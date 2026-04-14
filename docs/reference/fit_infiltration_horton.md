# Fit the Horton (1940) infiltration rate model

Fits the Horton (1940) exponential decay model to infiltration rates
computed at discrete time intervals: \$\$f(t) = f_c + (f_0 - f_c) \cdot
e^{-k t}\$\$

## Usage

``` r
fit_infiltration_horton(data, rate_col, time_col, workers = 1L)
```

## Arguments

- data:

  A data frame or tibble, optionally grouped.

- rate_col:

  Bare column name of infiltration rates (cm/s). Typically `.rate` from
  [`infiltration_rate()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/infiltration_rate.md).

- time_col:

  Bare column name of midpoint times (s). Typically `.time_mid` from
  [`infiltration_rate()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/infiltration_rate.md).

- workers:

  Number of parallel workers (default 1).

## Value

A tibble with one row per group containing:

- Group keys (if grouped)

- `.fc` — final/steady-state rate ≈ Ksat (cm/s)

- `.f0` — initial rate (cm/s)

- `.k` — decay constant (1/s)

- `.fc_std_error`, `.f0_std_error`, `.k_std_error`

- `.convergence`

## Details

where \\f_c\\ (cm/s) is the final/steady-state rate (≈ Ksat for ponded
ring experiments), \\f_0\\ (cm/s) is the initial rate, and \\k\\ (1/s)
is the decay constant.

Inputs are typically interval rates computed with
[`infiltration_rate()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/infiltration_rate.md):
`.rate` (y) and `.time_mid` (x). The first row within each group has
`NA` values and is automatically excluded from fitting.

Starting values are derived automatically from the data range:

- `f0_start` = maximum observed rate

- `fc_start` = minimum observed rate

- `k_start` = 0.01 (1/s)

If `data` is grouped, the model is fitted independently per group.
Parallel fitting is available on Unix via `workers > 1`.

## References

Horton, R. E. (1940). An approach toward a physical interpretation of
infiltration capacity. *Soil Science Society of America Proceedings*, 5,
399–417.

## Examples

``` r
library(tibble)
library(dplyr)

dat <- tibble(
  time   = seq(0, 3600, 360),
  volume = c(500, 440, 390, 355, 328, 308, 292, 280, 271, 265, 260)
) |>
  infiltration_cumulative(time = time, volume = volume, radius = 10) |>
  infiltration_rate(time_col = time, infiltration_col = .infiltration)

fit_infiltration_horton(dat, rate_col = .rate, time_col = .time_mid)
#> # A tibble: 1 × 7
#>        .fc     .f0      .k .fc_std_error .f0_std_error .k_std_error .convergence
#>      <dbl>   <dbl>   <dbl>         <dbl>         <dbl>        <dbl> <lgl>       
#> 1 -1.46e-5 6.18e-4 7.14e-4     0.0000187     0.0000156    0.0000611 TRUE        
```
