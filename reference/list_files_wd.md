# List Files in Working Directory

Return a dataframe containing the paths of files in the working
directory. Generally used prior to `spot_{funs/pkgs}_files()`.

## Usage

``` r
list_files_wd(
  path = ".",
  pattern = stringr::regex("(r|rmd|rmarkdown|qmd)$", ignore_case = TRUE),
  rmv_index = TRUE
)
```

## Arguments

- path:

  Character vector or path. Default is "." which will set the starting
  location for `relative_paths`.

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

Dataframe with columns of `relative_paths` and `absolute_paths`.

## Details

Can also be used outside of working directory if `path` is specified.

## See also

[`list_files_github_repo()`](https://brshallo.github.io/funspotr/reference/list_files_github_repo.md),
[`list_files_github_gists()`](https://brshallo.github.io/funspotr/reference/list_files_github_gists.md)

## Examples

``` r
# \donttest{
library(dplyr)
library(funspotr)

# pulling and analyzing my R file github gists
files_local <- list_files_wd()

# Will just parse the first 2 files/gists
contents <- spot_funs_files(slice(files_local, 2:3))

contents %>%
  unnest_results()
#> # A tibble: 0 × 3
#> # ℹ 3 variables: pkgs <???>, relative_paths <fs::path>, absolute_paths <chr>
# }
```
