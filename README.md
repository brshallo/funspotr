
# funspotr <a href="https://brshallo.github.io/funspotr/"><img src="man/figures/logo.png" align="right" height="139" /></a>

[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/brshallo/funspotr/workflows/R-CMD-check/badge.svg)](https://github.com/brshallo/funspotr/actions)

-   [Installation](#installation)
-   [Linked examples](#linked-examples)
    -   [Talks and posts](#talks-and-posts)
    -   [funspotr built reference
        tables](#funspotr-built-reference-tables)
-   [Spot functions in a file](#spot-functions-in-a-file)
-   [Spot functions on all files in a
    project](#spot-functions-on-all-files-in-a-project)
    -   [Previewing and customizing files to
        parse](#previewing-and-customizing-files-to-parse)
-   [Other things](#other-things)
    -   [Files you didn’t write](#files-you-didnt-write)
    -   [Package dependencies in another
        file](#package-dependencies-in-another-file)
    -   [Show all function calls](#show-all-function-calls)
    -   [Helper for blogdown tags](#helper-for-blogdown-tags)
    -   [Unexported functions](#unexported-functions)
-   [How `spot_funs()` works](#how-spot_funs-works)
-   [Limitations, problems, musings](#limitations-problems-musings)

<!-- README.md is generated from README.Rmd. Please edit that file -->
<!-- badges: start -->
<!-- badges: end -->

The goal of funspotr (R function spotter) is to make it easy to identify
which functions and packages are used in files and projects. It was
initially written to create reference tables of the functions and
packages used in a few popular github repositories[1].

There are roughly three types of functions in funspotr:

-   `list_files_*()`: that identify files in a repository or related
    location
-   `spot_*()`: that identify functions or packages in files
-   other helpers that manipulate or plot outputs from the above
    functions

funspotr is primarily designed for identifying the functions / packages
in self-contained files or collections of files[2] like R markdown files
or blogdown projects respectively[3].

## Installation

You can install the development version of funspotr from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("brshallo/funspotr")
```

Package will be submitted to CRAN shortly.

## Linked examples

funspotr can be used to quickly create reference tables of the functions
and packages used in R projects.

### Talks and posts

-   slides from Rstudio Conf 2022 [From summarizing projects to setting
    tags, uses of parsing R
    files](https://github.com/brshallo/funspotr-rstudioconf2022)
-   Part 1 of a series on [Identifying R functions and
    packages…](https://www.bryanshalloway.com/2022/01/18/identifying-r-functions-packages-used-in-github-repos/)
    (WARNING: uses old API)

### funspotr built reference tables

-   [Julia Silge
    blog](https://www.bryanshalloway.com/2022/01/18/identifying-r-functions-packages-used-in-github-repos/#julia-silge-blog)
-   [David Robinson
    screencasts](https://www.bryanshalloway.com/2022/01/18/identifying-r-functions-packages-used-in-github-repos/#david-robinson-tidy-tuesday)
-   [R for Data Science
    book](https://www.bryanshalloway.com/2022/01/18/identifying-r-functions-packages-used-in-github-repos/#r-for-data-science-chapters)
-   [Bryan Shalloway
    blog](https://www.bryanshalloway.com/2022/01/18/identifying-r-functions-packages-used-in-github-repos/#bryan-shalloway-blog)
-   [brshallo
    gists](https://www.bryanshalloway.com/2022/02/07/identifying-r-functions-packages-in-your-github-gists/#binding-files-together)

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
#> # A tibble: 10 x 2
#>    funs         pkgs     
#>    <chr>        <chr>    
#>  1 library      base     
#>  2 require      base     
#>  3 as_tibble    tidyr    
#>  4 mutate       dplyr    
#>  5 as.character base     
#>  6 group_by     dplyr    
#>  7 nest         tidyr    
#>  8 map          purrr    
#>  9 lm           stats    
#> 10 made_up_fun  (unknown)
```

-   `funs`: functions in file
-   `pkgs`: best guess as to the package the functions came from  
-   …[4]

<!-- The example below uses `spot_pkgs_from_DESCRIPTION()` to load in package dependencies and then passes the resulting character vector to `spot_funs_custom()`. -->

## Spot functions on all files in a project

funspotr has a few `list_files_*()` functions that return a dataframe of
`relative_paths` and `absolute_paths` of all the R or R markdown files
in a specified location (e.g. github repo, gists). These can be combined
with a variant of `spot_funs()` that maps the function across each file
path found, `spot_funs_files()`:

``` r
# repo for an old presentation I gave
gh_ex <- list_files_github_repo(
  repo = "brshallo/feat-eng-lags-presentation", 
  branch = "main") %>% 
  spot_funs_files()

gh_ex
#> # A tibble: 4 x 3
#>   relative_paths                absolute_paths                      spotted     
#>   <chr>                         <chr>                               <list>      
#> 1 R/Rmd-to-R.R                  https://raw.githubusercontent.com/~ <named list>
#> 2 R/feat-engineering-lags.R     https://raw.githubusercontent.com/~ <named list>
#> 3 R/load-inspections-save-csv.R https://raw.githubusercontent.com/~ <named list>
#> 4 R/types-of-splits.R           https://raw.githubusercontent.com/~ <named list>
```

-   `relative_paths` : relative filepath
-   `absolute_paths`: absolute filepath (in this case URL to raw file on
    github)
-   `spotted`: `purrr::safely()` style list-column of results[5] from
    mapping `spot_funs()` across `absolute_paths`.

These results may then be unnested with the helper
`funspotr::unnest_results()` to provide a table of functions and
packages by filepath. This can be manipulated like any other dataframe –
say we want to filter to only those files where
[here](https://here.r-lib.org/), [readr](https://readr.tidyverse.org/)
or [rsample](https://rsample.tidymodels.org/) packages are used.

``` r
gh_ex %>% 
  unnest_results() %>% 
  filter(pkgs %in% c("here", "readr", "rsample"))
#> # A tibble: 8 x 4
#>   funs               pkgs    relative_paths                absolute_paths       
#>   <chr>              <chr>   <chr>                         <chr>                
#> 1 here               here    R/Rmd-to-R.R                  https://raw.githubus~
#> 2 read_csv           readr   R/feat-engineering-lags.R     https://raw.githubus~
#> 3 initial_time_split rsample R/feat-engineering-lags.R     https://raw.githubus~
#> 4 training           rsample R/feat-engineering-lags.R     https://raw.githubus~
#> 5 testing            rsample R/feat-engineering-lags.R     https://raw.githubus~
#> 6 sliding_period     rsample R/feat-engineering-lags.R     https://raw.githubus~
#> 7 write_csv          readr   R/load-inspections-save-csv.R https://raw.githubus~
#> 8 here               here    R/load-inspections-save-csv.R https://raw.githubus~
```

The outputs from `funspotr::unnest_results()` can also be passed into
`funspotr::network_plot()` to build a network visualization of the
connections between functions/packages and files[6].

### Previewing and customizing files to parse

You might only want to parse a subset of the files in a repo.

``` r
preview_files <- list_files_github_repo(
  repo = "brshallo/feat-eng-lags-presentation", 
  branch = "main")

preview_files
#> # A tibble: 4 x 2
#>   relative_paths                absolute_paths                                  
#>   <chr>                         <chr>                                           
#> 1 R/Rmd-to-R.R                  https://raw.githubusercontent.com/brshallo/feat~
#> 2 R/feat-engineering-lags.R     https://raw.githubusercontent.com/brshallo/feat~
#> 3 R/load-inspections-save-csv.R https://raw.githubusercontent.com/brshallo/feat~
#> 4 R/types-of-splits.R           https://raw.githubusercontent.com/brshallo/feat~
```

Say we only want to parse the “types-of-splits.R” and “Rmd-to-R.R”
files.

``` r
preview_files %>% 
  filter(stringr::str_detect(relative_paths, "types-of-splits|Rmd-to-R")) %>% 
  spot_funs_files() %>% 
  unnest_results()
#> # A tibble: 24 x 4
#>    funs      pkgs      relative_paths      absolute_paths                       
#>    <chr>     <chr>     <chr>               <chr>                                
#>  1 purl      knitr     R/Rmd-to-R.R        https://raw.githubusercontent.com/br~
#>  2 here      here      R/Rmd-to-R.R        https://raw.githubusercontent.com/br~
#>  3 library   base      R/types-of-splits.R https://raw.githubusercontent.com/br~
#>  4 theme_set ggplot    R/types-of-splits.R https://raw.githubusercontent.com/br~
#>  5 theme_bw  ggplot    R/types-of-splits.R https://raw.githubusercontent.com/br~
#>  6 set.seed  base      R/types-of-splits.R https://raw.githubusercontent.com/br~
#>  7 tibble    dplyr     R/types-of-splits.R https://raw.githubusercontent.com/br~
#>  8 rep       base      R/types-of-splits.R https://raw.githubusercontent.com/br~
#>  9 today     lubridate R/types-of-splits.R https://raw.githubusercontent.com/br~
#> 10 days      lubridate R/types-of-splits.R https://raw.githubusercontent.com/br~
#> # ... with 14 more rows
```

Note that if you have a lot of files in a repo you may need to set-up
sleep periods or clone the repo locally *and then* parse the files from
there so as to stay within the limits of github API hits.

## Other things

### Files you didn’t write

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
#> # A tibble: 5 x 2
#>   funs        pkgs     
#>   <chr>       <chr>    
#> 1 library     base     
#> 2 as_tibble   dplyr    
#> 3 print       base     
#> 4 made_up_fun (unknown)
#> 5 hello_world (unknown)
```

*To spot which package a function is from you must have the package
installed locally.* Hence for files on others’ github repos or that you
created on a different machine, it is a good idea to start with
`funspotr::check_pkgs_availability()` to see which packages you are
missing.

`funspotr:::install_missing_pkgs()` is an unexported helper for
installing missing packages (see “R/spot-pkgs.R” for documentation):

``` r
check_pkgs_availability(file_path) %>% 
  funspotr:::install_missing_pkgs()
```

Alternatively, you may want to clone the repository locally and then use
`renv::dependencies()` and only then start using funspotr[7].

### Package dependencies in another file

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
#> # A tibble: 5 x 2
#>   funs   pkgs     
#>   <chr>  <chr>    
#> 1 source base     
#> 2 tibble tibble   
#> 3 mutate dplyr    
#> 4 today  lubridate
#> 5 days   lubridate
```

Also see `funspotr:::spot_pkgs_from_description()`.

### Show all function calls

Passing in `show_each_use = TRUE` to `...` in `spot_funs()` or
`spot_funs_files()` will return *all* instances of a function call
rather than just once for each file.

Compared to the initial example, `mutate()` now shows-up at both rows 4
and 8:

``` r
spot_funs(file_path = file_output, show_each_use = TRUE)
#> # A tibble: 11 x 2
#>    funs         pkgs     
#>    <chr>        <chr>    
#>  1 library      base     
#>  2 require      base     
#>  3 as_tibble    tidyr    
#>  4 mutate       dplyr    
#>  5 as.character base     
#>  6 group_by     dplyr    
#>  7 nest         tidyr    
#>  8 mutate       dplyr    
#>  9 map          purrr    
#> 10 lm           stats    
#> 11 made_up_fun  (unknown)
```

### Helper for [blogdown](https://pkgs.rstudio.com/blogdown/) tags

Setting `as_yaml_tags = TRUE` in `spot_pkgs()` flattens the dependencies
and outputs them in a format that can be copied and pasted into the
**tags** section of a blogdown post’s YAML header.

``` r
# Example from old blogdown post
spot_pkgs(
  file_path = "https://raw.githubusercontent.com/brshallo/brshallo/master/content/post/2020-02-06-maximizing-magnetic-volume-the-perfect-bowl.Rmd",
  as_yaml_tags = TRUE) %>% 
  cat()
#>   - knitr
#>   - tidyverse
#>   - ggforce
```

`spot_pkgs_used()` will only return those packages that have functions
actually used[8].

*To automatically have your packages used as the tags for a post* you
can add the function `funspotr::spot_tags()` to a bullet in the `tags`
argument of your YAML header[9]. For example:

    ---
    title: This is a post
    author: brshallo
    date: '2022-02-11'
    tags: 
      - "`r funspotr::spot_tags()`"
    slug: this-is-a-post
    ---

### Unexported functions

Many of the unexported functions in funspotr may be helpful in building
up other workflows for mapping `spot_funs()` across multiple files[10]
*If you have a suggestion for a function, feel free to open an issue.*

<!-- **If you've used {funspotr} to map the R functions and packages of a public blog or repository, open an issue to add a link in the README.** -->

## How `spot_funs()` works

funspotr mimics the search space of each file prior to identifying
`pkgs`/`funs`[11]. At a high-level…

1.  Create a new R instance using
    [callr](https://github.com/r-lib/callr)
2.  Load packages. Explicit calls (e.g. `pkg::fun()`) are loaded
    individually via [import](https://github.com/rticulate/import) and
    are loaded last (putting them at the top of the search space)[12].

(steps 1 and 2 needed so that step 4 has the best chance of identifying
the package a function comes from in the file.)

3.  Pass file through `utils::getParseData()` and filter to just
    functions[13]
4.  Pass functions through `utils::find()` to identify associated
    package

## Limitations, problems, musings

-   If a file contains R syntax that is not well defined it will not be
    parsed and will return an error. See
    [formatR\#further-notes](https://yihui.org/formatr/#6-further-notes)
    (used by {funspotr} in parsing) for other common reasons for
    failure.
-   `knitr::read_chunk()` and `knitr::purl()` in a file passed to
    {funspotr} will also frequently cause an error in parsing. See
    [knitr\#1753](https://github.com/yihui/knitr/issues/1753) &
    [knitr\#1938](https://github.com/yihui/knitr/issues/1938)
-   Please open an issue if you find other cases where parsing breaks
    :-) .
-   As mentioned elsewhere, the default parsing of `spot_funs()` is
    primarily for cases where package dependencies are loaded in the
    same file that they are used in[14]. Scripts that are not
    self-contained typically should have the `pkgs` argument provided
    explicitly via `spot_funs_custom()`.
-   funspotr does not pay attention to when functions are reexported
    from elsewhere. For example, many tibble functions are reexported by
    dplyr and tidyr – funspotr though will not know the “true” home of
    these functions it is simply looking at the top of the search
    space[15].
-   Feel free to open an issue if you’d be interested in a simplifying
    function or vignette for mapping `spot_funs()` through other folder
    structures not yet mentioned.
-   All the functions in “R/spot-pkgs.R” would probably be better
    handled by something like `renv::dependencies()` or a parsing based
    approach. The simple regex’s I use have a variety of problems. As
    just one example `funspotr::get_pkgs()` will not recognize when a
    package is within quotes or being escaped[16]. Another useful
    package for installing missing dependencies may be
    [attachment](https://thinkr-open.github.io/attachment/index.html).
-   I am curious if there is something to be learned from how
    `R CMD check` does function parsing.
    -   \`funspotr’s current approach is slow
    -   Current approach uses some imperfect heuristics
-   Does not identify infix operators, e.g. `+`[17]
-   funspotr has lots of dependencies. It may have make sense to move
    some of the non-core functionality into a separate package
    (e.g. stuff concerning `list_files*()`)
-   Rather than running `list_files_github_repo()` it may make sense to
    instead clone the repo locally and then run `list_files_wd()` from
    the repo prior to running `spot_funs_files()` as this will limit the
    number of API hits to github.
-   Currently it’s possible to have github block you pretty soon due to
    hitting too many files (in which case you’ll likely get a 403 or
    connection error). There are some things that could probably be done
    to reduce number of github API hits (e.g. above bullet,
    `Sys.sleep()`, …).
-   Throughout the code and package documentation I have “inspiration”
    bullets followed by a link pointing to places where I took stuff
    from stack overflow, github, or other packages. Also see the
    footnotes of the README

[1] The following posts were written using the initial API for funspotr
– the key functions used in these posts have now been deprecated:  
- [Identifying R Functions & Packages Used in GitHub Repos (funspotr
part
1)](https://www.bryanshalloway.com/2022/01/18/identifying-r-functions-packages-used-in-github-repos/)
- [Identifying R Functions & Packages in Github Gists (funspotr part
2)](https://www.bryanshalloway.com/2022/02/07/identifying-r-functions-packages-in-your-github-gists/)
- [Network Plots of Code Collections (funspotr part
3)](https://www.bryanshalloway.com/2022/03/17/network-plots-of-code-collections-funspotr-part-3/)

[2] See [Package dependencies in another
file](#package-dependencies-in-another-file)

[3] Rather than, for example,
[targets](https://github.com/ropensci/targets) workflows. Also, in some
cases funspotr may not identify *every* function and/or package in a
file (see [Limitations, problems,
musings](#limitations-problems-musings)) or read the source code for
details).

[4] `in_multiple_pkgs`: (by default is dropped, pass in
`keep_in_multiple_pkgs = TRUE` to `...` to display)Whether the function
has multiple packages/environments on it’s (guessed) search space. By
default only the package at the top of the search space is returned.
E.g. `as_tibble()` is attributed to
[tidyr](https://tidyr.tidyverse.org/) by `spot_funs()` however
`as_tibble()` is also in [dplyr](https://dplyr.tidyverse.org/). I don’t
worry about getting to the root source of the package or the fact that
both of those packages are just reexporting it from
[tibble](https://tibble.tidyverse.org/). Setting
`keep_search_list = TRUE` will return rows for each item in the search
list which may be helpful if getting unexpected results.)

[5] list-column output where each item is a list containing `result` and
`error`.

[6] Took some inspiration from `plot()` method in
[cranly](https://github.com/ikosmidis/cranly).

[7] [renv](https://rstudio.github.io/renv/) is a more robust approach to
finding and installing dependencies – particularly in cases where you
are missing many dependencies or don’t want to alter the packages in
your global library.

[8] E.g. for cases when there are library calls that aren’t actually
used in the file. This may be useful in cases when metapackages like
tidyverse or tidymodels are loaded but not all packages are actually
used.

[9] See
([blogdown\#647](https://github.com/rstudio/blogdown/issues/647#issuecomment-1041599327),
[blogdown\#693](https://github.com/rstudio/blogdown/issues/693)) for an
explanation of how `funspotr::spot_tags()` works.

[10] Most unexported functions in `funspotr` still include a man file
and at least partial documentation.

[11] In a language like python, where calls are explicit (e.g. `np.*`),
all of this stuff with recreating the search space would likely be
unnecessary and you could just identify packages/functions with simple
parsing.

[12] This heuristic is imperfect and means that a file with
“library(dplyr); select(); MASS::select()” would view both `select()`
calls as coming from {MASS} – when what it should do is view the first
was as coming from {dplyr} and the second from {MASS}.

[13] inspired by `NCmisc::list.functions.in.file()`.

[14] i.e. in interactive R scripts or Rmd documents where you use
`library()` or related calls within the script.

[15] For example when reviewing David Robinson’s Tidy Tuesday code I
found that the [meme](https://github.com/GuangchuangYu/meme) package was
used far more than I would have expected. Turns out it was just due to
it reexporting the `aes()` function from ggplot.

[16] e.g. in this case `lines <- "library(pkg)"` the `pkg` would show-up
as a dependency despite just being part of a quote rather than actually
loaded.

[17] maybe that’s fine though.
