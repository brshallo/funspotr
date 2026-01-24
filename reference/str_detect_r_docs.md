# String Detect R or Rmarkdown or Quarto File endings

Wrapper on
[`stringr::str_detect()`](https://stringr.tidyverse.org/reference/str_detect.html)
to return `TRUE` for only R and Rmarkdown or Quarto files, else `FALSE`.

## Usage

``` r
str_detect_r_docs(
  contents,
  pattern = stringr::regex("(r|rmd|rmarkdown|qmd)$", ignore_case = TRUE),
  rmv_index = TRUE
)
```

## Arguments

- contents:

  Character vector of file path.

- pattern:

  Regex pattern to identify file types.

- rmv_index:

  Logical, default to `TRUE`, most repos containing blogdown sites will
  have an index.R file at the root. Change to `FALSE` if you don't want
  this file removed.

## Value

Logical vector.

## Examples

``` r
files <- c("file1.R", "file2.Rmd", "file3.Rmarkdown", "file4.Rproj", "file5.qmd")
funspotr::str_detect_r_docs(files)
#> [1]  TRUE  TRUE  TRUE FALSE  TRUE
```
