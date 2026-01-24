# Check Packages Availability

Check whether packages are available in current library.

## Usage

``` r
check_pkgs_availability(pkgs, quietly = TRUE)
```

## Arguments

- pkgs:

  Character vector of package names. (Typically the output from
  [`spot_pkgs()`](https://brshallo.github.io/funspotr/reference/spot_pkgs.md)).

- quietly:

  logical: should progress and error messages be suppressed?

## Value

Named logical vector indicating whether each package is available on the
machine.

## Examples

``` r
library(funspotr)
library(dplyr)
#> 
#> Attaching package: ‘dplyr’
#> The following objects are masked from ‘package:stats’:
#> 
#>     filter, lag
#> The following objects are masked from ‘package:base’:
#> 
#>     intersect, setdiff, setequal, union

file_lines <- "
library(dplyr)
require(tidyr)
library(madeUpPkg)

as_tibble(mpg) %>%
  group_by(class) %>%
  nest() %>%
  mutate(stats = purrr::map(data,
                            ~lm(cty ~ hwy, data = .x)))

made_up_fun()
"

file_output <- tempfile(fileext = ".R")
writeLines(file_lines, file_output)

spot_pkgs(file_output) %>%
  check_pkgs_availability()
#>     dplyr     tidyr madeUpPkg     purrr 
#>      TRUE      TRUE     FALSE      TRUE 
```
