# Spot package dependencies from DESCRIPTION file

Given explicit path to DESCRIPTION file return package dependencies
therein. Inspiration:
[blogdown#647](https://stackoverflow.com/a/30225680/9059865).

## Usage

``` r
spot_pkgs_from_description(DESCRIPTION_path)
```

## Arguments

- DESCRIPTION_path:

  Path to DESCRIPTION file

## Value

Character vector of packages.

## Examples

``` r
funspotr::spot_pkgs_from_description(
  "https://raw.githubusercontent.com/brshallo/animatrixr/master/DESCRIPTION"
)
#> [1] "dplyr"      "purrr"      "ggplot2"    "gganimate"  "knitr"     
#> [6] "rmarkdown"  "datasauRus"
```
