
<!-- README.md is generated from README.Rmd. Please edit that file -->

# funspotr

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

The goal of funspotr is to make it easy to identify which functions and
packages are used in files. It was initially written to map out the
functions and packages used in a few popular github repositories (see
[brshallo/funspotr-examples](https://github.com/brshallo/funspotr-examples)).

funspotr is primarily designed for self-contained scripts (see [Package
dependencies in another file](#package-dependencies-in-another-file)).
Also, it may not identify *every* function and/or package (see
[Limitations, Problems, Musings](#limitations-problems-musings)) or read
the source code for details.

## Spot functions in a file

The primary function in funspotr is `spot_funs()` which returns a
dataframe showing the functions and associated packages used in a file.

``` r
library(funspotr)
library(dplyr)

file_lines <- "
library(dplyr)
require(tidyr)

as_tibble(mpg) %>% 
  mutate(class = as.character(class)) %>%
  group_by(class) %>%
  nest() %>%
  mutate(stats = purrr::map(data,
                            ~lm(cty ~ hwy, data = .x)))
 
made_up_fun()
"

file_output <- tempfile(fileext = ".R")
writeLines(file_lines, file_output)

spot_funs(file_path = file_output)
#> # A tibble: 10 x 3
#>    funs         pkgs      in_multiple_pkgs
#>    <chr>        <chr>     <lgl>           
#>  1 library      base      FALSE           
#>  2 require      base      FALSE           
#>  3 as_tibble    tidyr     TRUE            
#>  4 mutate       dplyr     FALSE           
#>  5 as.character base      FALSE           
#>  6 group_by     dplyr     FALSE           
#>  7 nest         tidyr     FALSE           
#>  8 map          purrr     FALSE           
#>  9 lm           stats     FALSE           
#> 10 made_up_fun  (unknown) FALSE
```

-   `funs`: function used in script
-   `pkgs`: best guess as to the package it came from
-   `in_multiple_pkgs` : Whether the function has multiple
    packages/environments on it’s (guessed) search space. By default
    only the package at the top of the search space is returned[1].

<!-- The example below uses `spot_pkgs_from_DESCRIPTION()` to load in package dependencies and then passes the resulting character vector to `spot_funs_custom()`. -->

## Spot functions in a github repo

`github_spot_funs()` is a wrapper on `spot_funs()` that maps it across
all R or Rmarkdown files in a github repository.

``` r
# repo for an old presentation I gave
gh_ex <- github_spot_funs(
  repo = "brshallo/feat-eng-lags-presentation", 
  branch = "main")
#> Error in file(file, ifelse(append, "a", "w")) : 
#>   cannot open the connection
#> Error in file(file, ifelse(append, "a", "w")) : 
#>   cannot open the connection
#> Error in file(file, ifelse(append, "a", "w")) : 
#>   cannot open the connection
#> Error in file(file, ifelse(append, "a", "w")) : 
#>   cannot open the connection

gh_ex
#> # A tibble: 4 x 3
#>   contents                      urls                                  spotted   
#>   <chr>                         <chr>                                 <list>    
#> 1 R/Rmd-to-R.R                  https://raw.githubusercontent.com/br~ <named li~
#> 2 R/feat-engineering-lags.R     https://raw.githubusercontent.com/br~ <named li~
#> 3 R/load-inspections-save-csv.R https://raw.githubusercontent.com/br~ <named li~
#> 4 R/types-of-splits.R           https://raw.githubusercontent.com/br~ <named li~
```

-   `contents` : filepath in github repo
-   `urls`: URL to raw file on github
-   `spotted`: `purrr::safely()` style list-column of results when
    mapping `spot_funs()` across `urls`[2].

These results may then be unnested with the helper
`funspotr::unnest_github_results()` to provide a table of which
functions and packages are used. This can be manipulated like any other
dataframe – say we want to filter to those files where
[here](https://here.r-lib.org/), [readr](https://readr.tidyverse.org/)
or [rsample](https://rsample.tidymodels.org/) packages are used.

``` r
gh_ex %>% 
  unnest_github_results() %>% 
  filter(pkgs %in% c("here", "readr", "rsample"))
#> # A tibble: 8 x 5
#>   funs               pkgs    in_multiple_pkgs contents      urls                
#>   <chr>              <chr>   <lgl>            <chr>         <chr>               
#> 1 here               here    FALSE            R/Rmd-to-R.R  https://raw.githubu~
#> 2 read_csv           readr   FALSE            R/feat-engin~ https://raw.githubu~
#> 3 initial_time_split rsample TRUE             R/feat-engin~ https://raw.githubu~
#> 4 training           rsample TRUE             R/feat-engin~ https://raw.githubu~
#> 5 testing            rsample TRUE             R/feat-engin~ https://raw.githubu~
#> 6 sliding_period     rsample TRUE             R/feat-engin~ https://raw.githubu~
#> 7 write_csv          readr   FALSE            R/load-inspe~ https://raw.githubu~
#> 8 here               here    FALSE            R/load-inspe~ https://raw.githubu~
```

You can set `preview = TRUE` in `github_spot_funs()` to first view the
files you intend to parse.

``` r
preview_files <- github_spot_funs(
  repo = "brshallo/feat-eng-lags-presentation", 
  branch = "main",
  preview = TRUE)

preview_files
#> # A tibble: 4 x 2
#>   contents                      urls                                            
#>   <chr>                         <chr>                                           
#> 1 R/Rmd-to-R.R                  https://raw.githubusercontent.com/brshallo/feat~
#> 2 R/feat-engineering-lags.R     https://raw.githubusercontent.com/brshallo/feat~
#> 3 R/load-inspections-save-csv.R https://raw.githubusercontent.com/brshallo/feat~
#> 4 R/types-of-splits.R           https://raw.githubusercontent.com/brshallo/feat~
```

You can pass in a custom set of urls by inputting a dataframe to the
argument `custom_urls` – this may be the output of a previous call where
`preview = TRUE`. For examle, say we only want to parse the
“types-of-splits.R” and “Rmd-to-R.R” files.

``` r
preview_files %>% 
  filter(stringr::str_detect(contents, "types-of-splits|Rmd-to-R")) %>% 
  github_spot_funs(custom_urls = .) %>% 
  unnest_github_results()
#> Error in file(file, ifelse(append, "a", "w")) : 
#>   cannot open the connection
#> Error in file(file, ifelse(append, "a", "w")) : 
#>   cannot open the connection
#> # A tibble: 24 x 5
#>    funs      pkgs      in_multiple_pkgs contents            urls                
#>    <chr>     <chr>     <lgl>            <chr>               <chr>               
#>  1 purl      knitr     FALSE            R/Rmd-to-R.R        https://raw.githubu~
#>  2 here      here      FALSE            R/Rmd-to-R.R        https://raw.githubu~
#>  3 library   base      FALSE            R/types-of-splits.R https://raw.githubu~
#>  4 theme_set ggplot    FALSE            R/types-of-splits.R https://raw.githubu~
#>  5 theme_bw  ggplot    FALSE            R/types-of-splits.R https://raw.githubu~
#>  6 set.seed  base      FALSE            R/types-of-splits.R https://raw.githubu~
#>  7 tibble    dplyr     TRUE             R/types-of-splits.R https://raw.githubu~
#>  8 rep       base      FALSE            R/types-of-splits.R https://raw.githubu~
#>  9 today     lubridate FALSE            R/types-of-splits.R https://raw.githubu~
#> 10 days      lubridate FALSE            R/types-of-splits.R https://raw.githubu~
#> # ... with 14 more rows
```

## Files you didn’t write

Functions created in the file as well as functions from unavailable
packages (or packages that don’t exist) will output as
`pkgs = "(unknown)"`.

``` r
file_lines_missing_pkgs <- "
library(dplyr)

as_tibble(mpg)

hello_world <- function() print('hello world')

madeuppkg::made_up_fun()

hello_world()
"

missing_pkgs_ex <- tempfile(fileext = ".R")
writeLines(file_lines_missing_pkgs, missing_pkgs_ex)

spot_funs(file_path = missing_pkgs_ex)
#> # A tibble: 5 x 3
#>   funs        pkgs      in_multiple_pkgs
#>   <chr>       <chr>     <lgl>           
#> 1 library     base      FALSE           
#> 2 as_tibble   dplyr     FALSE           
#> 3 print       base      FALSE           
#> 4 made_up_fun (unknown) FALSE           
#> 5 hello_world (unknown) FALSE
```

*To spot which package a function is from you must have the package
installed locally.* Hence for files on others’ github repos or that you
created on a different machine, it is a good idea to start with
`funspotr::check_pkgs_availability()` to see which packages you are
missing.

A quick helper for installing missing packages (see “R/spot-pkgs.R” for
documentation):

``` r
check_pkgs_availability(file_path) %>% 
  funspotr:::install_missing_pkgs()
```

Alternatively, you may want to clone the repository locally and then use
`renv::dependencies()` and only then start using funspotr.
[renv](https://rstudio.github.io/renv/) is a more robust approach to
finding and installing dependencies – particularly in cases where you
are missing many dependencies or don’t want to alter the packages in
your global library.

# Other Things

## Package dependencies in another file

`spot_funs()` is currently set-up for self-contained files. But
`spot_funs_custom()` allows the user to explicitly specify `pkgs` where
functions may come from. This is useful in cases where the packages
loaded are not in the same location as the `file_path` (e.g. they are
loaded via `source()` or a DESCRIPTION file, or some other workflow).
For example, below is a made-up example where the `library()` calls are
made in a separate file and `source()`d in.

``` r
# file where packages are loaded
file_libs <- "library(dplyr)
library(lubridate)"

file_libs_output <- tempfile(fileext = ".R")
writeLines(file_libs, file_libs_output)

# File of interest where things happen
file_run <- glue::glue(
"source('{ file_libs_output }')
  
tibble::tibble(days_from_today = 0:10) %>% 
    mutate(date = today() + days(days_from_today))
", 
file_libs_output = stringr::str_replace_all(file_libs_output, "\\\\", "/")
)

file_run_output <- tempfile(fileext = ".R")
writeLines(file_run, file_run_output)

# Identify packages using both files and then pass in explicitly to `spot_funs_custom()`
pkgs <- c(spot_pkgs(file_libs_output), 
          spot_pkgs(file_run_output, show_explicit_funs = TRUE))

spot_funs_custom(
  pkgs = pkgs,
  file_path = file_run_output)
#> # A tibble: 5 x 3
#>   funs   pkgs      in_multiple_pkgs
#>   <chr>  <chr>     <lgl>           
#> 1 source base      FALSE           
#> 2 tibble tibble    TRUE            
#> 3 mutate dplyr     FALSE           
#> 4 today  lubridate FALSE           
#> 5 days   lubridate FALSE
```

## Show all function calls

Passing in `show_each_use = TRUE` to `...` in `get_funs()` or
`github_spot_funs()` will return *all* instances of a function call
rather than just once for each file.

Compared to the initial example, `mutate()` now shows-up at both rows 4
and 8:

``` r
spot_funs(file_path = file_output, show_each_use = TRUE)
#> # A tibble: 11 x 3
#>    funs         pkgs      in_multiple_pkgs
#>    <chr>        <chr>     <lgl>           
#>  1 library      base      FALSE           
#>  2 require      base      FALSE           
#>  3 as_tibble    tidyr     TRUE            
#>  4 mutate       dplyr     FALSE           
#>  5 as.character base      FALSE           
#>  6 group_by     dplyr     FALSE           
#>  7 nest         tidyr     FALSE           
#>  8 mutate       dplyr     FALSE           
#>  9 map          purrr     FALSE           
#> 10 lm           stats     FALSE           
#> 11 made_up_fun  (unknown) FALSE
```

## Helper for [blogdown](https://pkgs.rstudio.com/blogdown/) tags

Setting `as_yaml_tags = TRUE` in `spot_pkgs()` flattens the dependencies
and outputs them in a format that can be pasted into the **tags**
section of a blogdown post’s YAML header. See
([blogdown\#647](https://github.com/rstudio/blogdown/issues/647)).

``` r
# Example from old blogdown post
spot_pkgs(
  file_path = "https://raw.githubusercontent.com/brshallo/brshallo/master/content/post/2020-02-06-maximizing-magnetic-volume-the-perfect-bowl.Rmd",
  as_yaml_tags = TRUE)
#>   - knitr
#>   - tidyverse
#>   - ggforce
```

## Unexported functions

Many of the unexported functions (in “R/github-spot.R” in particular)
may be helpful in building up other workflows for mapping `spot_funs()`
across multiple files. (Most unexported functions in `funspotr` still
include documentation). *If you have a suggestion for a function or set
of functions for spotting functions, feel free to open an issue.*

<!-- **If you've used {funspotr} to map the R functions and packages of a public blog or repository, open an issue to add a link in the README.** -->

# How `funspotr::spot_funs()` works

At a high-level…

1.  Create a new R instance using
    [callr](https://github.com/r-lib/callr)
2.  Load packages. Explicit calls (e.g. `pkg::fun()`) are loaded
    individually via [import](https://github.com/rticulate/import) and
    are loaded last (putting them at the top of the search space)[3].

(steps 1 and 2 needed so that step 4 has the best chance of identifying
the package a function comes from in the file.)

3.  Pass file through `utils::getParseData()` and filter to just
    functions (inspired by `NCmisc::list.functions.in.file()`)
4.  Pass functions through `utils::find()` to identify associated
    package

# Limitations, Problems, Musings

-   If a file contains R syntax that is not well defined it will not be
    parsed and return an error. See
    [formatR](https://yihui.org/formatr/#6-further-notes) (used by
    {funspotr} in parsing) for other common reasons for failure.
-   `knitr::read_chunk()` and `knitr::purl()` in a file passed to
    {funspotr} will also frequently cause an error in parsing. See
    [knitr\#1753](https://github.com/yihui/knitr/issues/1753) &
    [knitr\#1938](https://github.com/yihui/knitr/issues/1938)
-   Please open an issue if you find other cases where it breaks :-) .
-   As mentioned elsewhere, the default parsing of `spot_funs()` is
    primarily for cases where package dependencies are loaded in the
    same file that they are used in[4]. Scripts that are not
    self-contained typically should have the `pkgs` argument provided
    explicitly via `spot_funs_custom()`.
-   Feel free to open an issue if you’d be interested in a simplifying
    function or vignette for mapping `spot_funs()` through local repos
    or other folder structures other than github respositories (which is
    already covered in `github_spot_funs()`)[5]
-   All the functions in “R/spot-pkgs.R” would probably be better
    handled by something like `renv::dependencies()` or a parsing based
    approach. The simple regex’s I use have a variety of problems. As
    just one example `funspotr::get_pkgs()` will not recognize when a
    package is within quotes or being escaped[6].
-   I am curiuos if there is something to be learned from how
    `R CMD check` does function parsing.
    -   \`funspotr’s current approach is slow
    -   Current approach uses some imperfect heuristics
-   Does not identify infix operators, e.g. `+` (maybe fine though)
-   `funspotr` has lots of dependencies. It may have make sense to move
    some of the non-core functionality into a separate package
    (e.g. everything “R/github-spot.R”)
-   It may have made more sense to have `github_get_funs()` clone the
    repo locally rather than pointing to URL’s to parse each file.
-   Currently is possible to have github block you pretty soon due to
    hitting too many files (in which case you’ll likely get a 403 or
    connection error). There are some things that could probably be done
    to reduce number of github API hits (e.g. above bullet,
    `Sys.sleep()`, …).
-   Throughout the code and package documentation I have “inspiration”
    bullets followed by a link pointing to places where I took stuff
    from stack overflow, github, or other packages

## Installation

You can install the development version of funspotr from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("brshallo/funspotr")
```

[1] E.g. `as_tibble()` is attributed to
[tidyr](https://tidyr.tidyverse.org/) by `spot_funs()` however
`as_tibble()` is also in [dplyr](https://dplyr.tidyverse.org/). I don’t
worry about getting to the root source of the package or the fact that
both of those packages are just reexporting it from
[tibble](https://tibble.tidyverse.org/). Setting
`keep_search_list = TRUE` will return rows for each item in the search
list which may be helpful if getting unexpected results.)

[2] If any file could not be parsed will be a `purrr::safely()`
list-column output where each item is a list containing `result` and
`error`.

[3] This heuristic is imperfect and means that a file with
“library(dplyr); select(); MASS::select()” would view both `select()`
calls as coming from {MASS} – when what it should do is view the first
was as coming from {dplyr} and the second from {MASS}.

[4] i.e. in interactive R scripts or Rmd documents where you use
`library()` or related calls within the script.

[5] E.g. for mapping across a local repository, across a package, a data
workflow, etc.

[6] e.g. in this case `lines <- "library(pkg)"` the `pkg` would show-up
as a dependency despite just being part of a quote rather than actually
loaded.
