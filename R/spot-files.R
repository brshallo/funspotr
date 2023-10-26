# engine for `spot_funs_files()` and `spot_pkgs_files()`
# spot_type is either spot_funs or spot_pkgs
spot_files <- function(spot_type, df, ..., .progress = TRUE){

  if(!exists("absolute_paths", df)) stop("`df` is missing required column 'absolute_paths'.")

  safe_spot_type <- purrr::safely(spot_type, quiet = TRUE)

  output <- df %>%
    mutate(spotted = purrr::map(.data$absolute_paths, safe_spot_type, ..., .progress = .progress))

  output_errors <- dplyr::filter(output, did_safely_error(.data$spotted))

  if(nrow(output_errors) > 0){
    warning("Failed for the following absolute_paths: \n\n",
            paste(output_errors$absolute_paths, collapse = "\n"),
            '\n\nCode to investigate errors (replace {output} with the returned object):\n',
            'funspotr:::review_spot_files_errors({output})'
            )
  }

  output
}

#' Spot Packages or Functions in dataframe of Paths
#'
#' @description
#' `spot_pkgs_files()` : Spot all packages that show-up in R or Rmarkdown or
#' quarto documents in a dataframe of filepaths.
#'
#' `spot_funs_files()` : Spot all functions and their corresponding packages
#' that show-up in R or Rmarkdown or quarto documents in a dataframe of
#' filepaths.
#'
#' @details
#' A `purrr::safely()` wrapper for mapping `spot_pkgs()` or `spot_funs()` across
#' multiple filepaths. I.e. even if some files fail to parse the function will
#' continue on.
#'
#' Default settings are meant for files where package libraries are referenced
#' *within* the files themselves. See README for more details.
#'
#' @param df Dataframe containing a column of `absolute_paths`.
#' @param ... Arguments passed onto `spot_{pkgs|funs}()`.
#' @inheritParams purrr::map
#'
#' @return Dataframe with `relative_paths` and `absolute_paths` of file paths
#'   along with a list-column `spotted` containing `purrr::safely()` named list
#'   of "result" and "error" for each file parsed. Use `unnest_results()` to
#'   unnest only the "result" values.
#'
#' @seealso [spot_pkgs()], [spot_funs()], [unnest_results()]
#' @export
#' @examples
#' \donttest{
#' library(funspotr)
#' library(dplyr)
#'
#' list_files_github_repo("brshallo/feat-eng-lags-presentation", branch = "main") %>%
#'   spot_funs_files()
#' }
spot_funs_files <- function(df, ..., .progress = TRUE){
  spot_files(spot_funs, df, ..., .progress = .progress)
}

#' @export
#' @rdname spot_funs_files
spot_pkgs_files <- function(df, ..., .progress = TRUE){
  spot_files(spot_pkgs, df, ..., .progress = .progress)
}


#' Unnest Results
#'
#' Run after running `list_files_*() |> spot_{funs|pkgs}_files()` to unnest the
#' `spotted` list-column.
#'
#' @param df Dataframe outputted by `spot_{funs|pkgs}_files()` that contains a
#'   `spotted` list-column.
#'
#' @return An unnested dataframe with what was in `spotted` moved to the front.
#' @export
#'
#' @seealso [spot_funs_files()], [spot_pkgs_files()]
#'
#' @examples
#' \donttest{
#' library(funspotr)
#' library(dplyr)
#'
#' list_files_github_repo("brshallo/feat-eng-lags-presentation", branch = "main") %>%
#'   spot_funs_files() %>%
#'   unnest_results()
#' }
unnest_results <- function(df){
  output <- df %>%
    filter(!did_safely_error(.data$spotted)) %>%
    mutate(spotted = map(.data$spotted, "result")) %>%
    relocate(.data$spotted) %>%
    unnest(.data$spotted)

  if(any(names(output) == "spotted")) output <- rename(output, pkgs = .data$spotted)

  output
}

# df should be the returned object from running `spot_*_files()` , e.g.:
review_spot_files_errors <- function(df){
  df %>%
    dplyr::filter(did_safely_error(.data$spotted)) %>%
    dplyr::mutate(error = purrr::map(.data$spotted, "error")) %>%
    dplyr::select(-.data$spotted) %>%
    base::as.list() %>%
    purrr::list_transpose()

}
