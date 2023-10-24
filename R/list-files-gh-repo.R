# taken from here: https://stackoverflow.com/a/60627969/9059865
valid_url <- function(url_in,t=2){
  con <- url(url_in)
  check <- suppressWarnings(try(open.connection(con,open="rt",timeout=t),silent=T)[1])
  suppressWarnings(try(close.connection(con),silent=T))
  ifelse(is.null(check),TRUE,FALSE)
}


#' Github Contents
#'
#' List files and folders in a github repo.
#' inspiration: https://stackoverflow.com/a/25485782/9059865
#'
#' @param repo Github user/repo
#' @param branch Default is `NULL` which will test "main" and then if that is
#'   invalid, "master".
#'
#' @return Character vector of contents from github repo.
github_contents <- function(repo, branch = NULL){

  # default try `branch = "main", if doesn't work try `branch = "master"`
  if(is.null(branch)){
    branch <- "main"
    url_test <- glue::glue("https://api.github.com/repos/{repo}/git/trees/{branch}?recursive=1")

    if(!valid_url(url_test)) branch <- "master"
  }

  req <- httr::GET(glue::glue("https://api.github.com/repos/{repo}/git/trees/{branch}?recursive=1"))
  httr::stop_for_status(req)
  filelist <- unlist(lapply(httr::content(req)$tree, "[", "path"), use.names = F)
  filelist
}

# Given github repo, branch, file, returns a github URL to the raw content
github_rbf_to_url <- function(repo, branch, file) glue::glue("https://raw.githubusercontent.com/{repo}/{branch}/{file}")

#' Github Contents and URLS
#'
#' Runs `funspotr:::github_contents()` and then maps this through
#' `github_rbf_to_url()` returning URL's to the "raw" location.
#'
#' @inheritParams github_contents
#'
#' @return Dataframe with columns `relative_paths` and `absolute_paths`.
github_contents_urls <- function(repo, branch = "main"){
  # This step should probably be taken out of the function and instead it should
  # be to pass in a list of files and then select only the r versions... maybe
  contents <- tibble(
    relative_paths = github_contents(repo, branch)
  )

  contents_urls <- contents %>%
    mutate(absolute_paths = map_chr(
      .data$relative_paths,
      github_rbf_to_url,
      repo = repo,
      branch = branch
    ))

  contents_urls
}

# engine for `github_spot_funs()` and `github_spot_pkgs()`
github_spot <-
  function(spot_type, # get_funs or get_pkgs
           repo,
           branch = "main",
           ...,
           preview = FALSE,
           rmv_index = TRUE,
           custom_urls = NULL) {

  if(is.null(custom_urls)){
    contents_urls <- github_contents_urls(repo, branch)

    contents_urls <- contents_urls %>%
      filter(str_detect_r_docs(.data$relative_paths, rmv_index))

  } else contents_urls <- custom_urls

  if(preview) return(contents_urls)

  safe_spot_type <- purrr::safely(spot_type)

  output <- contents_urls %>%
    mutate(spotted = map(.data$absolute_paths, safe_spot_type, ...))

  output_errors <- filter(output, did_safely_error(.data$spotted))

  if(nrow(output_errors) > 0){
    warning("Did not evaluate properly for the following absolute_paths: ", output_errors$paths)
  }

  # message("Packages should be referenced in the same file as they are used.
  #         See README for example with repo that uses a DESCRIPTION file.")

  # message(
  #   "Each item in `spotted` column is a `purrr::safely()` named list containing 'result' and 'error'.
  #   See `funspotr::unnest_results()` to remove rows with errors and unnest 'result' column."
  # )
  output
}

#' @rdname github_spot_things
github_spot_pkgs <-
  function(repo,
           branch = "main",
           ...,
           preview = FALSE,
           rmv_index = TRUE,
           custom_urls = NULL) {

    lifecycle::deprecate_warn("0.0.1",
                              "github_spot_funs()",
                              "list_files_github_repo() |> spot_pkgs_files()")

  github_spot(spot_pkgs, repo, branch, ..., preview = preview, rmv_index = rmv_index, custom_urls = custom_urls)
}

#' @rdname github_spot_things
github_spot_funs <-
  function(repo,
           branch = "main",
           ...,
           preview = FALSE,
           rmv_index = TRUE,
           custom_urls = NULL
  ){

  lifecycle::deprecate_warn("0.0.1",
                            "github_spot_funs()",
                            "list_files_github_repo() |> spot_funs_files()")
  github_spot(spot_funs, repo, branch, ..., preview = preview, rmv_index = rmv_index, custom_urls = custom_urls)
}


