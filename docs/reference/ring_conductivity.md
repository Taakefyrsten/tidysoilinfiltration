# Estimate saturated hydraulic conductivity from ponded ring infiltration

A convenience wrapper that combines
[`infiltration_cumulative()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/infiltration_cumulative.md),
[`infiltration_rate()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/infiltration_rate.md),
and
[`fit_infiltration_horton()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/fit_infiltration_horton.md)
into a single pipeline step. Takes raw time–volume readings from a
ponded ring infiltrometer and returns Horton (1940) model parameters,
where `.fc` (the asymptotic final rate) is an estimate of
**field-saturated hydraulic conductivity Kfs**.

## Usage

``` r
ring_conductivity(data, time, volume, radius, workers = 1L)
```

## Arguments

- data:

  A data frame or tibble, optionally grouped with
  [`dplyr::group_by()`](https://dplyr.tidyverse.org/reference/group_by.html).
  If grouped, the model is fitted independently per group.

- time:

  Bare column name; elapsed time in seconds.

- volume:

  Bare column name; water volume in the reservoir (mL), decreasing as
  water infiltrates.

- radius:

  Ring radius in cm. No default — ring sizes vary and a silent wrong
  value would produce incorrect Kfs estimates.

- workers:

  Number of parallel workers passed to
  [`fit_infiltration_horton()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/fit_infiltration_horton.md).
  Defaults to `1`. Values \> 1 use
  [`parallel::mclapply()`](https://rdrr.io/r/parallel/mclapply.html)
  (Unix only).

## Value

A tibble with one row per group containing:

- Group keys (if grouped)

- `.fc` — final/steady-state infiltration rate ≈ Kfs (cm/s)

- `.f0` — initial infiltration rate (cm/s)

- `.k` — exponential decay constant (1/s)

- `.fc_std_error`, `.f0_std_error`, `.k_std_error`

- `.convergence` — logical; `TRUE` if NLS converged

## Details

The Horton model is: \$\$f(t) = f_c + (f_0 - f_c) \cdot e^{-k t}\$\$

where \\f_c\\ ≈ Kfs (cm/s), \\f_0\\ is the initial infiltration rate,
and \\k\\ (1/s) is the exponential decay constant.

**When to use the step-by-step approach instead:** If you want to
visualise the raw cumulative infiltration curve or the rate decay before
fitting, call
[`infiltration_cumulative()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/infiltration_cumulative.md),
[`infiltration_rate()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/infiltration_rate.md),
and
[`fit_infiltration_horton()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/fit_infiltration_horton.md)
individually.

## References

Horton, R. E. (1940). An approach toward a physical interpretation of
infiltration capacity. *Soil Science Society of America Proceedings*, 5,
399–417.

## See also

[`fit_infiltration_horton()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/fit_infiltration_horton.md),
[`infiltration_cumulative()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/infiltration_cumulative.md),
[`infiltration_rate()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/infiltration_rate.md),
[`minidisk_conductivity()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/minidisk_conductivity.md)

## Examples

``` r
library(tibble)
library(dplyr)

# Single ring — 100 cm ring radius, 1-hour run
ring <- tibble(
  time   = seq(0, 3600, 360),
  volume = c(500, 440, 390, 355, 328, 308, 292, 280, 271, 265, 260)
)

ring_conductivity(ring, time = time, volume = volume, radius = 10)
#> # A tibble: 1 × 7
#>        .fc     .f0      .k .fc_std_error .f0_std_error .k_std_error .convergence
#>      <dbl>   <dbl>   <dbl>         <dbl>         <dbl>        <dbl> <lgl>       
#> 1 -1.46e-5 6.18e-4 7.14e-4     0.0000187     0.0000156    0.0000611 TRUE        

# Multi-site: one group_by feeds the full pipeline
multi <- tibble(
  site   = rep(c("A", "B"), each = 11),
  time   = rep(seq(0, 3600, 360), 2),
  volume = c(
    500, 440, 390, 355, 328, 308, 292, 280, 271, 265, 260,
    500, 450, 410, 375, 348, 328, 313, 302, 294, 288, 284
  )
)

multi |>
  group_by(site) |>
  ring_conductivity(time = time, volume = volume, radius = 10)
#> # A tibble: 2 × 8
#>   site         .fc      .f0       .k .fc_std_error .f0_std_error .k_std_error
#>   <chr>      <dbl>    <dbl>    <dbl>         <dbl>         <dbl>        <dbl>
#> 1 A     -0.0000146 0.000618 0.000714     0.0000187     0.0000156    0.0000611
#> 2 B     -0.0000846 0.000492 0.000476     0.0000309     0.0000114    0.0000547
#> # ℹ 1 more variable: .convergence <lgl>
```
