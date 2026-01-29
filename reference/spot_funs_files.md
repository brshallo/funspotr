# Spot Packages or Functions in dataframe of Paths

`spot_pkgs_files()` : Spot all packages that show-up in R or Rmarkdown
or quarto documents in a dataframe of filepaths.

`spot_funs_files()` : Spot all functions and their corresponding
packages that show-up in R or Rmarkdown or quarto documents in a
dataframe of filepaths.

## Usage

``` r
spot_funs_files(df, ..., .progress = TRUE)

spot_pkgs_files(df, ..., .progress = TRUE)
```

## Arguments

- df:

  Dataframe containing a column of `absolute_paths`.

- ...:

  Arguments passed onto `spot_{pkgs|funs}()`.

- .progress:

  Whether to show a progress bar. Use `TRUE` to a turn on a basic
  progress bar, use a string to give it a name, or see
  [progress_bars](https://purrr.tidyverse.org/reference/progress_bars.html)
  for more details.

## Value

Dataframe with `relative_paths` and `absolute_paths` of file paths along
with a list-column `spotted` containing
[`purrr::safely()`](https://purrr.tidyverse.org/reference/safely.html)
named list of "result" and "error" for each file parsed. Use
[`unnest_results()`](https://brshallo.github.io/funspotr/reference/unnest_results.md)
to unnest only the "result" values.

## Details

A [`purrr::safely()`](https://purrr.tidyverse.org/reference/safely.html)
wrapper for mapping
[`spot_pkgs()`](https://brshallo.github.io/funspotr/reference/spot_pkgs.md)
or
[`spot_funs()`](https://brshallo.github.io/funspotr/reference/spot_funs.md)
across multiple filepaths. I.e. even if some files fail to parse the
function will continue on.

Default settings are meant for files where package libraries are
referenced *within* the files themselves. See README for more details.

## See also

[`spot_pkgs()`](https://brshallo.github.io/funspotr/reference/spot_pkgs.md),
[`spot_funs()`](https://brshallo.github.io/funspotr/reference/spot_funs.md),
[`unnest_results()`](https://brshallo.github.io/funspotr/reference/unnest_results.md)

## Examples

``` r
# \donttest{
library(funspotr)
library(dplyr)

list_files_github_repo("brshallo/feat-eng-lags-presentation", branch = "main") %>%
  spot_funs_files()
#> # A tibble: 4 × 3
#>   relative_paths                absolute_paths                      spotted     
#>   <chr>                         <chr>                               <list>      
#> 1 R/Rmd-to-R.R                  https://raw.githubusercontent.com/… <named list>
#> 2 R/feat-engineering-lags.R     https://raw.githubusercontent.com/… <named list>
#> 3 R/load-inspections-save-csv.R https://raw.githubusercontent.com/… <named list>
#> 4 R/types-of-splits.R           https://raw.githubusercontent.com/… <named list>
# }
```
