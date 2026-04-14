# Compute interval infiltration rates from cumulative data

Computes the mean infiltration rate over each consecutive time interval:
\$\$f_i = \frac{I_i - I\_{i-1}}{t_i - t\_{i-1}}\$\$

## Usage

``` r
infiltration_rate(data, time_col, infiltration_col)
```

## Arguments

- data:

  A data frame or tibble. Passed as the first argument so the function
  is compatible with `|>` and `%>%` pipes.

- time_col:

  Bare column name; elapsed time in seconds. For BeerKan data, use
  `.cumulative_time`.

- infiltration_col:

  Bare column name; cumulative infiltration depth (cm). Typically
  `.infiltration` from
  [`infiltration_cumulative()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/infiltration_cumulative.md)
  or
  [`beerkan_cumulative()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/beerkan_cumulative.md).

## Value

The input `data` as a tibble with two additional columns:

- `.rate` — mean infiltration rate over the interval (cm/s); `NA` for
  the first row within each group

- `.time_mid` — midpoint time of the interval (s); `NA` for the first
  row

## Details

The rate is assigned to the midpoint time of each interval. The first
row within each group has no preceding observation and returns `NA` for
both `.rate` and `.time_mid`.

The function is **group-aware**: if `data` is grouped with
[`dplyr::group_by()`](https://dplyr.tidyverse.org/reference/group_by.html),
differences are computed independently within each group using
[`dplyr::lag()`](https://dplyr.tidyverse.org/reference/lead-lag.html).

## Examples

``` r
library(tibble)
library(dplyr)

dat <- tibble(
  time   = seq(0, 300, 30),
  volume = c(95, 89, 86, 83, 80, 77, 74, 73, 71, 69, 67)
) |>
  infiltration_cumulative(time = time, volume = volume)

infiltration_rate(dat, time_col = time, infiltration_col = .infiltration)
#> # A tibble: 11 × 7
#>     time volume .sqrt_time .volume_infiltrated .infiltration    .rate .time_mid
#>    <dbl>  <dbl>      <dbl>               <dbl>         <dbl>    <dbl>     <dbl>
#>  1     0     95       0                      0         0     NA              NA
#>  2    30     89       5.48                   6         0.377  0.0126         15
#>  3    60     86       7.75                   9         0.566  0.00629        45
#>  4    90     83       9.49                  12         0.755  0.00629        75
#>  5   120     80      11.0                   15         0.943  0.00629       105
#>  6   150     77      12.2                   18         1.13   0.00629       135
#>  7   180     74      13.4                   21         1.32   0.00629       165
#>  8   210     73      14.5                   22         1.38   0.00210       195
#>  9   240     71      15.5                   24         1.51   0.00419       225
#> 10   270     69      16.4                   26         1.63   0.00419       255
#> 11   300     67      17.3                   28         1.76   0.00419       285
```
