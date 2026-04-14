# tidysoilinfiltration 1.0.0

Initial release.

## New functions

* `infiltration_cumulative()` — convert time–volume readings from Minidisk or
  ring infiltrometers to cumulative infiltration depth I(t) and √t. Fully
  group-aware.
* `beerkan_cumulative()` — convert BeerKan pour-event data (fixed volumes,
  infiltration times) to cumulative I(t). Group-aware via `cumsum()`.
* `infiltration_rate()` — compute mean interval infiltration rates and midpoint
  times from cumulative data. Group-aware.
* `fit_infiltration()` — fit the Philip (1957) two-term polynomial
  `I = C₂√t + C₁t` by OLS. Returns C₁ (conductivity proxy) and C₂
  (sorptivity proxy). Supports parallel fitting across groups.
* `infiltration_vg_params()` — look up Van Genuchten n, α, and A from the
  Decagon Devices (2005) table by texture class and suction. Pass `suction = 0`
  for BeerKan (shape parameters only; `.A` is `NA`).
* `parameter_A_zhang()` — compute the Zhang (1997) A parameter analytically
  from n, α, suction, and disc radius. Fully vectorised.
* `hydraulic_conductivity_minidisk()` — compute K(h) = C₁ / A.
* `fit_infiltration_horton()` — fit the Horton (1940) exponential rate decay
  model by NLS. Returns fc ≈ Ksat, f₀, k.
* `fit_infiltration_kostiakov()` — fit the Kostiakov (1932) power model
  `I = a t^b` by NLS. Returns a, b.
* `fit_best()` — implement the BEST algorithm (Lassabatère et al., 2006).
  Estimates Ks, S, and α from BeerKan cumulative data using the Haverkamp
  et al. (1994) quasi-exact implicit model. Three fitting methods: `"steady"`
  (default), `"slope"`, `"intercept"`. Supports parallel fitting.

## Datasets

* `minidisk_vg_params` — long-format tibble (96 rows × 5 columns) of Van
  Genuchten parameters n, α, and A for 12 USDA texture classes at 8 suction
  levels (0.5–7 cm). Source: Decagon Devices, Inc. (2005), via infiltrodiscR.

## Notes

* All functions are pipe-compatible (data frame as first argument, returns
  tibble) and use tidy evaluation for column arguments.
* Fully vectorised backends — no R-level loops — suitable for raster-scale
  workflows at millions of cells.
* Parallel fitting via `parallel::mclapply()` on Unix-like systems (`workers`
  argument on all `fit_*` functions).
