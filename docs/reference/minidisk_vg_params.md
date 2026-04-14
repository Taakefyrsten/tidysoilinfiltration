# Van Genuchten parameters for Minidisk Infiltrometer analysis

A tidy long-format tibble of tabulated Van Genuchten parameters and the
derived A values for the Minidisk Infiltrometer (disc radius 2.25 cm),
covering 12 USDA texture classes at eight applied suction levels.

## Usage

``` r
minidisk_vg_params
```

## Format

A tibble with 96 rows and 5 columns:

- texture:

  USDA texture class (character, lowercase). One of: `"sand"`,
  `"loamy sand"`, `"sandy loam"`, `"loam"`, `"silt"`, `"silt loam"`,
  `"sandy clay loam"`, `"clay loam"`, `"silty clay loam"`,
  `"sandy clay"`, `"silty clay"`, `"clay"`.

- suction_cm:

  Applied suction level (numeric, cm). One of: 0.5, 1, 2, 3, 4, 5, 6, 7.

- n:

  Van Genuchten shape parameter n (dimensionless, \> 1). Constant across
  suction levels for a given texture class.

- alpha:

  Van Genuchten scale parameter α (1/cm). Constant across suction levels
  for a given texture class.

- A:

  Tabulated A value for a disc radius of 2.25 cm (cm). Used in the
  Zhang (1997) relationship K(h) = C₁ / A.

## Source

Decagon Devices, Inc. (2005). *Mini Disk Infiltrometer User's Manual*.
Data accessed via the
[infiltrodiscR](https://github.com/biofisicasuelos/infiltrodiscR)
package.

## See also

[`infiltration_vg_params()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/infiltration_vg_params.md)
to look up parameters by texture and suction,
[`parameter_A_zhang()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/parameter_A_zhang.md)
to compute A analytically.

## Examples

``` r
minidisk_vg_params
#> # A tibble: 96 × 5
#>    texture    suction_cm     n alpha     A
#>    <chr>           <dbl> <dbl> <dbl> <dbl>
#>  1 sand              0.5  2.68 0.145 2.84 
#>  2 sand              1    2.68 0.145 2.40 
#>  3 sand              2    2.68 0.145 1.73 
#>  4 sand              3    2.68 0.145 1.24 
#>  5 sand              4    2.68 0.145 0.893
#>  6 sand              5    2.68 0.145 0.642
#>  7 sand              6    2.68 0.145 0.461
#>  8 sand              7    2.68 0.145 0.331
#>  9 loamy sand        0.5  2.28 0.124 2.99 
#> 10 loamy sand        1    2.28 0.124 2.79 
#> # ℹ 86 more rows

# Subset to a single texture class
subset(minidisk_vg_params, texture == "sandy loam")
#> # A tibble: 8 × 5
#>   texture    suction_cm     n alpha     A
#>   <chr>           <dbl> <dbl> <dbl> <dbl>
#> 1 sandy loam        0.5  1.89 0.075  3.88
#> 2 sandy loam        1    1.89 0.075  3.89
#> 3 sandy loam        2    1.89 0.075  3.91
#> 4 sandy loam        3    1.89 0.075  3.93
#> 5 sandy loam        4    1.89 0.075  3.95
#> 6 sandy loam        5    1.89 0.075  3.98
#> 7 sandy loam        6    1.89 0.075  4.00
#> 8 sandy loam        7    1.89 0.075  4.02
```
