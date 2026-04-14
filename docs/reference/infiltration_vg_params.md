# Look up Van Genuchten parameters from the Minidisk reference table

Appends Van Genuchten shape parameters (n, α) and the tabulated A value
to each row of `data` by matching texture class and suction level
against the built-in
[minidisk_vg_params](https://taakefyrsten.github.io/tidysoilinfiltration/reference/minidisk_vg_params.md)
lookup table (Decagon Devices, Inc., 2005).

## Usage

``` r
infiltration_vg_params(data, texture, suction)
```

## Arguments

- data:

  A data frame or tibble.

- texture:

  Bare column name or character scalar; USDA texture class (lowercase,
  e.g. `"clay loam"`). Must match one of the 12 classes in
  [minidisk_vg_params](https://taakefyrsten.github.io/tidysoilinfiltration/reference/minidisk_vg_params.md).

- suction:

  Bare column name, numeric scalar, or character scalar (e.g. `"2cm"`);
  suction level in cm. Must match one of 0.5, 1, 2, 3, 4, 5, 6, or 7 cm
  for full lookup. Pass `0` to retrieve only shape parameters.

## Value

The input `data` as a tibble with three additional columns:

- `.n` — Van Genuchten n parameter (dimensionless, \> 1)

- `.alpha` — Van Genuchten α parameter (1/cm)

- `.A` — tabulated A value for a 2.25 cm disc; `NA` when suction is 0

## Details

The lookup table covers 12 USDA texture classes and suction levels of
0.5, 1, 2, 3, 4, 5, 6, and 7 cm (all for a disc radius of 2.25 cm). For
the BeerKan experiment (null pressure head), pass `suction = 0` — the
function will return the tabulated shape parameters (n, α) while setting
`.A` to `NA`, as A is not defined at zero suction in the Decagon table.

## References

Decagon Devices, Inc. (2005). *Mini Disk Infiltrometer User's Manual*.

## See also

[minidisk_vg_params](https://taakefyrsten.github.io/tidysoilinfiltration/reference/minidisk_vg_params.md)
for the full lookup table,
[`parameter_A_zhang()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/parameter_A_zhang.md)
to compute A analytically from n and α.

## Examples

``` r
library(tibble)

soils <- tibble(
  site    = c("A", "B"),
  texture = c("sandy loam", "clay loam"),
  suction = c(4, 2)
)
infiltration_vg_params(soils, texture = texture, suction = suction)
#> # A tibble: 2 × 6
#>   site  texture    suction    .n .alpha    .A
#>   <chr> <chr>        <dbl> <dbl>  <dbl> <dbl>
#> 1 A     sandy loam       4  1.89  0.075  3.95
#> 2 B     clay loam        2  1.31  0.019  6.64

# Scalar suction
infiltration_vg_params(soils, texture = texture, suction = 3)
#> # A tibble: 2 × 6
#>   site  texture    suction    .n .alpha    .A
#>   <chr> <chr>        <dbl> <dbl>  <dbl> <dbl>
#> 1 A     sandy loam       4  1.89  0.075  3.93
#> 2 B     clay loam        2  1.31  0.019  7.23

# Character suction string
soils2 <- tibble(texture = "loam", suction = "2cm")
infiltration_vg_params(soils2, texture = texture, suction = suction)
#> # A tibble: 1 × 5
#>   texture suction    .n .alpha    .A
#>   <chr>   <chr>   <dbl>  <dbl> <dbl>
#> 1 loam    2cm      1.56  0.036  6.27

# For BeerKan: retrieve shape params only (A is NA at suction = 0)
beerkan_meta <- tibble(texture = "sandy loam", theta_s = 0.45, theta_i = 0.1)
infiltration_vg_params(beerkan_meta, texture = texture, suction = 0)
#> # A tibble: 1 × 6
#>   texture    theta_s theta_i    .n .alpha    .A
#>   <chr>        <dbl>   <dbl> <dbl>  <dbl> <dbl>
#> 1 sandy loam    0.45     0.1  1.89  0.075    NA
```
