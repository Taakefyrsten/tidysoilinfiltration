# Compute cumulative infiltration from BeerKan pour-event data

Converts raw BeerKan experiment data — where a fixed volume is poured
repeatedly and the time for each pour to infiltrate is recorded — into
cumulative I(t) pairs suitable for
[`fit_infiltration()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/fit_infiltration.md)
or
[`fit_best()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/fit_best.md).

## Usage

``` r
beerkan_cumulative(data, volume_col, time_col, radius)
```

## Arguments

- data:

  A data frame or tibble. Passed as the first argument so the function
  is compatible with `|>` and `%>%` pipes.

- volume_col:

  Bare column name; volume poured in each event (mL). The volume may
  vary between pours (e.g. 100 mL for most, 50 mL for the last).

- time_col:

  Bare column name; time for that pour to completely infiltrate
  (seconds).

- radius:

  Ring radius in cm. No default is provided because ring size varies;
  always pass the actual radius to avoid silent errors.

## Value

The input `data` as a tibble with four additional columns:

- `.cumulative_time` — cumulative infiltration time (s)

- `.sqrt_time` — square root of `.cumulative_time` (s^0.5); provided for
  compatibility with
  [`fit_infiltration()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/fit_infiltration.md)

- `.cumulative_volume` — cumulative volume infiltrated (mL)

- `.infiltration` — cumulative infiltration depth (cm)

## Details

The BeerKan protocol records data in the **inverted** direction compared
to standard ring and Minidisk experiments:

- **Standard / Minidisk**: volume measured at fixed time steps

- **BeerKan**: time measured for each fixed-volume pour to disappear

Cumulative quantities are computed as: \$\$t_i = \sum\_{j=1}^{i} \Delta
t_j\$\$ \$\$I_i = \frac{\sum\_{j=1}^{i} V_j}{\pi r^2}\$\$

The function is **group-aware**: if `data` is grouped with
[`dplyr::group_by()`](https://dplyr.tidyverse.org/reference/group_by.html),
cumulative sums are computed independently within each group (using
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
with [`cumsum()`](https://rdrr.io/r/base/cumsum.html)).

## References

Lassabatère, L., Angulo-Jaramillo, R., Soria Ugalde, J. M., Cuenca, R.,
Braud, I., & Haverkamp, R. (2006). Beerkan estimation of soil transfer
parameters through infiltration experiments—BEST. *Soil Science Society
of America Journal*, 70(2), 521–532.
<https://doi.org/10.2136/sssaj2005.0026>

## Examples

``` r
library(tibble)
library(dplyr)
#> 
#> Attaching package: ‘dplyr’
#> The following objects are masked from ‘package:stats’:
#> 
#>     filter, lag
#> The following objects are masked from ‘package:base’:
#> 
#>     intersect, setdiff, setequal, union

# Single BeerKan run — 100 mL poured each time
run <- tibble(
  pour   = 1:8,
  volume = 100,          # mL per pour (fixed)
  time   = c(12, 18, 24, 30, 34, 35, 35, 36)  # s to infiltrate
)
beerkan_cumulative(run, volume_col = volume, time_col = time, radius = 5)
#> # A tibble: 8 × 7
#>    pour volume  time .cumulative_time .sqrt_time .cumulative_volume
#>   <int>  <dbl> <dbl>            <dbl>      <dbl>              <dbl>
#> 1     1    100    12               12       3.46                100
#> 2     2    100    18               30       5.48                200
#> 3     3    100    24               54       7.35                300
#> 4     4    100    30               84       9.17                400
#> 5     5    100    34              118      10.9                 500
#> 6     6    100    35              153      12.4                 600
#> 7     7    100    35              188      13.7                 700
#> 8     8    100    36              224      15.0                 800
#> # ℹ 1 more variable: .infiltration <dbl>

# Multiple sites with group_by
runs <- tibble(
  site   = rep(c("S1", "S2"), each = 5),
  volume = 100,
  time   = c(10, 14, 18, 21, 22, 25, 35, 45, 50, 51)
)
runs |>
  group_by(site) |>
  beerkan_cumulative(volume_col = volume, time_col = time, radius = 5)
#> # A tibble: 10 × 7
#>    site  volume  time .cumulative_time .sqrt_time .cumulative_volume
#>    <chr>  <dbl> <dbl>            <dbl>      <dbl>              <dbl>
#>  1 S1       100    10               10       3.16                100
#>  2 S1       100    14               24       4.90                200
#>  3 S1       100    18               42       6.48                300
#>  4 S1       100    21               63       7.94                400
#>  5 S1       100    22               85       9.22                500
#>  6 S2       100    25               25       5                   100
#>  7 S2       100    35               60       7.75                200
#>  8 S2       100    45              105      10.2                 300
#>  9 S2       100    50              155      12.4                 400
#> 10 S2       100    51              206      14.4                 500
#> # ℹ 1 more variable: .infiltration <dbl>
```
