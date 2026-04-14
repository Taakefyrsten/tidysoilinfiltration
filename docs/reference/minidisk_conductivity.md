# Compute unsaturated hydraulic conductivity from Minidisk data

A convenience wrapper that combines
[`infiltration_vg_params()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/infiltration_vg_params.md)
and
[`hydraulic_conductivity_minidisk()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/hydraulic_conductivity_minidisk.md)
(and optionally
[`parameter_A_zhang()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/parameter_A_zhang.md))
into a single pipeline step. Given a data frame containing a Philip
\\C_1\\ coefficient (typically from
[`fit_infiltration()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/fit_infiltration.md)),
it looks up or computes the Van Genuchten A-parameter and returns
\\K(h)\\.

## Usage

``` r
minidisk_conductivity(
  data,
  texture,
  suction,
  C1,
  method = c("tabulated", "zhang"),
  radius = 2.25
)
```

## Arguments

- data:

  A data frame or tibble, typically the output of
  [`fit_infiltration()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/fit_infiltration.md)
  joined with sample metadata.

- texture:

  Bare column name or character scalar; USDA texture class (e.g.
  `"Sandy Loam"`). Must match the names in
  [minidisk_vg_params](https://taakefyrsten.github.io/tidysoilinfiltration/reference/minidisk_vg_params.md).

- suction:

  Bare column name or numeric scalar; applied suction in cm (e.g. `2`).
  Must be one of the tabulated levels (0.5, 1, 2, 3, 4, 5, 6, 7) when
  `method = "tabulated"`.

- C1:

  Bare column name; the Philip \\C_1\\ coefficient (cm/s). Defaults to
  `.C1` (the column produced by
  [`fit_infiltration()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/fit_infiltration.md)).

- method:

  `"tabulated"` (default) uses the Decagon lookup table; `"zhang"`
  computes A analytically from Zhang (1997).

- radius:

  Disc radius in cm. Only used when `method = "zhang"`. Defaults to
  `2.25`.

## Value

The input tibble with `.n`, `.alpha`, `.A`, and `.K_h` appended. When
`method = "zhang"` the `.A` column reflects the analytically computed
value rather than the tabulated one.

## Details

Two methods are available for the A-parameter:

- `"tabulated"`:

  Looks up A from the Decagon Devices (2005) reference table via
  [`infiltration_vg_params()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/infiltration_vg_params.md).
  Valid for the 8 standard Minidisk suction levels (0.5–7 cm) and 12
  USDA texture classes. The table assumes a disc radius of 2.25 cm.

- `"zhang"`:

  Computes A analytically from Zhang (1997) via
  [`parameter_A_zhang()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/parameter_A_zhang.md).
  Valid for any suction and disc radius; uses the \\n\\ and \\\alpha\\
  values from the VG lookup as inputs.

## References

Decagon Devices (2005). *Mini Disk Infiltrometer: User's Manual.*
Decagon Devices, Inc., Pullman, WA.

Zhang, R. (1997). Determination of soil sorptivity and hydraulic
conductivity from the disk infiltrometer. *Soil Science Society of
America Journal*, 61(4), 1024–1030.

## See also

[`infiltration_vg_params()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/infiltration_vg_params.md),
[`parameter_A_zhang()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/parameter_A_zhang.md),
[`hydraulic_conductivity_minidisk()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/hydraulic_conductivity_minidisk.md),
[`fit_infiltration()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/fit_infiltration.md)

## Examples

``` r
library(tibble)
library(dplyr)

# Minimal single-sample pipeline: raw data -> K(h) in four steps
minidisk <- tibble(
  time   = seq(0, 300, 30),
  volume = c(95, 89, 86, 83, 80, 77, 74, 73, 71, 69, 67),
  texture = "Sandy Loam",
  suction = 2
)

minidisk |>
  infiltration_cumulative(time = time, volume = volume) |>
  fit_infiltration(.infiltration, .sqrt_time) |>
  minidisk_conductivity(texture = texture, suction = suction)
#> Error: object 'texture' not found

# Multi-sample pipeline using group_by — no double group_by needed
multi <- tibble(
  sample  = rep(c("A", "B"), each = 11),
  time    = rep(seq(0, 300, 30), 2),
  volume  = c(95, 89, 86, 83, 80, 77, 74, 73, 71, 69, 67,
              83, 77, 74, 71, 68, 65, 62, 59, 57, 55, 53),
  texture = rep(c("Sandy Loam", "Loam"), each = 11),
  suction = 2
)

multi |>
  group_by(sample) |>
  infiltration_cumulative(time = time, volume = volume) |>
  fit_infiltration(.infiltration, .sqrt_time) |>
  minidisk_conductivity(texture = texture, suction = suction)
#> Error: object 'texture' not found

# Analytical A via Zhang (1997)
minidisk |>
  infiltration_cumulative(time = time, volume = volume) |>
  fit_infiltration(.infiltration, .sqrt_time) |>
  minidisk_conductivity(texture = texture, suction = suction,
                        method = "zhang", radius = 2.25)
#> Error: object 'texture' not found
```
