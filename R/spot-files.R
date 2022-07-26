# engine for `spot_funs_files()` and `spot_pkgs_files()`
spot_files <- function(spot_type, df, ...){

  if(!exists("absolute_paths", df)) stop("`df` is missing required column 'absolute_paths'.")

  safe_spot_type <- purrr::safely(spot_type)

  output <- df %>%
    mutate(spotted = map(.data$absolute_paths, safe_spot_type, ...))

  output_errors <- filter(output, did_safely_error(.data$spotted))

  if(nrow(output_errors) > 0){
    warning("Did not evaluate properly for the following absolute_paths: ", output_errors$paths)
  }

  output
}

#' @export
#' @rdname spot_things_files
spot_funs_files <- function(df, ...){
  spot_files(spot_funs, df, ...)
}

#' @export
#' @rdname spot_things_files
spot_pkgs_files <- function(df, ...){
  spot_files(spot_pkgs, df, ...)
}


#' Spot Packages or Functions in dataframe of Paths
#'
#' @description
#' `spot_pkgs_files()` : Spot all packages that show-up in R or Rmarkdown
#' documents in a dataframe of filepaths.
#'
#' `spot_funs_files()` : Spot all functions and their corresponding packages
#' that show-up in R or Rmarkdown documents in a dataframe of filepaths.
#'
#' @details
#' A `purrr::safely()` wrapper for mapping `spot_pkgs()` or `spot_funs()` across
#' multiple filepaths.
#'
#' Defaults are meant for files where package libraries are referenced *within*
#' the files themselves.
#'
#' @param df Dataframe containing a column of `absolute_paths`.
#' @param ... Arguments passed onto `spot_{pkgs|funs}()`.
#'
#' @return Dataframe with `relative_paths` and `absolute_paths` of file paths
#'   along with a list-column `spotted` containing `purrr::safely()` lists of
#'   "result" and "error" for each file parsed. Use `unnest_results()` to unnest
#'   only the "result" values.
#'
#' @seealso [spot_pkgs()], [spot_funs()], [unnest_results()]
#'
#' @examples
#' \dontrun{
#' library(funspotr)
#' library(dplyr)
#'
#' list_files_github_repos("brshallo/feat-eng-lags-presentation", branch = "main", preview = TRUE) %>%
#'   spot_funs_files()
#' }
#' @name spot_things_files
NULL
