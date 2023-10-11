#' Did Safely Error
#'
#' @param safely_named_list Named list as outputted by `purrr::safely()` where
#'   each index contains an "error" and a "result" element.
#'
#' @return logical vector
did_safely_error <- function(safely_named_list){

  output <- map(safely_named_list, "error") %>%
    map_lgl(is.null)

  !output
}

#' String Detect R or Rmarkdown or Quarto File endings
#'
#' Return `TRUE` for only R and Rmarkdown or Quarto files, else `FALSE`.
#'
#' @param contents Character vector of file path.
#' @param rmv_index Logical, default to `TRUE`, most repos containing blogdown
#'   sites will have an index.R file at the root. Change to `FALSE` if you don't
#'   want this file removed.
#' @param pattern Regex pattern to identify file types.
#' @return Logical vector.
#' @examples
#' files <- c("file1.R", "file2.Rmd", "file3.Rmarkdown", "file4.Rproj", "file5.qmd")
#' funspotr:::str_detect_r_docs(files)
str_detect_r_docs <- function(contents, rmv_index = TRUE, pattern = "(r|rmd|rmarkdown|qmd)$"){
  contents_lower <- stringr::str_to_lower(contents)
  contents_subset <- str_detect(fs::path_ext(contents_lower), pattern)

  if(rmv_index) contents_subset <- contents_subset & !str_detect(contents_lower, "^index")

  contents_subset
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
#' \dontrun{
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
