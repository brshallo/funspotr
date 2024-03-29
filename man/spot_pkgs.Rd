% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/spot-pkgs.R
\name{spot_pkgs}
\alias{spot_pkgs}
\title{Spot Packages}
\usage{
spot_pkgs(
  file_path,
  show_explicit_funs = FALSE,
  copy_local = TRUE,
  as_yaml_tags = FALSE
)
}
\arguments{
\item{file_path}{String of path to file of interest.}

\item{show_explicit_funs}{In cases where a function is called explicitly,
show both the package dependency and the function together. For example a
script containing \code{dplyr::select()} (as opposed to \verb{library(dplyr); select()}) would have \code{spot_pkgs(show_explicit_funs = TRUE)} return the
item as "dplyr::select" rather than just "dplyr")}

\item{copy_local}{Logical, default is \code{TRUE}. If changed to \code{FALSE} will not
copy to a local temporary folder prior to doing analysis. Many processes
require file to already be a .R file and for the file to exist locally,
hence this should usually be set to \code{TRUE}.}

\item{as_yaml_tags}{Logical, default is \code{FALSE}. If set to \code{TRUE} flattens
and puts into a format convenient for pasting in "tags" section of YAML
header of  a Rmd document for a blogdown post.}
}
\value{
Character vector of all packages loaded in file.
}
\description{
Extract all \code{pkg} called in either \code{library(pkg)}, \code{require(pkg)}
\code{requireNamespace("pkg")} or \code{pkg::fun()}. Will not identify packages loaded
in other ways not typically done in interactive R scripts (e.g. relying on a
DESCRIPTION file for a pkg or something like \code{source("lib-calls.R")}).
Inspiration: \href{https://github.com/rstudio/blogdown/issues/647}{blogdown#647}.
}
\details{
In cases where \code{show_explicit_funs = TRUE} and there are explicit calls in
the package, "pkg:fun" is returned instead.

Packages are extracted solely based on text -- not whether the
package actually exists or not. Hence even packages that you do not have
installed on your machine but show-up in the script will be returned in the
character vector.
}
\examples{
library(funspotr)

file_lines <- "
library(dplyr)
require(tidyr)
library(madeUpPkg)

as_tibble(mpg) \%>\%
  group_by(class) \%>\%
  nest() \%>\%
  mutate(stats = purrr::map(data,
                            ~lm(cty ~ hwy, data = .x)))

made_up_fun()
"

file_output <- tempfile(fileext = ".R")
writeLines(file_lines, file_output)

spot_pkgs(file_output)

# To view `purrr::map` as an explicit call
spot_pkgs(file_output, show_explicit_funs = TRUE)

# To output for blogdown post YAML header tags
cat(spot_pkgs(file_output, as_yaml_tags = TRUE))
}
\seealso{
\code{\link[=spot_pkgs_used]{spot_pkgs_used()}}, \code{\link[=spot_pkgs_from_description]{spot_pkgs_from_description()}},
\code{\link[=spot_pkgs_files]{spot_pkgs_files()}}, \code{renv::dependencies()}
}
