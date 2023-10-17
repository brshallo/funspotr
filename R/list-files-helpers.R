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
#' @param pattern Regex pattern to identify file types.
#' @param rmv_index Logical, default to `TRUE`, most repos containing blogdown
#'   sites will have an index.R file at the root. Change to `FALSE` if you don't
#'   want this file removed.
#' @return Logical vector.
#' @examples
#' files <- c("file1.R", "file2.Rmd", "file3.Rmarkdown", "file4.Rproj", "file5.qmd")
#' funspotr:::str_detect_r_docs(files)
str_detect_r_docs <- function(contents,
                              pattern = stringr::regex("(r|rmd|rmarkdown|qmd)$", ignore_case = TRUE),
                              rmv_index = TRUE){
  contents_subset <- str_detect(fs::path_ext(contents), pattern)

  if(rmv_index) contents_subset <- contents_subset & !str_detect(contents, "^index")

  contents_subset
}
