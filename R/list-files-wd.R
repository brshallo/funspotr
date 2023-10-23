#' List Files in Working Directory
#'
#' Return a dataframe containing the paths of files in the working directory.
#' Generally used prior to `spot_{funs/pkgs}_files()`.
#'
#' Can also be used outside of working directory if `path` is specified.
#'
#' @param path Character vector or path. Default is "." which will set the
#'   starting location for `relative_paths`.
#' @param pattern Regex pattern to keep only matching files. Default is
#'   `stringr::regex("(r|rmd|rmarkdown|qmd)$", ignore_case = TRUE)` which will
#'   keep only R, Rmarkdown and Quarto documents. To keep all files use `"."`.
#' @param rmv_index Logical, most repos containing blogdown sites will have an
#'   index.R file at the root. Change to `FALSE` if you don't want this file
#'   removed.
#'
#' @return Dataframe with columns of `relative_paths` and `absolute_paths`.
#' @export
#'
#' @seealso [list_files_github_repo()], [list_files_github_gists()]
#' @examples
#' \donttest{
#' library(dplyr)
#' library(funspotr)
#'
#' # pulling and analyzing my R file github gists
#' files_local <- list_files_wd()
#'
#' # Will just parse the first 2 files/gists
#' contents <- spot_funs_files(slice(files_local, 2:3))
#'
#' contents %>%
#'   unnest_results()
#' }
list_files_wd <- function(path = ".",
                          pattern = stringr::regex("(r|rmd|rmarkdown|qmd)$", ignore_case = TRUE),
                          rmv_index = TRUE) {
  contents <- tibble(relative_paths = fs::dir_ls(path = path, recurse = TRUE)) %>%
    mutate(absolute_paths = map_chr(.data$relative_paths, here::here))

  filter(contents, str_detect_r_docs(.data$relative_paths, pattern = pattern, rmv_index = rmv_index))

}
