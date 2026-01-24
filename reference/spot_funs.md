# Spot Functions

Given `file_path` extract all functions and their associated packages
from specified file.

## Usage

``` r
spot_funs(file_path, ...)
```

## Arguments

- file_path:

  character vector of path to file.

- ...:

  This allows you to pass additional arguments through to
  [`spot_funs_custom()`](https://brshallo.github.io/funspotr/reference/spot_funs_custom.md).

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

`spot_funs()` uses
[`spot_funs_custom()`](https://brshallo.github.io/funspotr/reference/spot_funs_custom.md)
to run – it is a less verbose version and does not require passing in
the packages separately. See README and
[`?spot_funs_custom`](https://brshallo.github.io/funspotr/reference/spot_funs_custom.md)
for details on how the function works and arguments that can be passed
through (via `...`).

If code syntax is malformed and cannot be properly parsed, function will
error.

## See also

[`spot_funs_custom()`](https://brshallo.github.io/funspotr/reference/spot_funs_custom.md),
[`spot_funs_files()`](https://brshallo.github.io/funspotr/reference/spot_funs_files.md)

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

spot_funs(file_output)
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
```
