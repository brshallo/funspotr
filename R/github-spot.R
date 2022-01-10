#' Github Contents
#'
#' List files and folders in a github repo.
#' inspiration: https://stackoverflow.com/a/25485782/9059865
#'
#'
#' @param repo Github user/repo
#' @param branch Default is "main", "master" is likely also common.
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

### github
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

#' Keep only R and Rmarkdown files
#'
#' @param contents Vector of folder and file pathways.
#' @param rmv_index Logical, most repos containing blogdown sites will have an
#'   index.R file. By default these are removed from list of files.
#' @return Subsetted character vector.
#' @examples
#' library(dplyr)
#'
#' funspotr:::github_contents("brshallo/feat-eng-lags-presentation", branch = "main") %>%
#'   funspotr:::str_detect_r_rmd()
str_detect_r_rmd <- function(contents, rmv_index = TRUE){
  contents_lower <- stringr::str_to_lower(contents)
  contents_subset <- str_detect(contents_lower, "\\.(r|rmd|rmarkdown)$")

  if(rmv_index) contents_subset <- contents_subset & !str_detect(contents_lower, "^index")

  contents_subset
}

# engine for `github_spot*()`
github_spot <- function(spot_things, repo, branch = "main", preview = FALSE, rmv_index = TRUE){


  contents_urls <- github_contents_urls(repo, branch)

  contents_urls <- contents_urls %>%
    filter(str_detect_r_rmd(urls, rmv_index))

  if(preview) return(contents_urls)

  output <- contents_urls %>%
    mutate(spotted = map(urls, purrr::possibly(spot_things, otherwise = NULL)))

  output_errors <- filter(output, map_lgl(spotted, is.null))

  if(nrow(output_errors) > 0){
    warning("Did not evaluate properly for the following URL's which were filtered from output:")
    print(ouput_errors)
  }

  # message("Packages should be referenced in the same file as they are used.
  #         See README for example with repo that uses a DESCRIPTION file.")

  filter(output, !map_lgl(spotted, is.null))
}


#' @export
#' @rdname github_spot_things
github_spot_pkgs <- function(repo, branch = "main", preview = FALSE, rmv_index = TRUE){

  github_spot(spot_pkgs, repo, branch, preview, rmv_index)
}

#' @export
#' @rdname github_spot_things
github_spot_funs <- function(repo, branch = "main", preview = FALSE, rmv_index = TRUE){

  github_spot(spot_funs, repo, branch, preview, rmv_index)
}


#' Spot Packages or Functions from Github Repository
#'
#' `github_spot_pkgs()` : Spot all packages that show-up in R or Rmarkdown
#' documents in the github repository.
#'
#' `github_spot_funs()` : Spot all functions and their corresponding packages that
#' show-up in R or Rmarkdown documents in the github repository.
#'
#' Meant for cases where packages and scripts are in *the same* file, in cases
#' where this is not the case will need to build an alternative workflow. See
#' unexported functions in R/github-spot.R for some potentially helpful building
#' blocks.
#'
#' @param repo Github repository, e.g. "brshallo/feat-eng-lags-presentation"
#' @param branch Branch of github repository, default is "main".
#' @param preview Logical, if set to `TRUE` will print urls that will be
#'   passed through `spot_funs()` or `spot_pkgs()` without parsing files.
#' @param rmv_index Logical, most repos containing blogdown sites will have an
#'   index.R file. By default these are removed from list of files.
#'
#' @return Dataframe with `contents` and `urls` of file paths along with a
#'   list-column `spotted` containing packages or functions & packages used in
#'   each file.
#'
#' @seealso spot_pkgs spot_funs
#'
#' @examples
#' library(funspotr)
#'
#' github_spot_funs("brshallo/feat-eng-lags-presentation", branch = "main")
#' @name github_spot_things
NULL


# Clean-up formatting some, e.g. put into searchable table... other stuff
