### HELPERS TO MAKE LOCAL TEMPFILES
# `notebook_chunks_to_r_temp()` ; `r_to_r_temp()` ; go into
# `copy_to_local_tempfile()` which is a helper for creating local R temp files
# from other file locations .
# It would probably be more efficient to first have a check whether the file is
# local or not before going straight into making the temp file...

# RMD to local R temp file
# inspiration: https://gist.github.com/noamross/a549ee50e8a4fd68b8b1
# Currently only works on Rmarkdown or quarto documents, to apply to jupyter
# notebooks you'd need to first convert them to .Rmd files which you can do like
# described here: https://stackoverflow.com/a/65683697/9059865
notebook_chunks_to_r_temp <- function(file){

  temp <- tempfile(fileext=".R")

  # needed callr so can use when knitting -- else can bump into "duplicate chunk
  # label" errors when running when knitting
  callr::r(function(file, temp){
    knitr::purl(file, output = temp)
  },
  args = list(file, temp))
}

# R to local R temp file
r_to_r_temp <- function(file, fileext = ".R"){

  lines <- readLines(file, warn = FALSE)
  file_output <- tempfile(fileext = fileext)
  writeLines(lines, file_output)
  file_output
}

# copy R or Rmarkdown or quarto file format to a local temporary R file
copy_to_local_tempfile <- function(file_path){
  if(stringr::str_to_lower(fs::path_ext(file_path)) %in% c("rmd", "rmarkdown", "qmd")){
    file_temp <- notebook_chunks_to_r_temp(file_path)
  } else {
    file_temp <- r_to_r_temp(file_path)

    # remove comments
    formatR::tidy_source(file_temp, file = file_temp, comment = FALSE)

    if(!(stringr::str_to_lower(fs::path_ext(file_path)) %in% c("r", "rmd", "rmarkdown", "qmd"))){
      warning("File extension does not seem to be an R or Rmarkdown or quarto file. File is being processed as though it is a .R file .")
    }
  }

  file_temp
}
