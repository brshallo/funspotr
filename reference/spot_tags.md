# Spot Tags

Put quoted inline R function in your blogdown or quarto post's YAML
header to have the packages be the packages used in your post (wrapper
around
[`funspotr::spot_pkgs()`](https://brshallo.github.io/funspotr/reference/spot_pkgs.md)).

## Usage

``` r
spot_tags(
  file_path = knitr::current_input(),
  used = FALSE,
  drop_knitr = FALSE,
  yaml_bullet = NULL,
  ...
)
```

## Arguments

- file_path:

  Default is the file being knitted but can change to some other file
  (e.g. in cases where the code for the post may reside in a different
  file).

- used:

  Default is `FALSE`. If `TRUE` will pass to `show_pkgs_used()` rather
  than `show_pkgs()`. (Mainly useful for showing actual packages used
  rather than meta-packages being called like `tidyverse` or
  `tidymodels`. Also uses a more strict parsing method.

- drop_knitr:

  Many blogdown posts have `knitr::opts_chunk$set()` in them and you may
  not want this tag showing-up. Default is to keep this, but set to
  `FALSE` to drop "knitr" from being tagged.

- yaml_bullet:

  Default is `NULL` meaning that `file_path` is read-in and correct
  format is guessed based on "spot_tags" appearance with either a hyphen
  or bracket (corresponding with bulleted or array format in the YAML
  header).

  If it's first occurrence happens on a line that contains a bracket the
  value becomes `FALSE` else it becomes `TRUE`. If set to `NULL` and
  "spot_tags" is not detected at all in `file_path` it will default to
  `FALSE`. `yaml_bullet` can also be specified directly with either
  `TRUE` or `FALSE`. `TRUE` entails that `spot_tags()` is set in a YAML
  bullet, `FALSE` indicates the user is inputting it in an array (see
  examples below).

  See examples for how to hard-code.

- ...:

  Any additional arguments to pass to `spot_pkgs*()`.

## Value

Character vector in a format meant to be read while evaluating the YAML
header when rendering.

## Details

    tags:
      - "`r funspotr::spot_tags()`"

OR

    tags: ["`r funspotr::spot_tags()`"]

OR

    categories: ["`r funspotr::spot_tags()`"]

Thanks Yihui for the suggestions and for getting this working
[blogdown#647](https://github.com/rstudio/blogdown/issues/647),
[blogdown#693](https://github.com/rstudio/blogdown/issues/693).)

## See also

[`spot_pkgs()`](https://brshallo.github.io/funspotr/reference/spot_pkgs.md),
[`spot_pkgs_used()`](https://brshallo.github.io/funspotr/reference/spot_pkgs_used.md)

## Examples

``` r
# To review input interactively from within rstudio you might also try:
if (FALSE) { # \dontrun{
funspotr::spot_tags(rstudioapi::getSourceEditorContext()$path)
} # }
```
