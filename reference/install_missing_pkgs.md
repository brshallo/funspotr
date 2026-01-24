# Install Missing Packages From CRAN

Attempt to install missing packages from CRAN. In most cases, it is
safer to clone and use `renv::dependencies()`. See README for example.
You should first verify packages specified are available on CRAN,
otherwise will error.

## Usage

``` r
install_missing_pkgs(pkgs_availability)
```

## Arguments

- pkgs_availability:

  Named logical vector where names are packages – generally the output
  of running
  [`check_pkgs_availability()`](https://brshallo.github.io/funspotr/reference/check_pkgs_availability.md).

## Value

Installs packages from cran using
[`remotes::install_cran()`](https://remotes.r-lib.org/reference/install_cran.html)
if available, else
[`install.packages()`](https://rdrr.io/r/utils/install.packages.html)

## Examples

``` r
if (FALSE) { # \dontrun{
library(funspotr)
library(dplyr)

file_lines <- "
library(dplyr)
require(tidyr)

as_tibble(mpg) %>%
  group_by(class) %>%
  nest() %>%
  mutate(stats = purrr::map(data,
                            ~lm(cty ~ hwy, data = .x)))

"

file_output <- tempfile(fileext = '.R')
writeLines(file_lines, file_output)

spot_pkgs(file_output) %>%
  check_pkgs_availability() %>%
  install_missing_pkgs()
} # }
```
