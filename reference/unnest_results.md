# Unnest Results

Run after running `list_files_*() |> spot_{funs|pkgs}_files()` to unnest
the `spotted` list-column.

## Usage

``` r
unnest_results(df)
```

## Arguments

- df:

  Dataframe outputted by `spot_{funs|pkgs}_files()` that contains a
  `spotted` list-column.

## Value

An unnested dataframe with what was in `spotted` moved to the front.

## See also

[`spot_funs_files()`](https://brshallo.github.io/funspotr/reference/spot_funs_files.md),
[`spot_pkgs_files()`](https://brshallo.github.io/funspotr/reference/spot_funs_files.md)

## Examples

``` r
# \donttest{
library(funspotr)
library(dplyr)

list_files_github_repo("brshallo/feat-eng-lags-presentation", branch = "main") %>%
  spot_funs_files() %>%
  unnest_results()
#>  ■■■■■■■■■■■■■■■■                  50% |  ETA:  1s
#> # A tibble: 114 × 4
#>    funs            pkgs      relative_paths            absolute_paths           
#>    <chr>           <chr>     <chr>                     <chr>                    
#>  1 purl            knitr     R/Rmd-to-R.R              https://raw.githubuserco…
#>  2 here            here      R/Rmd-to-R.R              https://raw.githubuserco…
#>  3 getOption       base      R/feat-engineering-lags.R https://raw.githubuserco…
#>  4 options         base      R/feat-engineering-lags.R https://raw.githubuserco…
#>  5 library         base      R/feat-engineering-lags.R https://raw.githubuserco…
#>  6 read_csv        (unknown) R/feat-engineering-lags.R https://raw.githubuserco…
#>  7 arrange         (unknown) R/feat-engineering-lags.R https://raw.githubuserco…
#>  8 mutate          (unknown) R/feat-engineering-lags.R https://raw.githubuserco…
#>  9 slide_index_dbl (unknown) R/feat-engineering-lags.R https://raw.githubuserco…
#> 10 days            (unknown) R/feat-engineering-lags.R https://raw.githubuserco…
#> # ℹ 104 more rows
# }
```
