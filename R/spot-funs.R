########UNEXPORTED HELPERS############################
#' List Functions in File
#'
#' Simply a wrapper on `utils::getParseData()` . Is mostly copied from:
#' NCmisc::list.functions.in.file(). Rewrote because function made order of
#' output dependent on packages. Also wanted to add `show_each_use` argument.
#'
#' @param file_path character vector of path to file.
#' @param show_each_use If changed to `TRUE` will return each instance a function
#'   is used rather than once for everything
#'
#' @noRd
list_functions_in_file <- function(file_path, show_each_use = FALSE){
  tmp <- utils::getParseData(parse(file_path, keep.source = TRUE))
  nms <- tmp$text[which(tmp$token == "SYMBOL_FUNCTION_CALL")]
  nms_unique <- unique(nms)

  # only do `find()` once for each function, even if `show_each_use = TRUE`
  funs <- sapply(nms_unique, utils::find)
  if(show_each_use) funs <- funs[nms]

  funs
}

#' List Functions in File to Dataframe
#'
#'   This is a helper function that converts output from
#'   `funspotr:::list_functions_in_file()` into a tibble and cleans-up a few
#'   things.
#'   '
#'   `list_functions_in_file_to_df()` is the last step inside `spot_funs()` --
#'   check there for documentation on the returned output.
#'
#'   Note that the `map_chr(pkgs, 1)` step at the end means that it only keeps
#'   the version of the function at the top of the fabricated search list. This
#'   is not perfect however. It also does nothing with reexported functions etc.
#'   (e.g. `as_tibble()` home is tibble but it is reexported by dplyr and tidyr
#'   -- this is meaningless to `spot_funs()` though which is just looking at the
#'   top of the search space via `utils::find()`)
#'
#' @param funs List output returned from running
#'   `funspotr:::list_functions_in_file()`
#' @param keep_search_list Logical, default is `FALSE` if change to `TRUE` will
#'   include entire search list as a list-column.
#' @noRd
list_functions_in_file_to_df <- function(funs, keep_search_list = FALSE){

  output <- tibble::enframe(funs) %>%
    rename(funs = .data$name, pkgs = .data$value) %>%
    mutate(pkgs_len = map_int(.data$pkgs, length),
           in_multiple_pkgs = ifelse(.data$pkgs_len > 1, TRUE, FALSE),
           pkgs = map(.data$pkgs, ~str_extract(.x, "(?<=package:)[:alpha:]+") %>% unique()),
           pkgs = ifelse(.data$pkgs_len == 0, list("(unknown)"), .data$pkgs)) %>%
    select(-.data$pkgs_len)

  if(keep_search_list) return(output) # previously unnested... but if also `show_each_use = TRUE` is confusing

  mutate(output, pkgs = map_chr(.data$pkgs, 1))
}

#' Call R List Functions
#'
#' The next several function are all created to make namespaces *slightly*
#' better -- honestly not sure is worth the added complexity this created. But
#' what I do is essentially: if there are no explicit function calls (i.e.
#' pkg::fun() ) then `spot_funs()` / `spot_funs_custom()` will run
#' `call_r_list_functions()` to identify functions and packages, but if there
#' are explicit functions it will run `call_r_list_functions_explicit()` which
#' does the same thing as `call_r_list_functions()` except it first loads any
#' regular packages AND THEN attaches any explicit function calls -- this has
#' the impact of giving explicit function calls precedence in terms of being
#' identified while not attaching the entire package (the way prior approaches
#' did). This still has problems in some cases but on the whole I think is
#' better... These functions use the import package to manage this process and
#' takes the approach described here:
#' https://github.com/rticulate/import/issues/57
#' @name call_r_list_functions_doc
#'
#' @param pkgs Character vector of packages loaded via library, require, etc,
#' @param file_temp character vector of path to file. In most cases will be a
#'   temporary file.
#' @param show_each_use Logical, default is `FALSE`. If changed to `TRUE` will
#'   return individual rows for each time a function is used (rather than just
#'   once for the entire file).
#' @param pkgs_explicit Packages used explicitly, e.g. `pkg::fun()`.
NULL

