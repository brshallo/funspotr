% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/spot-pkgs.R
\name{install_missing_pkgs}
\alias{install_missing_pkgs}
\title{Install missing packages}
\usage{
install_missing_pkgs(pkgs_availability)
}
\arguments{
\item{pkgs_availability}{Named logical vector where names are packages --
generally the output of running \code{check_pkgs_availability()}.}
}
\value{
Installs packages from cran using \code{remotes::install_cran()} if
available else \code{install.packages()}
}
\description{
Attempt to install missing packages from CRAN.
}
\details{
In most cases, is probably safer to clone and use \code{renv::dependencies()} -- README.
}
\examples{
# should verify pkgs are available on CRAN -- example below wouldn't work #
# because madeUpPkg doesn't exist on CRAN
\dontrun{
library(funspotr)
library(dplyr)

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

file_output <- tempfile(fileext = '.R')
writeLines(file_lines, file_output)

spot_pkgs(file_output) \%>\%
  check_pkgs_availability() \%>\%
  funspotr:::install_missing_pkgs()
}
}
