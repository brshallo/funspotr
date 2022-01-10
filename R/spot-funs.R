
########UNEXPORTED HELPERS############################
### HELPERS TO MAKE LOCAL TEMPFILES
# `rmd_chunks_to_r_temp()` ; `r_to_r_temp()` ; go into
# `copy_to_local_tempfile()` which is a helper for creating local R temp files
# from other file locations which is needed because
# NCmisc::list.functions.in.file() expects local versions of the file (which is
# important so you can provide a URL as a filepath for example). It would
# probably be more efficient to first have a check whether the file is local or
# not before going straight into making the temp file... It also may be helpful
# to add some parsing capabilities in these functions, to e.g. take-out any
# commented parts of code... but this would be tough to actually do correctly
# https://stackoverflow.com/questions/23630530/is-there-a-way-to-delete-all-comments-in-a-r-script-using-rstudio

# RMD to local R temp file
# inspiration: https://gist.github.com/noamross/a549ee50e8a4fd68b8b1
rmd_chunks_to_r_temp <- function(file){

  temp <- tempfile(fileext=".R")
  knitr::purl(file, output = temp)

}

# R to local R temp file
r_to_r_temp <- function(file, fileext = ".R"){

  lines <- readLines(file)
  file_output <- tempfile(fileext = fileext)
  writeLines(lines, file_output)
  file_output
}

# copy R or Rmarkdown file format to a local temporary R file
copy_to_local_tempfile <- function(file_path){
  if(stringr::str_to_lower(fs::path_ext(file_path)) %in% c("rmd", "rmarkdown")){
    file_temp <- rmd_chunks_to_r_temp(file_path)
  } else {
    file_temp <- r_to_r_temp(file_path)

    if(stringr::str_to_lower(fs::path_ext(file_path)) != "r"){
      warning("File extension does not seem to be an R or Rmarkdown file. File is being processed as though it is a .R file .")
    }
  }

  file_temp
}


#' List Functions in File to Dataframe
#'
#'   This is a helper function that converts output from
#'   NCmisc::list.functions.in.file() into a tibble and cleans-up a few things.
#'
#'   `list_functions_in_file_to_df()` is the last step inside `spot_funs()` --
#'   check there for documentation on the returned output.
#'
#' @param funs List output returned from running
#'   NCmisc::list.functions.in.file()
list_functions_in_file_to_df <- function(funs){

  if(nrow(funs) == 0) return(tibble(pkgs = character(), funs = character(), pkg_multiple = logical()))

  funs_df <- funs %>%
    tibble::enframe() %>%
    mutate(in_multiple_pkgs = str_detect(name, ","),
           pkg_list = str_extract_all(name, "(?<=package:)[:alpha:]+"),
           pkg_len = map_int(pkg_list, length)) %>%
    mutate(pkglist = ifelse(pkg_len == 0, list("(unknown)"), pkg_list)) %>%
    select(funs = value, pkgs = pkglist, in_multiple_pkgs) %>%
    unnest(pkgs) %>%
    unnest(funs)

  funs_df
}

####################################

