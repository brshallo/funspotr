#' Spot Tags
#'
#' Put function in your blogdown post's YAML header to have the packages be the
#' packages used in your post (wrapper around `funspotr::spot_pkgs()`).
#'
#' ```
#' tags: ["`r funspotr::spot_tags()`"]
#' ```
#' Note that you must wrap in double quotes.
#'
#' Thanks Yihui for getting this working and for suggesting the function! Note
#' requires blogdown >= 1.9 to work
#' (https://github.com/rstudio/blogdown/issues/647).
#'
#' @param file_path Default is the file being knitted but can change to some
#'   other file (e.g. in cases where the code for the post may reside in a
#'   different file).
#' @param used Default is `FALSE`. If `TRUE` will pass to `show_pkgs_used()`
#'   rather than `show_pkgs()`. (Mainly useful for showing actual packages used
#'   rather than meta-packages being called like `tidyverse` or `tidymodels`).
#' @param drop_knitr Many blogdown posts have `knitr::opts_chunk$set()` in them
#'   and you may not want this tag showing-up. Default is to keep this, but set
#'   to `FALSE` to drop "knitr" from being tagged.
#'
#'   A better approach may be to just skip the "setup" chunk during parsing...
#' @param yaml_bullet Default is `NULL` meaning that `file_path` is read-in and
#'   correct format is guessed based on "spot_tags" appearance with either a
#'   hyphen or bracket (corresponding with bulleted or array format in the YAML
#'   header). See examples for how to hard-code.
#'
#'   If it's first occurrence happens on a line that contains a bracket
#'   the value becomes `FALSE` else it becomes `TRUE`. If set to `NULL` and
#'   "spot_tags" is not detected at all in `file_path` it will default to
#'   `FALSE`. `yaml_bullet` can also be specified directly with either `TRUE` or
#'   `FALSE`. `TRUE` entails that `spot_tags()` is set in a YAML bullet, `FALSE`
#'   indicates the user is inputting it in an array (see examples below).
#'
#' @param ... Any additional arguments to pass to `spot_pkgs*()`.
#'
#' @return String in a format meant to be inserted in tags argument of YAML header.
#' @export
#'
#' @seealso show_pkgs show_pkgs_used
#'
#' @examples
#'
#' ## Put this in your blogdown posts YAML header to autogenerate tags based on pkgs
#' # tags:
#' #   - "`r funspotr::spot_tags()`"
#'
#' ## Can also put this in an array format in your YAML header
#' # tags: ["`r funspotr::spot_tags()`"]
#'
#' ## To review input interactively from within rstudio you might also try:
#' # funspotr::spot_tags(rstudioapi::getSourceEditorContext()$path, drop_knitr = TRUE)
spot_tags <- function(file_path = knitr::current_input(),
                      used = FALSE,
                      drop_knitr = FALSE,
                      yaml_bullet = NULL,
                      ...) {
  if(utils::packageVersion("blogdown") < "1.9"){
    warning("blogdown >= 1.9 needed for this function if `file_path = knitr::current_input()`.", call. = FALSE)
  }

  if(used){
    x <- spot_pkgs_used(file_path, ...)
  } else{
    x <- spot_pkgs(file_path, ...)
  }

  if(drop_knitr) x <- x[x != "knitr"]

  if(is.null(yaml_bullet)){
    lines_file <- readLines(file_path)
    lines_spot_tags <- stringr::str_detect(lines_file, "spot_tags\\(")
    lines_spot_tags <- lines_file[lines_spot_tags]
    if(length(lines_spot_tags) == 0){
      yaml_bullet <- FALSE
      message("`spot_tags` not in file, yaml_bullet defaulting to ", yaml_bullet)
    } else{
      yaml_bullet <- str_detect(lines_spot_tags[[1]], "\\-")
      yaml_bracket <- str_detect(lines_spot_tags[[1]], "\\[")
      if(!yaml_bullet & !yaml_bracket){
        message("`spot_tags` not in line with either a bracket or bullet, yaml_bullet defaulting to ", yaml_bullet)
      } else message("yaml_bullet set to ", yaml_bullet)

    }
  }

  if(yaml_bullet){
    output <- paste(x, collapse = '"\n "')
  } else{
    output <- paste(x, collapse = '", "')
  }

  output
}
