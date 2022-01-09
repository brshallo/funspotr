# ESSENTIALLY EVERYTHING HERE WOULD BE BETTER DONE WITH a parsing rather than
# regex based method and should likely be moved to use `renv::dependencies()` or
# other established packages for dependency detection and management.

#' Get packages loaded or used in file
#'
#' Extract all `pkg` called in either `library(pkg)`, `require(pkg)`
#' `requireNamespace("pkg")` or `pkg::fun()`. Will not identify packages loaded
#' in other ways not typically done in interactive R scripts (e.g. relying on a
#' DESCRIPTION file for a pkg or something like `source("lib-calls.R")`).
#' Inspiration: https://github.com/rstudio/blogdown/issues/647
#'
#' This would be better handled by something like `renv::dependencies()` or
#' established packages for identifying package dependencies.
#'
#' @param file_path Character of length one of path to file of interest.
#' @param as_yaml_tags Logical, default is `FALSE`. If set to `TRUE` flattens
#'   and puts into a format convenient for pasting in "tags" section of a
#'   blogdown post.
#'
#' @return Character vector of all packages used in file. Packages are extracted
#'   solely based on text -- not whether the package actually exists or not.
#'   Hence even packages that you do not have installed on your machine but
#'   show-up in the script will be returned in the character vector.
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
#' get_pkgs(file_output)
#'
#' # For if you use blogdown, there is an argument to return the identified
#' # packages in a way that is convenient for adding them to the tags section of
#' # a yaml header.
#' get_pkgs(file_output, as_yaml_tags = TRUE)
get_pkgs <- function(file_path, as_yaml_tags = FALSE){

  # file <- readr::read_lines(file_path)
  file <- formatR::tidy_source(file_path, comment = FALSE, output = FALSE)$text.tidy %>%
    readr::read_lines()

  lib_calls <- str_extract_all(file, "(?<=library\\()[:alnum:]+(?=[:punct:])", simplify = TRUE) %>%
    str_remove_all('"')
  req_calls <- str_extract_all(file, "(?<=require\\()[:alnum:]+(?=[:punct:])", simplify = TRUE) %>%
    str_remove_all('"')
  reqns_calls <- str_extract_all(file, "(?<=requireNamespace\\([:punct:])[:alnum:]+(?=[:punct:])", simplify = TRUE) %>%
    str_remove_all('"')
  explicit_calls <- str_extract_all(file, "[[:alnum:]|\\.]+(?=::)", simplify = TRUE)

  output <- c(lib_calls, req_calls, reqns_calls, explicit_calls) %>%
    stringr::str_subset(pattern = ".+") %>%
    sort() %>%
    unique()

  if(as_yaml_tags){
    output_tags <- output %>%
      stringr::str_flatten("\n  - ") %>%
      stringr::str_c("  - ", .)

    return( cat(output_tags) )
  }

  output
}

#' Get package dependencies from DESCRIPTION file
#'
#' Given explicit path to DESCRIPTION file return package dependencies therein.
#' inspiration: https://stackoverflow.com/a/30225680/9059865
#'
#' @param DESCRIPTION_path Path to DESCRIPTION file
#'
#' @return Character vector of packages.
#' @export
#'
#' @examples
#' library(funspotr)
#' get_pkgs_from_DESCRIPTION(
#'   "https://raw.githubusercontent.com/brshallo/animatrixr/master/DESCRIPTION"
#' )
get_pkgs_from_DESCRIPTION <- function(DESCRIPTION_path) {

  file_path <- r_to_r_temp(DESCRIPTION_path, fileext = "")

  dcf <- read.dcf(file_path)
  jj <- intersect(c("Depends", "Imports", "Suggests"), colnames(dcf))
  val <- unlist(strsplit(dcf[, jj], ","), use.names=FALSE)
  val <- gsub("\\s.*", "", trimws(val))
  val[val != "R"]
}

#' Check Packages Availability
#'
#' See example for common way would be used in {funspotr}.
#'
#' @param pkgs Character vector with package names checked.
#'
#' @return Named logical indicating whether each package is available on the
#'   machine.
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
#' get_pkgs(file_output) %>%
#'   check_pkgs_availability()
#'
check_pkgs_availability <- function(pkgs){
  purrr::map_lgl(pkgs, requireNamespace) %>%
    purrr::set_names(pkgs)
}


#' Install missing packages
#'
#' Attempt to install missing packages from CRAN. This whole set of functions
#' would be better if handled by taking advantage of something like
#' `renv::dependencies()`.
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
#' # should verify pkgs are available on CRAN -- this won't work in this case
#' # because # {madeUpPkg} doesn't exist on CRAN
#' get_pkgs(file_output) %>%
#'   check_pkgs_availability() %>%
#'   funspotr:::install_missing_pkgs()
#' }
install_missing_pkgs <- function(pkgs_availability){

  unavailable_pkgs <- names(pkgs_availability[pkgs_availability])

  if(!requireNamespace("remotes")){
    remotes::install_cran(unavailable_pkgs)

  } else utils::install.packages( unavailable_pkgs )

}

