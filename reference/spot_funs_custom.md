# Spot Functions Custom

Engine that runs
[`spot_funs()`](https://brshallo.github.io/funspotr/reference/spot_funs.md).
`spot_funs_custom()` has options for changing returned output and for
producing print statements and errors. It also requires you to provide a
character vector for `pkgs` rather than identifying these automatically
via
[`spot_pkgs()`](https://brshallo.github.io/funspotr/reference/spot_pkgs.md).

## Usage

``` r
spot_funs_custom(
  pkgs,
  file_path,
  show_each_use = FALSE,
  keep_search_list = FALSE,
  copy_local = TRUE,
  print_pkgs_load_status = FALSE,
  error_if_missing_pkg = FALSE,
  keep_in_multiple_pkgs = FALSE
)
```

## Arguments

- pkgs:

  Character vector of packages that are added to search space via
  [`require()`](https://rdrr.io/r/base/library.html) or
  [`import::from()`](https://import.rticulate.org/reference/importfunctions.html)
  so can be found by
  [`utils::find()`](https://rdrr.io/r/utils/apropos.html). Generally
  will be the returned value from
  `spot_pkgs(file_path, show_explicit_funs = TRUE)`.

- file_path:

  character vector of path to file.

- show_each_use:

  Logical, default is `FALSE`. If changed to `TRUE` will return
  individual rows for each time a function is used (rather than just
  once for the entire file).

- keep_search_list:

  Logical, default is `FALSE`. If changed to `TRUE` will include entire
  search list for function. May be helpful for debugging in cases where
  funspotr may not be doing a good job of recreating the search list for
  identifying which packages function(s) came from. This will print all
  packages in the search list for each function.

- copy_local:

  Logical, if changed to `FALSE` will not copy to a local temporary
  folder prior to doing analysis. Many functions require file to already
  be an .R file and for the file to exist locally. This should generally
  not be set to `TRUE` unless these hold.

- print_pkgs_load_status:

  Logical, default is `FALSE`. If set to `TRUE` will print a named
  vector of logicals showing whether packages are on machine along with
  any warning messages that come when running
  [`require()`](https://rdrr.io/r/base/library.html). Will continue on
  to produce output of function.

- error_if_missing_pkg:

  Logical, default is `FALSE`. If set to `TRUE` then
  `print_pkgs_load_status = TRUE` automatically. If a package is not
  installed on the machine then will print load status of individual
  pkgs and result in an error.

- keep_in_multiple_pkgs:

  Logical, default is `FALSE`. If set to `TRUE` will include in the
  outputted dataframe a column `in_multiple_pkgs`: logical, whether a
  function exists in multiple packages loaded (i.e. on the search space
  of [`utils::find()`](https://rdrr.io/r/utils/apropos.html).

## Value

Given default arguments and no missing packages, a dataframe with the
following columns is returned:

`funs`: specifying functions in file. `pkgs`: the package a function
came from. If `funs` is a custom function or if it came from a package
not installed on your machine, `pkgs` will return "(unknown)".

Note that any unused loaded packages / `pkgs` are dropped from output.
Any functions without an available package are returned with the value
"(unknown)".

See README for further documentation.

## Details

`spot_funs_custom()` is also what you should use in cases where you
don't trust
[`spot_pkgs()`](https://brshallo.github.io/funspotr/reference/spot_pkgs.md)
to properly identify package dependencies from within the same file and
instead want to pass in your own character vector of packages.

See README for a description of how the function works.

If a package is not included in `pkgs`, any functions called that should
come from that package will be assigned a value of "(unknown)" in the
`pkgs` column of the returned output. You can also use the
`print_pkgs_load_status` and `error_if_missing_pkg` arguments to alter
how output works in cases when not all packages are on the machine.

Explicit calls to unexported functions i.e. `pkg:::fun()` will have
`pkgs = "(unknown)"` in the returned dataframe.

## See also

[`spot_funs()`](https://brshallo.github.io/funspotr/reference/spot_funs.md)

## Examples

``` r
library(funspotr)

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

pkgs <- spot_pkgs(file_output)

spot_funs_custom(pkgs, file_output)
#> # A tibble: 9 × 2
#>   funs        pkgs     
#>   <chr>       <chr>    
#> 1 library     base     
#> 2 require     base     
#> 3 as_tibble   tidyr    
#> 4 group_by    dplyr    
#> 5 nest        tidyr    
#> 6 mutate      dplyr    
#> 7 map         purrr    
#> 8 lm          stats    
#> 9 made_up_fun (unknown)

# If you'd rather it error when a pkg doesn't exist e.g. for {madeUpPkg}
# set`error_if_missing_pkg = TRUE`
```
