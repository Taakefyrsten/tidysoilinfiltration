# Compute cumulative infiltration from time-volume series

Converts raw time–volume readings from a Minidisk or ring infiltrometer
into cumulative infiltration depth and its square root of time, ready
for downstream model fitting.

## Usage

``` r
infiltration_cumulative(data, time, volume, radius = 2.25)
```

## Arguments

- data:

  A data frame or tibble. Passed as the first argument so the function
  is compatible with `|>` and `%>%` pipes.

- time:

  Bare column name or scalar numeric; elapsed time in seconds.

- volume:

  Bare column name or scalar numeric; water volume in the reservoir
  (mL), decreasing as water infiltrates.

- radius:

  Disc or ring radius in cm. Defaults to `2.25`, the standard Minidisk
  Infiltrometer radius. Pass the actual ring radius for standard ring
  infiltrometers.

## Value

The input `data` as a tibble with three additional columns:

- `.sqrt_time` — square root of elapsed time (s^0.5)

- `.volume_infiltrated` — cumulative volume infiltrated from the start
  of the run (mL)

- `.infiltration` — cumulative infiltration depth (cm)

## Details

Cumulative infiltration is calculated as: \$\$I = \frac{V_0 - V}{\pi
r^2}\$\$ where \\V_0\\ is the initial volume (first observation within
each group), \\V\\ is the volume at time \\t\\, and \\r\\ is the disc or
ring radius.

The function is **group-aware**: if `data` is grouped with
[`dplyr::group_by()`](https://dplyr.tidyverse.org/reference/group_by.html),
the initial volume \\V_0\\ is taken as the first observation *within
each group*, so multiple samples can be processed in a single pipeline
step.

## References

Philip, J. R. (1957). The theory of infiltration: 4. Sorptivity and
algebraic infiltration equations. *Soil Science*, 84(3), 257–264.

## Examples

``` r
library(tibble)
library(dplyr)

# Single sample
minidisk <- tibble(
  time   = seq(0, 300, 30),
  volume = c(95, 89, 86, 83, 80, 77, 74, 73, 71, 69, 67)
)
infiltration_cumulative(minidisk, time = time, volume = volume)
#> # A tibble: 11 × 5
#>     time volume .sqrt_time .volume_infiltrated .infiltration
#>    <dbl>  <dbl>      <dbl>               <dbl>         <dbl>
#>  1     0     95       0                      0         0    
#>  2    30     89       5.48                   6         0.377
#>  3    60     86       7.75                   9         0.566
#>  4    90     83       9.49                  12         0.755
#>  5   120     80      11.0                   15         0.943
#>  6   150     77      12.2                   18         1.13 
#>  7   180     74      13.4                   21         1.32 
#>  8   210     73      14.5                   22         1.38 
#>  9   240     71      15.5                   24         1.51 
#> 10   270     69      16.4                   26         1.63 
#> 11   300     67      17.3                   28         1.76 

# Multiple samples via group_by — initial volume taken per group
multi <- tibble(
  sample = rep(c("A", "B"), each = 11),
  time   = rep(seq(0, 300, 30), 2),
  volume = c(95, 89, 86, 83, 80, 77, 74, 73, 71, 69, 67,
             83, 77, 64, 61, 58, 45, 42, 35, 29, 17, 15)
)
multi |>
  group_by(sample) |>
  infiltration_cumulative(time = time, volume = volume)
#> # A tibble: 22 × 6
#> # Groups:   sample [2]
#>    sample  time volume .sqrt_time .volume_infiltrated .infiltration
#>    <chr>  <dbl>  <dbl>      <dbl>               <dbl>         <dbl>
#>  1 A          0     95       0                      0         0    
#>  2 A         30     89       5.48                   6         0.377
#>  3 A         60     86       7.75                   9         0.566
#>  4 A         90     83       9.49                  12         0.755
#>  5 A        120     80      11.0                   15         0.943
#>  6 A        150     77      12.2                   18         1.13 
#>  7 A        180     74      13.4                   21         1.32 
#>  8 A        210     73      14.5                   22         1.38 
#>  9 A        240     71      15.5                   24         1.51 
#> 10 A        270     69      16.4                   26         1.63 
#> # ℹ 12 more rows

# Ring infiltrometer with 10 cm radius
ring <- tibble(time = seq(0, 600, 60), volume = 500 - seq(0, 200, 20))
infiltration_cumulative(ring, time = time, volume = volume, radius = 10)
#> # A tibble: 11 × 5
#>     time volume .sqrt_time .volume_infiltrated .infiltration
#>    <dbl>  <dbl>      <dbl>               <dbl>         <dbl>
#>  1     0    500       0                      0        0     
#>  2    60    480       7.75                  20        0.0637
#>  3   120    460      11.0                   40        0.127 
#>  4   180    440      13.4                   60        0.191 
#>  5   240    420      15.5                   80        0.255 
#>  6   300    400      17.3                  100        0.318 
#>  7   360    380      19.0                  120        0.382 
#>  8   420    360      20.5                  140        0.446 
#>  9   480    340      21.9                  160        0.509 
#> 10   540    320      23.2                  180        0.573 
#> 11   600    300      24.5                  200        0.637 
```
