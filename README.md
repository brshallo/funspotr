
<!-- README.md is generated from README.Rmd. Please edit that file -->

# funspotr

<!-- badges: start -->
<!-- badges: end -->

The goal of funspotr is to make it easy to identify which functions and
associated packages are used in files.

Currently `{funspotr}` cannot disambiguate when function names are
shared beween package dependencies and may not identify *every* function
in a script. See [Limitations, Problems,
Musings](#limitations-problems-musings) (or read the source code).

## Spot functions in a file

The foundational function in `{funspotr}` is `spot_funs()` which returns
a dataframe showing the functions and associated packages used in a
single file.

``` r
library(funspotr)
library(dplyr)

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

# Notice is not able to determine singular package for as_tibble()
# See [Limitations...] for more
spot_funs(file_path = file_output)
#> # A tibble: 10 x 3
#>    funs        pkgs      in_multiple_pkgs
#>    <chr>       <chr>     <lgl>           
#>  1 as_tibble   tidyr     TRUE            
#>  2 as_tibble   dplyr     TRUE            
#>  3 made_up_fun (unknown) FALSE           
#>  4 library     base      FALSE           
#>  5 require     base      FALSE           
#>  6 group_by    dplyr     FALSE           
#>  7 mutate      dplyr     FALSE           
#>  8 map         purrr     FALSE           
#>  9 lm          stats     FALSE           
#> 10 nest        tidyr     FALSE
```

`spot_funs_custom()` allows the user to explicitly specify `pkgs` where
functions may come from. This is useful in cases where the packages
loaded are not in the same location as the `file_path` (e.g. they are
loaded via `source()` or a DESCRIPTION file, or some other workflow).

<!-- The example below uses `spot_pkgs_from_DESCRIPTION()` to load in package dependencies and then passes the resulting character vector to `spot_funs_custom()`. -->

For example, let’s check which functions go into creating the functions
written in one of the R files in `{funspotr}`:

``` r
funspotr_deps <- spot_pkgs_from_DESCRIPTION("https://raw.githubusercontent.com/brshallo/funspotr/main/DESCRIPTION")

# using dplyr::filter() to remove functions created in {funspotr}
spot_funs_custom(
  pkgs = funspotr_deps,
  file_path = "https://raw.githubusercontent.com/brshallo/funspotr/main/R/spot-funs.R"
  ) %>% 
  dplyr::filter(pkgs != "(unknown)")
#> # A tibble: 30 x 3
#>    funs      pkgs   in_multiple_pkgs
#>    <chr>     <chr>  <lgl>           
#>  1 tibble    tibble TRUE            
#>  2 tibble    tidyr  TRUE            
#>  3 tibble    dplyr  TRUE            
#>  4 all       base   FALSE           
#>  5 c         base   FALSE           
#>  6 character base   FALSE           
#>  7 ifelse    base   FALSE           
#>  8 lapply    base   FALSE           
#>  9 list      base   FALSE           
#> 10 logical   base   FALSE           
#> # ... with 20 more rows
```

## Spot functions in a github repo

`github_spot_funs()` identifies the R and Rmarkdown files in a github
repository and then maps `spot_funs()` across all file URLs, outputting
the results to a `spotted` list-column in a dataframe.

``` r
# repo for an old presentation
gh_ex <- github_spot_funs(
  repo = "brshallo/feat-eng-lags-presentation", 
  branch = "main")

gh_ex
#> # A tibble: 4 x 3
#>   contents                      urls                                 spotted    
#>   <chr>                         <chr>                                <list>     
#> 1 R/Rmd-to-R.R                  https://raw.githubusercontent.com/b~ <tibble [2~
#> 2 R/feat-engineering-lags.R     https://raw.githubusercontent.com/b~ <tibble [8~
#> 3 R/load-inspections-save-csv.R https://raw.githubusercontent.com/b~ <tibble [2~
#> 4 R/types-of-splits.R           https://raw.githubusercontent.com/b~ <tibble [2~
```

These results may then be unnested to provide a table of which functions
and packages are used in each file.

``` r
gh_ex %>% 
  dplyr::relocate(spotted) %>% 
  tidyr::unnest(spotted) %>% 
  dplyr::arrange(pkgs, contents)
#> # A tibble: 128 x 5
#>    funs               pkgs      in_multiple_pkgs contents                  urls 
#>    <chr>              <chr>     <lgl>            <chr>                     <chr>
#>  1 extract_dates_rset (unknown) FALSE            R/feat-engineering-lags.R http~
#>  2 plot_dates_rset    (unknown) FALSE            R/feat-engineering-lags.R http~
#>  3 where              (unknown) FALSE            R/feat-engineering-lags.R http~
#>  4 c                  base      FALSE            R/feat-engineering-lags.R http~
#>  5 getOption          base      FALSE            R/feat-engineering-lags.R http~
#>  6 is.na              base      FALSE            R/feat-engineering-lags.R http~
#>  7 library            base      FALSE            R/feat-engineering-lags.R http~
#>  8 list               base      FALSE            R/feat-engineering-lags.R http~
#>  9 max                base      FALSE            R/feat-engineering-lags.R http~
#> 10 options            base      FALSE            R/feat-engineering-lags.R http~
#> # ... with 118 more rows
```

You can set `preview = TRUE` in `github_spot_funs()` to first view the
files you intend to parse. (This is particularly helpful to start with
in repositories with many files where it will take a while to run.)

``` r
github_spot_funs(
  repo = "brshallo/feat-eng-lags-presentation", 
  branch = "main",
  preview = TRUE)
#> # A tibble: 4 x 2
#>   contents                      urls                                            
#>   <chr>                         <chr>                                           
#> 1 R/Rmd-to-R.R                  https://raw.githubusercontent.com/brshallo/feat~
#> 2 R/feat-engineering-lags.R     https://raw.githubusercontent.com/brshallo/feat~
#> 3 R/load-inspections-save-csv.R https://raw.githubusercontent.com/brshallo/feat~
#> 4 R/types-of-splits.R           https://raw.githubusercontent.com/brshallo/feat~
```

## Files you didn’t write

Functions created in a file and functions from unavailable packages will
output as `pkgs = "(unknown)"`. *To spot which package a function is
from you must have the package installed locally.*

Hence for files on other peoples’ github repositories or that you
created on a different machine, it is a good idea to start with
`funspotr::check_pkgs_availability()` to see which packages you may be
missing.
`check_pkgs_availability(file_path) %>% funspotr:::install_missing_pkgs()`
is a quick helper for installing missing packages (see “R/spot-pkgs.R”
for documentation).

Alternatively, you may want to clone the repository locally and then use
`renv::dependencies()` to identify and install the package dependencies
to your local repository (see [{renv}](https://rstudio.github.io/renv/)
for documentation) and only then start using `{funspotr}`. (`{renv}` is
a more robust approach than using the `{funspotr}` functions and is
particular important in cases where you are missing many dependencies or
don’t want to alter the packages in your global library).

# Other Things

**Helper for `{blogdown}` tags:**

`spot_pkgs()` has an argument for `as_yaml_tags` that flattens the
dependencies and outputs them in a format that can be pasted into the
**tags** section of a blogdown post’s YAML header. See
([blogdown\#647](https://github.com/rstudio/blogdown/issues/647)).

``` r
# Example from old blogdown post
spot_pkgs(
  file_path = "https://raw.githubusercontent.com/brshallo/brshallo/master/content/post/2020-02-06-maximizing-magnetic-volume-the-perfect-bowl.Rmd",
  as_yaml_tags = TRUE)
#>   - ggforce
#>   - knitr
#>   - tidyverse
```

**Unexported functions:**

Many of the unexported functions (in “R/github-spot.R” in particular)
may be helpful in building up other workflows for mapping `spot_funs()`
across multiple files. (Most unexported functions in `funspotr` still
include documentation). *If you have a suggestion for a function or set
of functions for spotting functions, feel free to open an issue.*

<!-- **If you've used {funspotr} to map the R functions and packages of a public blog or repository, open an issue to add a link in the README.** -->

## Limitations, Problems, Musings

-   As mentioned elsewhere, the default parsing of `spot_funs()` and
    functions that build on this is primarily for cases where package
    dependencies are loaded in the same file that they are used in
    (i.e. in interactive scripts or notebooks where you use `library()`
    or related calls within the script). Scripts that are not
    self-contained typically require passing in a `pkgs` argument
    explicitly to `spot_funs_custom()`.
-   Feel free to open an issue if you’d be interested in a simplifying
    function or vignette for mapping `spot_funs()` through local repos
    or other folder structures outside of github repos containing
    largely self-contained files as in `github_spot_funs()`. E.g. for
    mapping across a local repository, across a package, a data
    workflow, etc.
-   All the functions in “R/spot-pkgs.R” would be better handled by
    something like `renv::dependencies()` or a parsing based approach.
    The simple regex’s I use have a variety of problems. As just one
    example `funspotr::get_pkgs()` will not recognize when a package is
    within quotes or being escaped, e.g. in this case
    `lines <- "library(pkg)"` the `pkg` would show-up as a dependency
    despite just being part of a quote rather than actually loaded.
-   The foundation of “R/spot-funs.R” is
    `NCmisc::list.functions.in.file()` which would likely be better if
    instead handled by however `R CMD check` does function parsing.
    -   The current approach is much slower than `R CMD check`
    -   `NCmisc::list.functions.in.file()` does not properly consider
        namespaces – making the `in_multiple_pkgs` column in the output
        of `spot_funs()` necessary in cases of ambigugity (a better
        handling of namespaces should obviate the need for this column).
        -   Even when there is an explicit call to a function
            (e.g. `pkg::fun()`), `NCmisc::list.functions.in.file()` will
            not know `fun` is coming from `pkg` specifically if there is
            another package loaded elsewhere that also contains a
            function named `fun()`
    -   Does not identify infix operators, e.g. `+` (maybe this is fine
        though)
-   `funspotr` has LOTS of dependencies
-   It may have made more sense to have `github_get_funs()` clone the
    repo locally rather than pointing to URL’s to parse each file.

## Installation

You can install the development version of funspotr from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("brshallo/funspotr")
```
