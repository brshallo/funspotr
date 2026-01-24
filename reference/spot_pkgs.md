# Spot Packages

Extract all `pkg` called in either
[`library(pkg)`](https://rdrr.io/r/base/library.html),
[`require(pkg)`](https://rdrr.io/r/base/library.html)
[`requireNamespace("pkg")`](https://rdrr.io/r/base/ns-load.html) or
`pkg::fun()`. Will not identify packages loaded in other ways not
typically done in interactive R scripts (e.g. relying on a DESCRIPTION
file for a pkg or something like `source("lib-calls.R")`). Inspiration:
[blogdown#647](https://github.com/rstudio/blogdown/issues/647).

## Usage

``` r
spot_pkgs(
  file_path,
  show_explicit_funs = FALSE,
  copy_local = TRUE,
  as_yaml_tags = FALSE
)
```

## Arguments

- file_path:

  String of path to file of interest.

- show_explicit_funs:

  In cases where a function is called explicitly, show both the package
  dependency and the function together. For example a script containing
  [`dplyr::select()`](https://dplyr.tidyverse.org/reference/select.html)
  (as opposed to `library(dplyr); select()`) would have
  `spot_pkgs(show_explicit_funs = TRUE)` return the item as
  "dplyr::select" rather than just "dplyr")

- copy_local:

  Logical, default is `TRUE`. If changed to `FALSE` will not copy to a
  local temporary folder prior to doing analysis. Many processes require
  file to already be a .R file and for the file to exist locally, hence
  this should usually be set to `TRUE`.

- as_yaml_tags:

  Logical, default is `FALSE`. If set to `TRUE` flattens and puts into a
  format convenient for pasting in "tags" section of YAML header of a
  Rmd document for a blogdown post.

## Value

Character vector of all packages loaded in file.

## Details

In cases where `show_explicit_funs = TRUE` and there are explicit calls
in the package, "pkg:fun" is returned instead.

Packages are extracted solely based on text – not whether the package
actually exists or not. Hence even packages that you do not have
installed on your machine but show-up in the script will be returned in
the character vector.

## See also

[`spot_pkgs_used()`](https://brshallo.github.io/funspotr/reference/spot_pkgs_used.md),
[`spot_pkgs_from_description()`](https://brshallo.github.io/funspotr/reference/spot_pkgs_from_DESCRIPTION.md),
[`spot_pkgs_files()`](https://brshallo.github.io/funspotr/reference/spot_funs_files.md),
`renv::dependencies()`

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

spot_pkgs(file_output)
#> [1] "dplyr"     "tidyr"     "madeUpPkg" "purrr"    

# To view `purrr::map` as an explicit call
spot_pkgs(file_output, show_explicit_funs = TRUE)
#> [1] "dplyr"      "tidyr"      "madeUpPkg"  "purrr::map"

# To output for blogdown post YAML header tags
cat(spot_pkgs(file_output, as_yaml_tags = TRUE))
#>   - dplyr
#>   - tidyr
#>   - madeUpPkg
#>   - purrr
```
