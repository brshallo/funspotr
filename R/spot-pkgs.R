# ESSENTIALLY EVERYTHING HERE WOULD BE BETTER DONE WITH a parsing rather than
# regex based approach and should perhaps be moved to use `renv::dependencies()` or
# other established packages for dependency detection and management.

#' Spot packages loaded or used in file
#'
#' Extract all `pkg` called in either `library(pkg)`, `require(pkg)`
#' `requireNamespace("pkg")` or `pkg::fun()`. Will not identify packages loaded
#' in other ways not typically done in interactive R scripts (e.g. relying on a
#' DESCRIPTION file for a pkg or something like `source("lib-calls.R")`).
#' Inspiration: https://github.com/rstudio/blogdown/issues/647
#'
#'   Packages are extracted solely based on text -- not whether the
#'   package actually exists or not. Hence even packages that you do not have
#'   installed on your machine but show-up in the script will be returned in the
#'   character vector.
#'
#' @param file_path String of path to file of interest.
#' @param show_explicit_funs In cases where a function is called explicitly,
#'   show both the package dependency and the function together. For example a
#'   script containing `dplyr::select()` (as opposed to `library(dplyr);
#'   select()`) would have `spot_pkgs(show_explicit_funs = TRUE)` return the
#'   item as "dplyr::select" rather than just "dplyr")
#' @param copy_local Logical, if changed to `FALSE` will not copy to a local
#'   temporary folder prior to doing analysis. Many processes require file to
#'   already be a .R file and for the file to exist locally, hence this should
#'   usually be set to `TRUE` unless these are known to be the case.
#' @param as_yaml_tags Logical, default is `FALSE`. If set to `TRUE` flattens
#'   and puts into a format convenient for pasting in "tags" section of a
#'   blogdown post Rmd document.
#'
#' @return Character vector of all packages loaded in file (or in cases where
#'   show_explicit_funs = TRUE and there are explicit calls in the package,
#'   "pkg:fun").
#'
#'
#' @seealso spot_pkgs_from_description github_spot_pkgs renv::dependencies
#'
#' @export
#'
#' @examples
#' library(funspotr)
#'
#' file_lines <- "
#' library(dplyr)
#' require(tidyr)
#' library(madeUpPkg)
#'
#' as_tibble(mpg) %>%
#'   group_by(class) %>%
#'   nest() %>%
#'   mutate(stats = purrr::map(data,
#'                             ~lm(cty ~ hwy, data = .x)))
#'
#' made_up_fun()
#' "
#'
#' file_output <- tempfile(fileext = ".R")
#' writeLines(file_lines, file_output)
#'
#' spot_pkgs(file_output)
#'
#' # To view `purrr::map` as an explicit call
#' spot_pkgs(file_output, show_explicit_funs = TRUE)
#'
#' # To output for blogdown post YAML header tags
#' cat(spot_pkgs(file_output, as_yaml_tags = TRUE))
spot_pkgs <- function(file_path, show_explicit_funs = FALSE, copy_local = TRUE, as_yaml_tags = FALSE){

  if(copy_local){
    file_temp <- copy_to_local_tempfile(file_path)
  } else file_temp <- file_path

  file <- readr::read_lines(file_temp)

  # Remove comments so regexs don't run through
  if(stringr::str_trim(str_flatten(file)) == "") {
    message("No R code in file.")
    return(character())
  }


  lib_calls <- "(?<=library\\()[:alnum:]+(?=[:punct:])"
  req_calls <- "(?<=require\\()[:alnum:]+(?=[:punct:])"
  reqns_calls <- "(?<=requireNamespace\\([:punct:])[:alnum:]+(?=[:punct:])"

  if(show_explicit_funs){
    explicit_calls <- "[[:alnum:]|\\.]+::[^\\(]+"
  } else explicit_calls <- "[[:alnum:]|\\.]+(?=::)"

  regex_calls <- str_flatten(c(lib_calls, req_calls, reqns_calls, explicit_calls), collapse = "|")

  pkg_calls <- str_extract_all(file, regex_calls, simplify = TRUE) %>%
    str_remove_all('"')

  output <- pkg_calls %>%
    stringr::str_subset(pattern = ".+") %>%
    # sort() %>% # instead show in-order they are loaded
    unique()

  if(as_yaml_tags){
    output_tags <- output %>%
      str_flatten("\n  - ") %>%
      stringr::str_c("  - ", .)

    return(output_tags)
  }

  output
}

