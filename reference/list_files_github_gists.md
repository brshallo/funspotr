# List Github Gists of User

Given a username, return a dataframe with paths to all the gists by that
user.

## Usage

``` r
list_files_github_gists(
  user,
  pattern = stringr::regex("(r|rmd|rmarkdown|qmd)$", ignore_case = TRUE)
)
```

## Arguments

- user:

  Character string of username whose github gists you want to pull.

- pattern:

  Regex pattern to keep only matching files. Default is
  `stringr::regex("(r|rmd|rmarkdown|qmd)$", ignore_case = TRUE)` which
  will keep only R, Rmarkdown and Quarto documents. If you have a lot of
  .md gists that can be converted to .R files you may want to edit this
  argument. To keep all files use `"."`.

## Value

Dataframe with `relative_paths` and `absolute_paths` of file paths.
Because gists do not exist in a folder structure `relative_paths` will
generally just be a file name. `absolute_paths` a url to the raw file.
See
[`unnest_results()`](https://brshallo.github.io/funspotr/reference/unnest_results.md)
for helper to put into an easier to read format.

## See also

[`list_files_github_repo()`](https://brshallo.github.io/funspotr/reference/list_files_github_repo.md),
[`list_files_wd()`](https://brshallo.github.io/funspotr/reference/list_files_wd.md)

## Examples

``` r
# \donttest{
library(dplyr)
library(funspotr)

# pulling and analyzing my R file github gists
gists_urls <- list_files_github_gists("brshallo", pattern = ".")

# Will just parse the first 2 files/gists
# Note that is easy to hit the API limit if have lots of gists
contents <- filter(gists_urls, str_detect_r_docs(absolute_paths)) %>%
  slice(1:2) %>%
  spot_funs_files()


contents %>%
  unnest_results()
#> # A tibble: 29 × 4
#>    funs      pkgs      relative_paths                  absolute_paths           
#>    <chr>     <chr>     <chr>                           <chr>                    
#>  1 library   base      find_in_files.R                 https://gist.githubuserc…
#>  2 dir_ls    fs        find_in_files.R                 https://gist.githubuserc…
#>  3 map       purrr     find_in_files.R                 https://gist.githubuserc…
#>  4 grep      base      find_in_files.R                 https://gist.githubuserc…
#>  5 readLines base      find_in_files.R                 https://gist.githubuserc…
#>  6 keep      purrr     find_in_files.R                 https://gist.githubuserc…
#>  7 length    base      find_in_files.R                 https://gist.githubuserc…
#>  8 library   base      rolling-mean-conditioned-date.R https://gist.githubuserc…
#>  9 seq       base      rolling-mean-conditioned-date.R https://gist.githubuserc…
#> 10 map       (unknown) rolling-mean-conditioned-date.R https://gist.githubuserc…
#> # ℹ 19 more rows
# }
```
