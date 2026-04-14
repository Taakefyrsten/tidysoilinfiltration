# Package index

## Minidisk — tension-disc infiltrometer

Process Minidisk time–volume readings and compute K(h) via Zhang (1997)

- [`infiltration_cumulative()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/infiltration_cumulative.md)
  : Compute cumulative infiltration from time-volume series
- [`fit_infiltration()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/fit_infiltration.md)
  : Fit the Philip two-term infiltration model
- [`infiltration_vg_params()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/infiltration_vg_params.md)
  : Look up Van Genuchten parameters from the Minidisk reference table
- [`parameter_A_zhang()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/parameter_A_zhang.md)
  : Compute the Zhang (1997) A parameter for Minidisk analysis
- [`hydraulic_conductivity_minidisk()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/hydraulic_conductivity_minidisk.md)
  : Compute unsaturated hydraulic conductivity from Minidisk data

## Ring infiltration — ponded methods

Analyse standard ponded ring data with Philip, Horton, and Kostiakov
models

- [`infiltration_rate()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/infiltration_rate.md)
  : Compute interval infiltration rates from cumulative data
- [`fit_infiltration_horton()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/fit_infiltration_horton.md)
  : Fit the Horton (1940) infiltration rate model
- [`fit_infiltration_kostiakov()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/fit_infiltration_kostiakov.md)
  : Fit the Kostiakov (1932) cumulative infiltration model

## BeerKan — BEST algorithm

Process BeerKan pour-event data and fit the BEST algorithm

- [`beerkan_cumulative()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/beerkan_cumulative.md)
  : Compute cumulative infiltration from BeerKan pour-event data
- [`fit_best()`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/fit_best.md)
  : Fit the BEST algorithm to BeerKan cumulative infiltration data

## Data

Built-in reference datasets

- [`minidisk_vg_params`](https://taakefyrsten.github.io/tidysoilinfiltration/reference/minidisk_vg_params.md)
  : Van Genuchten parameters for Minidisk Infiltrometer analysis