#' Spot Packages Used
#'
#' Primarily used for cases where you load metapackages like `tidyverse` or
#' `tidymodels` but only want to return those packages that are actually used.
#' E.g. say you have a `library(tidyverse)` call but only end-up using functions
#' that are in `dplyr` -- `spot_pkgs()` would return `"tidyverse"` but
#' `spot_pkgs_used()` woudl return `"dplyr"`.
#'
#' Is essentially just calling `spot_funs() %>% with(unique(pkgs))` in the
#' background. Does not have as many options as `spot_pkgs()` though.
#'
#' @param file_path String of path to file of interest.
#' @param as_yaml_tags Logical, default is `FALSE`. If set to `TRUE` flattens
#'   and puts into a format convenient for pasting in "tags" section of a
#'   blogdown post Rmd document.
#'
#' @return Character vector of all packages with functions used in the file.
#' @export
spot_pkgs_used <- function(file_path, as_yaml_tags = FALSE){

  output <- spot_funs(file_path = file_path) %>%
    filter(!(pkgs %in% c("(unknown)", "base", "stats", "graphics", "grDevices", "utils", "methods"))) %>%
    with(unique(pkgs))

  if(as_yaml_tags){
    output_tags <- output %>%
      str_flatten("\n  - ") %>%
      stringr::str_c("  - ", .)

    return(output_tags)
  }

  output

}

#' Spot package dependencies from DESCRIPTION file
#'
#' Given explicit path to DESCRIPTION file return package dependencies therein.
#' inspiration: https://stackoverflow.com/a/30225680/9059865
#'
#' @param DESCRIPTION_path Path to DESCRIPTION file
#'
#' @return Character vector of packages.
#'
#' @examples
#' funspotr:::spot_pkgs_from_DESCRIPTION(
#'   "https://raw.githubusercontent.com/brshallo/animatrixr/master/DESCRIPTION"
#' )
spot_pkgs_from_DESCRIPTION <- function(DESCRIPTION_path) {

  file_path <- r_to_r_temp(DESCRIPTION_path, fileext = "")

  dcf <- read.dcf(file_path)
  jj <- intersect(c("Depends", "Imports", "Suggests"), colnames(dcf))
  val <- unlist(strsplit(dcf[, jj], ","), use.names=FALSE)
  val <- gsub("\\s.*", "", trimws(val))
  val[val != "R"]
}

#' Check Packages Availability
#'
#' See example for way may use in {funspotr}.
#'
#' @param pkgs Character vector of package names. (Typically the output from
#'   `spot_pkgs()`).
#' @param quietly logical: should progress and error messages be suppressed?
#'
#' @return Named logical vector indicating whether each package is available on
#'   the machine.
#' @export
#'
#' @examples
#' library(funspotr)
#' library(dplyr)
#'
#' file_lines <- "
#' library(dplyr)
#' require(tidyr)
#' library(madeUpPkg)
#'
#' as_tibble(mpg) %>%
#'   group_by(class) %>%
#'   nest() %>%
#'   mutate(stats = purrr::map(data,
#'                             ~lm(cty ~ hwy, data = .x)))
#'
#' made_up_fun()
#' "
#'
#' file_output <- tempfile(fileext = ".R")
#' writeLines(file_lines, file_output)
#'
#' spot_pkgs(file_output) %>%
#'   check_pkgs_availability()
#'
check_pkgs_availability <- function(pkgs, quietly = TRUE){

  # remove function components of explicit function calls:
  # "pkg::fun" becomes "pkg"
  pkgs <- stringr::str_remove(pkgs, "::.+") %>%
    unique()

  purrr::map_lgl(pkgs, requireNamespace, quietly = quietly) %>%
    purrr::set_names(pkgs)
}


#' Install missing packages
#'
#' Attempt to install missing packages from CRAN.
#'
#' In most cases, is probably safer to clone and use `renv::dependencies()` -- README.
#'
#' @param pkgs_availability Named logical vector where names are packages --
#'   generally the output of running `check_pkgs_availability()`.
#'
#' @return Installs packages from cran using `remotes::install_cran()` if
#'   available else `install.packages()`
#'
#' @examples
#' \dontrun{
#' library(funspotr)
#' library(dplyr)
#'
#' file_lines <- "
#' library(dplyr)
#' require(tidyr)
#' library(madeUpPkg)
#'
#' as_tibble(mpg) %>%
#'   group_by(class) %>%
#'   nest() %>%
#'   mutate(stats = purrr::map(data,
#'                             ~lm(cty ~ hwy, data = .x)))
#'
#' made_up_fun()
#' "
#'
#' file_output <- tempfile(fileext = ".R")
#' writeLines(file_lines, file_output)
#'
#' # should verify pkgs are available on CRAN -- this wouldn't work in this case
#' # because # {madeUpPkg} doesn't exist on CRAN
#' spot_pkgs(file_output) %>%
#'   check_pkgs_availability() %>%
#'   funspotr:::install_missing_pkgs()
#' }
install_missing_pkgs <- function(pkgs_availability){

  unavailable_pkgs <- names(pkgs_availability[pkgs_availability])

  if(!requireNamespace("remotes")){
    remotes::install_cran(unavailable_pkgs)

  } else utils::install.packages( unavailable_pkgs )

}