#'
#' @rdname call_r_list_functions_doc
call_r_list_functions <- function(pkgs, file_temp, show_each_use = FALSE){

  callr::r(function(pkgs, file_temp, show_each_use, fun) {

    # load packages, inspiration: https://stackoverflow.com/a/8176099/9059865
    lapply(pkgs, require, character.only = TRUE);

    # inspiration: https://stackoverflow.com/a/53009440/9059865
    fun(file_temp, show_each_use) },

    args = list(pkgs, file_temp, show_each_use, list_functions_in_file))
}

# Add specific functions to search space that will be recognized by
# utils::find()
# used to take the approach described here:
# https://github.com/rticulate/import/issues/57
# attach_pkg_fun <- function(pkg_fun){
#   pkg <- pkg_fun$pkg
#   fun <- pkg_fun$fun
#   pkg_nm <- paste0("explicitpackage:", pkg)
#
#   import::from(pkg, fun, .into = pkg_nm, .character_only = TRUE)
# }

# old approach
attach_pkg_fun <- function(pkg_fun){
  pkg <- pkg_fun$pkg
  fun <- pkg_fun$fun
  env <- new.env()
  env_nm <- paste0("explicitpackage:", pkg)

  import::from(pkg, fun, .into = {env}, .character_only = TRUE)

  make_attach <- attach # Make R CMD check happy.
  make_attach(env, name = env_nm)
}

try_attach_pkg_fun <- function(pkg_fun) try(attach_pkg_fun(pkg_fun))

#'
#' @rdname call_r_list_functions_doc
call_r_list_functions_explicit <- function(pkgs, pkgs_explicit, file_temp, show_each_use = FALSE){

  callr::r(function(pkgs, pkgs_explicit, file_temp, show_each_use, fun1, fun2) {
    # load packages, inspiration: https://stackoverflow.com/a/8176099/9059865
    lapply(pkgs, require, character.only = TRUE);

    lapply(pkgs_explicit, fun1);

    # inspiration: https://stackoverflow.com/a/53009440/9059865
    fun2(file_temp, show_each_use) },

    args = list(pkgs, pkgs_explicit, file_temp, show_each_use, try_attach_pkg_fun, list_functions_in_file))
}
####


####################################