#' Spot Packages or Functions from Github Repository
#' @description
#' `r lifecycle::badge("deprecated")`
#'
#' These function were deprecated with updates to the API that modularized this
#' functionality into two steps `list_files_*()` and `spot_*()`.
#'
#' `github_spot_pkgs()` : Spot all packages that show-up in R or Rmarkdown
#' documents in the github repository. Essentially a wrapper for mapping
#' `spot_pkgs()` across multiple files.
#'
#' `github_spot_funs()` : Spot all functions and their corresponding packages
#' that show-up in R or Rmarkdown documents in the github repository.
#' Essentially a wrapper for mapping `spot_pkgs()` across multiple files.
#'
#' Meant for cases where packages and scripts are in *the same* file. In cases
#' where this is not the case will need to build an alternative workflow. See
#' unexported functions in R/github-spot.R for some potentially helpful building
#' blocks.
#'
#' @param repo Github repository, e.g. "brshallo/feat-eng-lags-presentation"
#' @param branch Branch of github repository, default is "main".
#' @param ... Arguments passed onto `spot_*()`.
#' @param preview Logical, if set to `TRUE` will return dataframe of urls that
#'   will be passed through `spot_funs()` or `spot_pkgs()` without parsing
#'   files. See README for example of how this can be combined with
#'   `custom_urls` to only parse a subset of files identified.
#' @param rmv_index Logical, most repos containing blogdown sites will have an
#'   index.R file at the root. Change to `FALSE` if you don't want this file
#'   removed.
#' @param custom_urls Option to pass in a dataframe with columns `contents` and
#'   `urls` to override the default urls in the repo to parse. Default is
#'   `NULL`. See README for example.
#'
#'
#' @return Dataframe with `relative_paths` and `absolute_paths` of file paths
#'   along with a list-column `spotted` containing `purrr::safely()` lists of
#'   "result" and "error" for each file parsed. See `unnest_results()`
#'   for helper to put into an easier to read format.
#'
#' @seealso spot_pkgs spot_funs spot_funs_custom unnest_results
#'
#' @keywords internal
#' @name github_spot_things
NULL


#' List Files in Github Repo
#'
#' Return a dataframe containing the paths of files in a github repostiory.
#' Generally used prior to `spot_{funs/pkgs}_files()`.
#'
#' @param repo Github repository, e.g. "brshallo/feat-eng-lags-presentation"
#' @param branch Branch of github repository, default is "main".
#' @param pattern Regex pattern to keep only matching files. Default is
#'   `stringr::regex("(r|rmd|rmarkdown|qmd)$", ignore_case = TRUE)` which will
#'   keep only R, Rmarkdown and Quarto documents. To keep all files use `"."`.
#' @param rmv_index Logical, most repos containing blogdown sites will have an
#'   index.R file at the root. Change to `FALSE` if you don't want this file
#'   removed.
#'
#' @return Dataframe with columns of `relative_paths` and `absolute_paths` for
#'   file path locations. `absolute_paths` will be urls to raw files.
#'
#' @export
#'
#' @seealso [list_files_wd()], [list_files_github_gists()]
#'
#' @examples
#' \donttest{
#' library(dplyr)
#' library(funspotr)
#'
#' # pulling and analyzing my R file github gists
#' gh_urls <- list_files_github_repo("brshallo/feat-eng-lags-presentation", branch = "main")
#'
#' # Will just parse the first 2 files/gists
#' contents <- spot_funs_files(slice(gh_urls, 1:2))
#'
#' contents %>%
#'   unnest_results()
#' }
list_files_github_repo <- function(repo,
                                   branch = NULL,
                                   pattern = stringr::regex("(r|rmd|rmarkdown|qmd)$", ignore_case = TRUE),
                                   rmv_index = TRUE) {

  # test "main" and then "master" branch if not specified
  if(is.null(branch)){
    branch <- "main"
    url_test <- glue::glue("https://api.github.com/repos/{repo}/git/trees/{branch}?recursive=1")

    if(!valid_url(url_test)) branch <- "master"
  }

  contents_urls <- github_contents_urls(repo, branch)

  filter(contents_urls, str_detect_r_docs(.data$relative_paths, pattern = pattern, rmv_index = rmv_index))

}