#' Spot Functions Custom
#'
#' Engine that runs `spot_funs()`. `spot_funs_custom()` has options for returning
#' print statements and errors that may be useful when you don't have all
#' packages installed. It also requires you to provide a character vector for
#' `pkgs` rather than identifying these automatically via `spot_pkgs()`.
#'
#' `spot_funs_custom()` is what you should use in cases where you don't trust
#' `spot_pkgs()` to properly identify package dependencies and instead want to
#' pass in your own character vector of packages.
#'
#' HOW IT WORKS: Loads packages (`pkgs`) in a new R process and then extracts
#' all functions in specified file via `NCmisc::list.functions.in.file()`. The
#' reason it is necessary to load this in a separate process is it prevents
#' any packages open in your current session from being used to identify
#' functions in the source file of interest.
#'
#' If a package is not included in `pkgs`, any functions called that should come
#' from that package will be assigned to an "(unknown)" value in the returned
#' output.
#'
#' Note that any commented out functions or packages in the file are (currently)
#' included in the output.
#'
#' @param pkgs Character vector of packages to `require` for script. Generally
#'   will be the returned value from `spot_pkgs(file_path)`.
#' @param file_path character vector of path to file. This function depends on
#'   `NCmisc::list.function.in_file()` which requries an actual file_path for a
#'   file passed in.
#'
#' @param print_pkgs_load_status Logical, default is `FALSE`. If set to `TRUE`
#'   will *print* a named vector of logicals showing whether packages are on
#'   machine along with any warning messages that come when running `require()`.
#'   Along with output.
#' @param error_if_missing_pkg Logical, default is `FALSE`. If set to `TRUE` then
#'   `print_pkgs_load_status = TRUE` automatically. If a package is not
#'   installed on the machine then will print load status of individual pkgs and
#'   result in an error.
#'
#' @return Given default arguments and no missing packages A dataframe with the
#'   following columns is returned: `funs`: specifying functions in file.
#'   `pkgs`: the package a function came from. If `funs` is a custom function or
#'   if it came from a package not installed on your machine, `pkgs` will return
#'   "(unknown)". `in_multiple_pkgs`: logical, sometimes a function name may
#'   exist in multiple packages loaded. If that is the case then a separate line
#'   will be printed for each loaded package containing the function and
#'   `in_multiple_pkgs` will be `TRUE` for each. (Ideally this column would not
#'   need to exist and the function could determine which pkg the function is
#'   coming from -- maybe in a future version...)
#'
#' Note that any unknown pkgs do not show-up in `pkgs` but are simply dropped
#' (any of their functions simply have `pkgs` equal to "unknown").
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
#' pkgs <- spot_pkgs(file_output)
#'
#' # Notice is not able to determine singular package for as_tibble()
#' spot_funs_custom(pkgs, file_output)
#'
#' # If you'd rather it error when a pkg doesn't exist (e.g. {madeUpPkg})
#' # You could run:
#' # spot_funs_custom(pkgs, file_output, error_if_missing_pkg = TRUE)
spot_funs_custom <- function(pkgs,
                            file_path,
                            print_pkgs_load_status = FALSE,
                            error_if_missing_pkg = FALSE) {


  if(print_pkgs_load_status || error_if_missing_pkg){

    pkgs_loaded <- check_pkgs_availability(pkgs)

    print(pkgs_loaded)

    if (error_if_missing_pkg && !all(pkgs_loaded)) {
      stop("A package in `pkgs` is not installed on machine. Install missing packages and rerun.")
    }
  }

  file_temp <- copy_to_local_tempfile(file_path)

  callr::r(function(pkgs, file_temp) {
    # load packages, inspiration: https://stackoverflow.com/a/8176099/9059865
    lapply(pkgs, require, character.only = TRUE);
    # inspiration: https://stackoverflow.com/a/53009440/9059865
    NCmisc::list.functions.in.file(file_temp) },
    args = list(pkgs, file_temp)) %>%
    list_functions_in_file_to_df()
}

# put parts together so can input an R or Rmarkdown file
# return the set of functions

#' Spot Functions
#'
#' Given `file_path` extract all functions and their associated packages from
#' specified file.
#'
#' `spot_funs()` uses `spot_funs_custom()` to run -- it is just a less verbose
#' version and does not require passing in the packages separately. See
#' `?spot_funs_custom` for details on how the function works.
#'
#' @inheritParams spot_funs_custom
#' @param ... This allows you to pass additional arguments to
#'   `spot_funs_custom()` that may be useful when not all packages in `file_path`
#'   are available on the machine. See `?spot_funs_custom` for documentation.
#'
#' @inherit spot_funs_custom return
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
#' # Notice is not able to determine singular package for as_tibble()
#' spot_funs(file_output)
spot_funs <- function(file_path, ...){

  pkgs <- spot_pkgs(file_path)
  spot_funs_custom(pkgs, file_path, ...)
}
