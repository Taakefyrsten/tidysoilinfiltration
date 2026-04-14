# Compute unsaturated hydraulic conductivity from Minidisk data

Calculates the unsaturated hydraulic conductivity at the applied tension
using the Zhang (1997) relationship: \$\$K(h) = \frac{C_1}{A}\$\$

## Usage

``` r
hydraulic_conductivity_minidisk(data, C1, A)
```

## Arguments

- data:

  A data frame or tibble.

- C1:

  Bare column name or scalar; the quadratic (time-proportional)
  coefficient from the Philip two-term fit (cm/s). Typically `.C1` from
  [`fit_infiltration()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/fit_infiltration.md).

- A:

  Bare column name or scalar; the A parameter (cm). Typically `.A` from
  [`infiltration_vg_params()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/infiltration_vg_params.md)
  or
  [`parameter_A_zhang()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/parameter_A_zhang.md).

## Value

The input `data` as a tibble with one additional column `.K_h` (cm/s).

## Details

where C₁ is the quadratic coefficient from
[`fit_infiltration()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/fit_infiltration.md)
and A is the shape parameter from
[`infiltration_vg_params()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/infiltration_vg_params.md)
or
[`parameter_A_zhang()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/parameter_A_zhang.md).

## References

Zhang, R. (1997). Determination of soil sorptivity and hydraulic
conductivity from the disk infiltrometer. *Soil Science Society of
America Journal*, 61(4), 1024–1030.
<https://doi.org/10.2136/sssaj1997.03615995006100060008x>

## Examples

``` r
library(tibble)

results <- tibble(site = c("A", "B"), .C1 = c(0.004, 0.009), .A = c(3.91, 6.27))
hydraulic_conductivity_minidisk(results, C1 = .C1, A = .A)
#> # A tibble: 2 × 4
#>   site    .C1    .A    .K_h
#>   <chr> <dbl> <dbl>   <dbl>
#> 1 A     0.004  3.91 0.00102
#> 2 B     0.009  6.27 0.00144
```
