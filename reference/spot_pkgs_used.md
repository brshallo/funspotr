# Spot Packages Used

Primarily used for cases where you load metapackages like `tidyverse` or
`tidymodels` but only want to return those packages that have functions
from the package that are actually called. E.g. say you have a
[`library(tidyverse)`](https://tidyverse.tidyverse.org) call but only
end-up using functions that are in `dplyr` – in that case
[`spot_pkgs()`](https://brshallo.github.io/funspotr/reference/spot_pkgs.md)
would return `"tidyverse"` whereas `spot_pkgs_used()` would return
`"dplyr"`.

## Usage

``` r
spot_pkgs_used(file_path, as_yaml_tags = FALSE)
```

## Arguments

- file_path:

  String of path to file of interest.

- as_yaml_tags:

  Logical, default is `FALSE`. If set to `TRUE` flattens and puts into a
  format convenient for pasting in "tags" section of a blogdown post Rmd
  document.

## Value

Character vector of all packages with functions used in the file.

## Details

Also does not return uninstalled packages or those loaded when R starts
up.

Is essentially just calling `spot_funs() |> with(unique(pkgs))` in the
background. Does not have as many options as
[`spot_pkgs()`](https://brshallo.github.io/funspotr/reference/spot_pkgs.md)
though.
