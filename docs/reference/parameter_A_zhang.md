# Compute the Zhang (1997) A parameter for Minidisk analysis

Calculates the shape parameter A from the analytical expression proposed
by Zhang (1997), using Van Genuchten parameters n and α together with
the applied suction and disc radius:

## Usage

``` r
parameter_A_zhang(data, n, alpha, suction, radius = 2.25)
```

## Arguments

- data:

  A data frame or tibble.

- n:

  Van Genuchten n parameter (dimensionless, must be \> 1). Bare column
  name or scalar.

- alpha:

  Van Genuchten α parameter (1/cm, must be \> 0). Bare column name or
  scalar.

- suction:

  Applied suction in cm (absolute value used internally). Bare column
  name or scalar.

- radius:

  Disc radius in cm. Defaults to `2.25` (Minidisk standard).

## Value

The input `data` as a tibble with one additional column `.A`.

## Details

\$\$A = \frac{11.65 \cdot (n^{0.1} - 1) \cdot \exp\\\bigl(B(n) \cdot
(n - 1.9) \cdot \alpha \cdot \|h\|\bigr)} {(\alpha \cdot
r_0)^{0.91}}\$\$

where \\B(n) = 7.5\\ if \\n \< 1.9\\ and \\B(n) = 2.92\\ otherwise.

All column arguments accept bare column names or scalar numeric values,
following the tidy evaluation convention of the TidySoils ecosystem.

## References

Zhang, R. (1997). Determination of soil sorptivity and hydraulic
conductivity from the disk infiltrometer. *Soil Science Society of
America Journal*, 61(4), 1024–1030.
<https://doi.org/10.2136/sssaj1997.03615995006100060008x>

## Examples

``` r
library(tibble)

soils <- tibble(
  site   = c("A", "B"),
  n      = c(1.89, 1.56),
  alpha  = c(0.075, 0.036),
  suction = c(4, 2)
)

# Using bare column names
parameter_A_zhang(soils, n = n, alpha = alpha, suction = suction)
#> # A tibble: 2 × 5
#>   site      n alpha suction    .A
#>   <chr> <dbl> <dbl>   <dbl> <dbl>
#> 1 A      1.89 0.075       4  3.78
#> 2 B      1.56 0.036       2  4.34

# Scalar suction, column n and alpha
parameter_A_zhang(soils, n = n, alpha = alpha, suction = 3)
#> # A tibble: 2 × 5
#>   site      n alpha suction    .A
#>   <chr> <dbl> <dbl>   <dbl> <dbl>
#> 1 A      1.89 0.075       4  3.80
#> 2 B      1.56 0.036       2  3.96

# Non-standard disc radius
parameter_A_zhang(soils, n = n, alpha = alpha, suction = suction, radius = 3)
#> # A tibble: 2 × 5
#>   site      n alpha suction    .A
#>   <chr> <dbl> <dbl>   <dbl> <dbl>
#> 1 A      1.89 0.075       4  2.91
#> 2 B      1.56 0.036       2  3.34
```
