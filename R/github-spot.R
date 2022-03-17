#' Did Safely Error
#'
#' @return logical vector
did_safely_error <- function(safely_named_list){

  map(safely_named_list, "error") %>%
    map_lgl(is.null) %>%
    {!.}
}

#' Github Contents
#'
#' List files and folders in a github repo.
#' inspiration: https://stackoverflow.com/a/25485782/9059865
#'
#' @param repo Github user/repo
#' @param branch Default is "main"; "master" is also common.
#'
#' @return Character vector of contents from github repo.
#'
#' @examples
#'
#' funspotr:::github_contents("brshallo/feat-eng-lags-presentation", branch = "main")
github_contents <- function(repo, branch = "main"){

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
#' @return Dataframe with columns `contents` and `urls`.
#' @examples
#'
#' funspotr:::github_contents_urls("brshallo/feat-eng-lags-presentation", branch = "main")
github_contents_urls <- function(repo, branch = "main"){
  # This step should probably be taken out of the function and instead it should
  # be to pass in a list of files and then select only the r versions... maybe
  contents <- tibble(
    contents = github_contents(repo, branch)
  )

  contents_urls <- contents %>%
    mutate(urls = map_chr(contents, github_rbf_to_url, repo = repo, branch = branch))

  contents_urls
}

#' String Detect R or Rmarkdown File endings
#'
#' Return `TRUE` for only R and Rmarkdown files, else `FALSE`.
#'
#' @param contents Character vector of file path.
#' @param rmv_index Logical, most repos containing blogdown sites will have an
#'   index.R file at the root. Change to `TRUE` if you don't want this file
#'   removed.
#' @return Logical vector.
#' @examples
#' files <- c("file1.R", "file2.Rmd", "file3.Rmarkdown", "file4.Rproj")
#' funspotr:::str_detect_r_rmd(files)
str_detect_r_rmd <- function(contents, rmv_index = TRUE){
  contents_lower <- stringr::str_to_lower(contents)
  contents_subset <- str_detect(fs::path_ext(contents_lower), "(r|rmd|rmarkdown)$")

  if(rmv_index) contents_subset <- contents_subset & !str_detect(contents_lower, "^index")

  contents_subset
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
      filter(str_detect_r_rmd(contents, rmv_index))

  } else contents_urls <- custom_urls

  if(preview) return(contents_urls)

  safe_spot_type <- purrr::safely(spot_type)

  output <- contents_urls %>%
    mutate(spotted = map(urls, safe_spot_type, ...))

  output_errors <- filter(output, did_safely_error(spotted))

  if(nrow(output_errors) > 0){
    warning("Did not evaluate properly for the following URL's: ", output_errors$urls)
  }

  # message("Packages should be referenced in the same file as they are used.
  #         See README for example with repo that uses a DESCRIPTION file.")

  # message(
  #   "Each item in `spotted` column is a `purrr::safely()` named list containing 'result' and 'error'.
  #   See `funspotr::unnest_github_results()` to remove rows with errors and unnest 'result' column."
  # )
  output
}

#' @export
#' @rdname github_spot_things
github_spot_pkgs <-
  function(repo,
           branch = "main",
           ...,
           preview = FALSE,
           rmv_index = TRUE,
           custom_urls = NULL) {


  github_spot(spot_pkgs, repo, branch, ..., preview = preview, rmv_index = rmv_index, custom_urls = custom_urls)
}

#' @export
#' @rdname github_spot_things
github_spot_funs <-
  function(repo,
           branch = "main",
           ...,
           preview = FALSE,
           rmv_index = TRUE,
           custom_urls = NULL
  ){

  github_spot(spot_funs, repo, branch, ..., preview = preview, rmv_index = rmv_index, custom_urls = custom_urls)
}


#' Spot Packages or Functions from Github Repository
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
#'   index.R file at the root. Change to `TRUE` if you don't want this file
#'   removed.
#' @param custom_urls Option to pass in a dataframe with columns `contents` and
#'   `urls` to overrride the default urls in the repo to parse. Default is
#'   `NULL`. See README for example.
#'
#'
#' @return Dataframe with `contents` and `urls` of file paths along with a
#'   list-column `spotted` containing `purrr::safely()` lists of "result" and
#'   "error" for each file parsed. See `unnest_github_results()` for helper to
#'   put into an easier to read format.
#'
#' @seealso spot_pkgs spot_funs spot_funs_custom unnest_github_results
#'
#' @seealso spot_pkgs spot_funs
#'
#' @examples
#' library(funspotr)
#'
#' github_spot_funs("brshallo/feat-eng-lags-presentation", branch = "main")
#'
#' # Say you only want to parse a subset of the R file discovered, you could do
#' # something like:
#' library(dplyr)
#'
#' github_spot_funs("brshallo/feat-eng-lags-presentation", branch = "main", preview = TRUE) %>%
#'   slice(1:2) %>%
#'   github_spot_funs(custom_urls = .)
#' @name github_spot_things
NULL


#' Unnest Github Results
#'
#' After running `github_spot()`
#'
#' @param df Dataframe outputted by `github_spot*()` that contains a `spotted` list-column.
#'
#' @return An unnested dataframe
#' @export
#'
#' @examples
#' library(funspotr)
#' library(dplyr)
#'
#' github_spot_funs("brshallo/feat-eng-lags-presentation", branch = "main") %>%
#'   unnest_github_results()
unnest_github_results <- function(df){
  output <- df %>%
    filter(!did_safely_error(spotted)) %>%
    mutate(spotted = map(spotted, "result")) %>%
    relocate(spotted) %>%
    unnest(spotted)

  if(any(names(output) == "spotted")) output <- rename(output, pkgs = spotted)

  output
}
