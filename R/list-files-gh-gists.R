
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

get_gist_content <- function(user){

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

#' List Github Gists of User
#'
#' Given a username, return a dataframe with paths to all the gists by that user.
#'
#' @param user Character string of username whose github gists you want to pull.
#' @param pattern Regex pattern to keep only matching files. Default is
#'   `stringr::regex("(r|rmd|rmarkdown|qmd)$", ignore_case = TRUE)` which will
#'   keep only R, Rmarkdown and Quarto documents. If you have a lot of .md gists
#'   that can be converted to .R files you may want to edit this argument. To
#'   keep all files use `"."`.
#'
#' @return Dataframe with `relative_paths` and `absolute_paths` of file paths.
#'   Because gists do not exist in a folder structure `relative_paths` will
#'   generally just be a file name. `absolute_paths` a url to the raw file. See
#'   `unnest_results()` for helper to put into an easier to read format.
#'
#' @seealso [list_files_github_repo()], [list_files_wd()]
#' @export
#'
#' @examples
#' \donttest{
#' library(dplyr)
#' library(funspotr)
#'
#' # pulling and analyzing my R file github gists
#' gists_urls <- list_files_github_gists("brshallo", pattern = ".")
#'
#' # Will just parse the first 2 files/gists
#' # Note that is easy to hit the API limit if have lots of gists
#' contents <- filter(gists_urls, str_detect_r_docs(absolute_paths)) %>%
#'   slice(1:2) %>%
#'   spot_funs_files()
#'
#'
#' contents %>%
#'   unnest_results()
#' }
list_files_github_gists <- function(user,
                                    pattern = stringr::regex("(r|rmd|rmarkdown|qmd)$", ignore_case = TRUE)){

  content <- get_gist_content(user)

  raw_urls <- content %>%
    map("files") %>%
    map(1) %>%
    map_chr("raw_url")

  output <- tibble(relative_paths = fs::path_file(raw_urls), absolute_paths = raw_urls)

  filter(output, str_detect_r_docs(.data$relative_paths, pattern = pattern, rmv_index = FALSE))
}


#' #' `r lifecycle::badge("deprecated")`
#' #'
#' #' This function was deprecated with updates to the API that improved
#' #' consistency of naming conventions.
#' github_gists <- function(user, drop_non_r = TRUE){
#'   list_files_github_gists(user, drop_non_r)
#' }
