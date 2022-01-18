### HELPERS TO MAKE LOCAL TEMPFILES
# `rmd_chunks_to_r_temp()` ; `r_to_r_temp()` ; go into
# `copy_to_local_tempfile()` which is a helper for creating local R temp files
# from other file locations .
# It would probably be more efficient to first have a check whether the file is
# local or not before going straight into making the temp file...

# RMD to local R temp file
# inspiration: https://gist.github.com/noamross/a549ee50e8a4fd68b8b1
rmd_chunks_to_r_temp <- function(file){

  temp <- tempfile(fileext=".R")
  knitr::purl(file, output = temp)

}

# R to local R temp file
r_to_r_temp <- function(file, fileext = ".R"){

  lines <- readLines(file)
  file_output <- tempfile(fileext = fileext)
  writeLines(lines, file_output)
  file_output
}

# copy R or Rmarkdown file format to a local temporary R file
copy_to_local_tempfile <- function(file_path){
  if(stringr::str_to_lower(fs::path_ext(file_path)) %in% c("rmd", "rmarkdown")){
    file_temp <- rmd_chunks_to_r_temp(file_path)
  } else {
    file_temp <- r_to_r_temp(file_path)

    # remove comments
    suppressMessages(formatR::tidy_file(file_temp, comment = FALSE))

    if(stringr::str_to_lower(fs::path_ext(file_path)) != "r"){
      warning("File extension does not seem to be an R or Rmarkdown file. File is being processed as though it is a .R file .")
    }
  }

  file_temp
}
