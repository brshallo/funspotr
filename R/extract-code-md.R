subset_even <- function(x) x[!seq_along(x) %% 2]

extract_rchunks_md <- function(file_path){

  lines <- readr::read_file(file_path) %>%
    stringr::str_split("```.*", simplify = TRUE) %>%
    subset_even() %>%
    stringr::str_flatten("\n## new chunk \n")

  file_output <- tempfile(fileext = ".R")
  writeLines(lines, file_output)
  file_output
}
