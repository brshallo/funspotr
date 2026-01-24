# List Files in Github Repo

Return a dataframe containing the paths of files in a github repostiory.
Generally used prior to `spot_{funs/pkgs}_files()`.

## Usage

``` r
list_files_github_repo(
  repo,
  branch = NULL,
  pattern = stringr::regex("(r|rmd|rmarkdown|qmd)$", ignore_case = TRUE),
  rmv_index = TRUE
)
```

## Arguments

- repo:

  Github repository, e.g. "brshallo/feat-eng-lags-presentation"

- branch:

  Branch of github repository, default is "main".

- pattern:

  Regex pattern to keep only matching files. Default is
  `stringr::regex("(r|rmd|rmarkdown|qmd)$", ignore_case = TRUE)` which
  will keep only R, Rmarkdown and Quarto documents. To keep all files
  use `"."`.

- rmv_index:

  Logical, most repos containing blogdown sites will have an index.R
  file at the root. Change to `FALSE` if you don't want this file
  removed.

## Value

Dataframe with columns of `relative_paths` and `absolute_paths` for file
path locations. `absolute_paths` will be urls to raw files.

## See also

[`list_files_wd()`](https://brshallo.github.io/funspotr/reference/list_files_wd.md),
[`list_files_github_gists()`](https://brshallo.github.io/funspotr/reference/list_files_github_gists.md)

## Examples

``` r
# \donttest{
library(dplyr)
library(funspotr)

# pulling and analyzing my R file github gists
gh_urls <- list_files_github_repo("brshallo/feat-eng-lags-presentation", branch = "main")

# Will just parse the first 2 files/gists
contents <- spot_funs_files(slice(gh_urls, 1:2))

contents %>%
  unnest_results()
#> # A tibble: 75 × 4
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
#> # ℹ 65 more rows
# }
```
