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
#' # tags: ["`r funspotr::spot_tags()`"]
#'
#' ## To reviw input interactively from within rstudio you might also try:
#' # funspotr::spot_tags(rstudioapi::getSourceEditorContext()$path, drop_knitr = TRUE)
spot_tags <- function(file_path = knitr::current_input(),
                      used = FALSE,
                      drop_knitr = FALSE,
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

  paste(x, collapse = '", "')
}
