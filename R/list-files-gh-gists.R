get_gist_pages <- function(user) {

  req_user <- httr::GET(glue::glue("https://api.github.com/users/{user}"))

  # Check HTTP response first
  if (httr::status_code(req_user) != 200) {
    warning("Failed to fetch GitHub user info for '\", user,\"' (status ", httr::status_code(req_user), "). Returning 0 pages.")
    return(0L)
  }

  body <- httr::content(req_user)
  num_gists <- body$public_gists

  # Defensive handling: ensure we have a single non-negative integer
  if (is.null(num_gists) || length(num_gists) == 0) return(0L)
  num_gists <- as.integer(num_gists)
  if (is.na(num_gists) || num_gists <= 0L) return(0L)

  # Compute pages using ceiling to avoid remainder logic problems
  num_pages <- ceiling(num_gists / 100)
  num_pages
}

get_gist_content <- function(user) {

  num_pages <- get_gist_pages(user)

  # If there are no pages, return an empty list
  if (num_pages == 0L) return(list())

  # gists themselves
  req_content <- vector("list", num_pages)

  for (i in seq_len(num_pages)) {

    req <- httr::GET(
      glue::glue("https://api.github.com/users/{user}/gists"),
      query = list(per_page = 100, page = i)
    )

    if (httr::status_code(req) != 200) {
      warning("Failed to fetch gists for page ", i, " (status ", httr::status_code(req), "). Skipping page.")
      req_content[[i]] <- list()
      next
    }

    req_content[[i]] <- httr::content(req)
  }

  purrr::flatten(req_content)
}

#' List Files in Github Gists
#'
#' Return a dataframe containing the paths of files in a github user's gists.
#' Generally used prior to `spot_{funs/pkgs}_files()`.
#'
#' @param user Github username, e.g. "brshallo"
#' @param pattern Regex pattern to keep only matching files. Default is
#'   `stringr::regex("(r|rmd|rmarkdown|qmd)$", ignore_case = TRUE)` which will
#'   keep only R, Rmarkdown and Quarto documents. To keep all files use `"."`.
#'
#' @return Dataframe with columns of `relative_paths` and `absolute_paths` for
#'   file path locations. `absolute_paths` will be urls to raw files.
#'
#' @export
#'
#' @seealso list_files_github_repo, list_files_wd
#'
#' @examples
#' \donttest{
#' library(dplyr)
#' library(funspotr)
#'
#' # pulling and analyzing R file github gists
#' gh_urls <- list_files_github_gists("brshallo")
#'
#' # Will just parse the first 2 files/gists
#' contents <- spot_funs_files(slice(gh_urls, 1:2))
#'
#' contents %>%
#'   unnest_results()
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