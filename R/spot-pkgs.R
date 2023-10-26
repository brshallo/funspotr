# ESSENTIALLY EVERYTHING HERE WOULD BE BETTER DONE WITH a parsing rather than
# regex based approach and should perhaps be moved to use `renv::dependencies()` or
# other established packages for dependency detection and management.

#' Spot Packages
#'
#' Extract all `pkg` called in either `library(pkg)`, `require(pkg)`
#' `requireNamespace("pkg")` or `pkg::fun()`. Will not identify packages loaded
#' in other ways not typically done in interactive R scripts (e.g. relying on a
#' DESCRIPTION file for a pkg or something like `source("lib-calls.R")`).
#' Inspiration: [blogdown#647](https://github.com/rstudio/blogdown/issues/647).
#'
#'   In cases where `show_explicit_funs = TRUE` and there are explicit calls in
#'   the package, "pkg:fun" is returned instead.
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
#' @param copy_local Logical, default is `TRUE`. If changed to `FALSE` will not
#'   copy to a local temporary folder prior to doing analysis. Many processes
#'   require file to already be a .R file and for the file to exist locally,
#'   hence this should usually be set to `TRUE`.
#' @param as_yaml_tags Logical, default is `FALSE`. If set to `TRUE` flattens
#'   and puts into a format convenient for pasting in "tags" section of YAML
#'   header of  a Rmd document for a blogdown post.
#'
#' @return Character vector of all packages loaded in file.
#'
#'
#' @seealso [spot_pkgs_used()], [spot_pkgs_from_description()],
#'   [spot_pkgs_files()], `renv::dependencies()`
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
    return(character())
  }


  lib_calls <- "(?<=library\\()[:punct:]?[:alnum:]+(?=[:punct:])"
  req_calls <- "(?<=require\\()[:punct:]?[:alnum:]+(?=[:punct:])"
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
      str_flatten("\n  - ")

    output_tags <- stringr::str_c("  - ", output_tags)

    return(output_tags)
  }

  output
}

#' Spot Packages Used
#'
#' Primarily used for cases where you load metapackages like `tidyverse` or
#' `tidymodels` but only want to return those packages that have functions from
#' the package that are actually called. E.g. say you have a
#' `library(tidyverse)` call but only end-up using functions that are in `dplyr`
#' -- in that case `spot_pkgs()` would return `"tidyverse"` whereas
#' `spot_pkgs_used()` would return `"dplyr"`.
#'
#' Also does not return uninstalled packages or those loaded when R starts up.
#'
#' Is essentially just calling `spot_funs() |> with(unique(pkgs))` in the
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
    filter(!(.data$pkgs %in% c("(unknown)", "base", "stats", "graphics", "grDevices", "utils", "methods")))

  output <- unique(output$pkgs)

  if(as_yaml_tags){
    output_tags <- output %>%
      str_flatten("\n  - ")

    output_tags <- stringr::str_c("  - ", output_tags)

    return(output_tags)
  }

  output

}

#' Spot package dependencies from DESCRIPTION file
#'
#' Given explicit path to DESCRIPTION file return package dependencies therein.
#' Inspiration: [blogdown#647](https://stackoverflow.com/a/30225680/9059865).
#'
#' @param DESCRIPTION_path Path to DESCRIPTION file
#'
#' @return Character vector of packages.
#' @export
#' @keywords internal
#'
#' @examples
#' funspotr::spot_pkgs_from_description(
#'   "https://raw.githubusercontent.com/brshallo/animatrixr/master/DESCRIPTION"
#' )
spot_pkgs_from_description <- function(DESCRIPTION_path) {

  file_path <- r_to_r_temp(DESCRIPTION_path, fileext = "")

  dcf <- read.dcf(file_path)
  jj <- intersect(c("Depends", "Imports", "Suggests"), colnames(dcf))
  val <- unlist(strsplit(dcf[, jj], ","), use.names=FALSE)
  val <- gsub("\\s.*", "", trimws(val))
  val[val != "R"]
}

#' Check Packages Availability
#'
#' Check whether packages are available in current library.
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


#' Install Missing Packages From CRAN
#'
#' Attempt to install missing packages from CRAN. In most cases, it is safer to
#' clone and use `renv::dependencies()`. See README for example. You should
#' first verify packages specified are available on CRAN, otherwise will error.
#'
#' @param pkgs_availability Named logical vector where names are packages --
#'   generally the output of running `check_pkgs_availability()`.
#'
#' @return Installs packages from cran using `remotes::install_cran()` if
#'   available, else `install.packages()`
#'
#' @export
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' library(funspotr)
#' library(dplyr)
#'
#' file_lines <- "
#' library(dplyr)
#' require(tidyr)
#'
#' as_tibble(mpg) %>%
#'   group_by(class) %>%
#'   nest() %>%
#'   mutate(stats = purrr::map(data,
#'                             ~lm(cty ~ hwy, data = .x)))
#'
#' "
#'
#' file_output <- tempfile(fileext = '.R')
#' writeLines(file_lines, file_output)
#'
#' spot_pkgs(file_output) %>%
#'   check_pkgs_availability() %>%
#'   install_missing_pkgs()
#' }
install_missing_pkgs <- function(pkgs_availability){

  unavailable_pkgs <- names(pkgs_availability[pkgs_availability])

  if(!requireNamespace("remotes")){
    remotes::install_cran(unavailable_pkgs)

  } else utils::install.packages( unavailable_pkgs )

}

