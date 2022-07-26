#' List Files in Working Directory
#'
#' Return a dataframe containing the paths of files in the working directory.
#' Generally used prior to `spot_{funs/pkgs}_files()`.
#'
#' Can also be used outside of working directory if `path` is specified.
#'
#' @param path Character vector or path. Default is "." which will set the
#'   starting location for `relative_paths`.
#' @param keep_non_r Logical, default is `FALSE` so keeps only records with
#'   `relative_paths` ending in "(r|rmd|rmarkdown)$".
#'
#' @return Dataframe with columns of `relative_paths` and `absolute_paths`.
#' @export
#'
#' @seealso [list_files_github_repo()], [list_files_github_gists()]
#' @examples
#' \dontrun{
#' library(dplyr)
#' library(funspotr)
#'
#' # pulling and analyzing my R file github gists
#' files_local <- list_files_wd()
#'
#' # Will just parse the first 2 files/gists
#' contents <- spot_funs_files(slice(files_local, 1:2))
#'
#' contents %>%
#'   unnest_results()
#' }
list_files_wd <- function(path = ".",
                          keep_non_r = FALSE){
  contents <- tibble(relative_paths = fs::dir_ls(path = ".", recurse = TRUE)) %>%
    mutate(absolute_paths = map_chr(.data$relative_paths, here::here))

  if(keep_non_r){
    return(contents)
  } else filter(contents, str_detect_r_rmd(.data$relative_paths))

}
