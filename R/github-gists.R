
get_gist_pages <- function(user){

  req_user <- httr::GET(
    glue::glue("https://api.github.com/users/{user}")
  )

  num_gists <- httr::content(req_user)$public_gists

  # Number of pages to do (assuming 100 per page)
  num_pages <- num_gists %/% 100
  remainder <- num_gists %% 100
  if(remainder > 0) num_pages <- num_pages + 1

  num_pages
}

get_content <- function(user){

  num_pages <- get_gist_pages(user)

  # gists themselves
  req_content <- vector("list", num_pages)

  for(i in seq_len(num_pages)){

    req <- httr::GET(glue::glue("https://api.github.com/users/{user}/gists"),
                     query = list(per_page = 100,
                                  page = i))

    req_content[[i]] <- httr::content(req)
  }

  purrr::flatten(req_content)

}

#' Get GitHub Gist Urls
#'
#' Given a username, return a dataframe of all the gists by that user. Note that
#' (similar to other `github_*` functions) if run repeatedly may error due to
#' hitting github API rate limits.
#'
#' Returned output does not filter to only R and Rmarkdown files by default, see
#' example for typical use with `funspotr:::str_detect_r_rmd()` -- I use a lot
#' of .md files for gists so should probably write something to parse out the R
#' code chunks from .md files.
#'
#' @param user Character.
#'
#' @return Dataframe with `contents` and `urls` of file paths.
#' @export
#'
#' @examples
#' library(dplyr)
#' library(funspotr)
#'
#' # pulling and analyzing my R file github gists
#' gists_urls <- github_gists("brshallo") %>%
#'   filter(funspotr:::str_detect_r_rmd(contents))
#'
#' gists_urls
#'
#' # Will just parse the first 2 files/gists
#' contents <-
#'   github_spot_funs(custom_urls = slice(gists_urls, 1:2))
#'
#' contents %>%
#'   unnest_github_results()
github_gists <- function(user){

  content <- get_content(user)

  raw_urls <- content %>%
    map("files") %>%
    map(1) %>%
    map_chr("raw_url")

  tibble(contents = fs::path_file(raw_urls), urls = raw_urls)
}
