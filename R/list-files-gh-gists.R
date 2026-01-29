#' List files from a user's GitHub gists
#'
#' Return a tibble of files (relative and raw URLs) from a user's public GitHub gists.
#'
#' @param user Character. GitHub username whose gists will be inspected.
#' @param pattern A regex (or object accepted by `stringr::regex()`) used to
#'   filter file names. By default only R, R Markdown and Quarto files are kept.
#' @return A tibble with columns `relative_paths` (file names) and
#'   `absolute_paths` (raw file URLs). If the user has no gists an empty tibble
#'   with those columns is returned.
#' @export
#' @examples
#' \dontrun{
#' files <- list_files_github_gists('hadley')
#' head(files)
#' }
list_files_github_gists <- function(user,
                                    pattern = stringr::regex("(r|rmd|rmarkdown|qmd)$", ignore_case = TRUE)) {

  content <- get_gist_content(user)

  # If nothing returned, return an empty tibble with the same columns
  if (length(content) == 0) {
    return(tibble::tibble(relative_paths = character(), absolute_paths = character()))
  }

  raw_urls <- content %>%
    map("files") %>%
    map(1) %>%
    map_chr("raw_url")

  output <- tibble(relative_paths = fs::path_file(raw_urls), absolute_paths = raw_urls)

  filter(output, str_detect_r_docs(.data$relative_paths, pattern = pattern, rmv_index = FALSE))
}