#' Spot Functions Custom
#'
#' Engine that runs `spot_funs()`. `spot_funs_custom()` has options for changing
#' returned output and for producing print statements and errors. It also
#' requires you to provide a character vector for `pkgs` rather than identifying
#' these automatically via `spot_pkgs()`.
#'
#' `spot_funs_custom()` is also what you should use in cases where you don't
#' trust `spot_pkgs()` to properly identify package dependencies from within the
#' same file and instead want to pass in your own character vector of packages.
#'
#' See README for a description of how the function works.
#'
#' If a package is not included in `pkgs`, any functions called that should come
#' from that package will be assigned a value of "(unknown)" in the `pkgs`
#' column of the returned output. You can also use the `print_pkgs_load_status`
#' and `error_if_missing_pkg` arguments to alter how output works in cases when
#' not all packages are on the machine.
#'
#' Explicit calls to unexported functions i.e. `pkg:::fun()` will have `pkgs =
#' "(unknown)"` in the returned dataframe.
#'
#' @param pkgs Character vector of packages that are added to search space via
#'   `require()` or `import::from()` so can be found by `utils::find()`.
#'   Generally will be the returned value from `spot_pkgs(file_path,
#'   show_explicit_funs = TRUE)`.
#' @param file_path character vector of path to file.
#' @param show_each_use Logical, default is `FALSE`. If changed to `TRUE` will
#'   return individual rows for each time a function is used (rather than just
#'   once for the entire file).
#' @param keep_search_list Logical, default is `FALSE`. If changed to `TRUE`
#'   will include entire search list for function. May be helpful for debugging
#'   in cases where funspotr may not be doing a good job of recreating the
#'   search list for identifying which packages function(s) came from. This will
#'   print all packages in the search list for each function.
#' @param copy_local Logical, if changed to `FALSE` will not copy to a local
#'   temporary folder prior to doing analysis. Many functions require file to
#'   already be an .R file and for the file to exist locally. This should
#'   generally not be set to `TRUE` unless these hold.
#' @param print_pkgs_load_status Logical, default is `FALSE`. If set to `TRUE`
#'   will print a named vector of logicals showing whether packages are on
#'   machine along with any warning messages that come when running `require()`.
#'   Will continue on to produce output of function.
#' @param error_if_missing_pkg Logical, default is `FALSE`. If set to `TRUE` then
#'   `print_pkgs_load_status = TRUE` automatically. If a package is not
#'   installed on the machine then will print load status of individual pkgs and
#'   result in an error.
#' @param keep_in_multiple_pkgs Logical, default is `FALSE`. If set to `TRUE`
#'   will include in the outputted dataframe a column `in_multiple_pkgs`:
#'   logical, whether a function exists in multiple packages loaded (i.e. on the
#'   search space of `utils::find()`.
#'
#' @return Given default arguments and no missing packages, a dataframe with the
#'   following columns is returned:
#'
#'   `funs`: specifying functions in file.
#'   `pkgs`: the package a function came from. If `funs` is a custom function or
#'   if it came from a package not installed on your machine, `pkgs` will return
#'   "(unknown)".
#'
#'   Note that any unused loaded packages / `pkgs` are dropped from output.
#'   Any functions without an available package are returned with the value
#'   "(unknown)".
#'
#'   See README for further documentation.
#'
#' @seealso [spot_funs()]
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
#' spot_funs_custom(pkgs, file_output)
#'
#' # If you'd rather it error when a pkg doesn't exist e.g. for {madeUpPkg}
#' # set`error_if_missing_pkg = TRUE`
spot_funs_custom <- function(pkgs,
                             file_path,
                             show_each_use = FALSE,
                             keep_search_list = FALSE,
                             copy_local = TRUE,
                             print_pkgs_load_status = FALSE,
                             error_if_missing_pkg = FALSE,
                             keep_in_multiple_pkgs = FALSE) {


  if(print_pkgs_load_status || error_if_missing_pkg){

    pkgs_loaded <- check_pkgs_availability(pkgs)

    print(pkgs_loaded)

    if (error_if_missing_pkg && !all(pkgs_loaded)) {
      stop("A package in `pkgs` is not installed on machine. Install missing packages and rerun.")
    }
  }

  if(copy_local){
    file_temp <- copy_to_local_tempfile(file_path)
  } else file_temp <- file_path

  pkgs_explicit <- str_subset(pkgs, "::", negate = FALSE)

  if(length(pkgs_explicit) == 0){

      output <- call_r_list_functions(pkgs, file_temp, show_each_use) %>%
        list_functions_in_file_to_df(keep_search_list)
  } else {

    pkgs_full <- str_subset(pkgs, "::", negate = TRUE)
    pkgs_explicit <- map(pkgs_explicit,
                         ~list(pkg = str_extract(.x, ".+(?=::)"),
                               fun = str_extract(.x, "(?<=::).+"))
                         )

    output <- call_r_list_functions_explicit(pkgs_full, pkgs_explicit, file_temp, show_each_use) %>%
      list_functions_in_file_to_df(keep_search_list)

  }

  if(keep_in_multiple_pkgs) {
    return(output)
  } else select(output, -.data$in_multiple_pkgs)
}

#' Spot Functions
#'
#' Given `file_path` extract all functions and their associated packages from
#' specified file.
#'
#' `spot_funs()` uses `spot_funs_custom()` to run -- it is a less verbose
#' version and does not require passing in the packages separately. See README
#' and `?spot_funs_custom` for details on how the function works and arguments
#' that can be passed through (via `...`).
#'
#' If code syntax is malformed and cannot be properly parsed, function will error.
#'
#' @inheritParams spot_funs_custom
#' @param ... This allows you to pass additional arguments through to
#'   `spot_funs_custom()`.
#'
#' @inherit spot_funs_custom return
#' @seealso [spot_funs_custom()], [spot_funs_files()]
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
#' spot_funs(file_output)
spot_funs <- function(file_path, ...){

  file_temp <- copy_to_local_tempfile(file_path)

  # Creating `file_temp` above and setting `copy_local = FALSE` here prevents
  # redundant files being created. This is helpful in functions like
  # `github_spot_funs()` that hit `spot_funs()` several times in that reduces
  # the number of times the github API will be hit (otherwise with many files
  # are likely to hit a 403 error).
  pkgs <- spot_pkgs(file_temp, show_explicit_funs = TRUE, copy_local = FALSE)

  spot_funs_custom(pkgs,
                   file_temp,
                   copy_local = FALSE,
                   ...)
}
