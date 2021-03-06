% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/list-files-wd.R
\name{list_files_wd}
\alias{list_files_wd}
\title{List Files in Working Directory}
\usage{
list_files_wd(path = ".", keep_non_r = FALSE)
}
\arguments{
\item{path}{Character vector or path. Default is "." which will set the
starting location for \code{relative_paths}.}

\item{keep_non_r}{Logical, default is \code{FALSE} so keeps only records with
\code{relative_paths} ending in "(r|rmd|rmarkdown)$".}
}
\value{
Dataframe with columns of \code{relative_paths} and \code{absolute_paths}.
}
\description{
Return a dataframe containing the paths of files in the working directory.
Generally used prior to \verb{spot_\{funs/pkgs\}_files()}.
}
\details{
Can also be used outside of working directory if \code{path} is specified.
}
\examples{
\dontrun{
library(dplyr)
library(funspotr)

# pulling and analyzing my R file github gists
files_local <- list_files_wd()

# Will just parse the first 2 files/gists
contents <- spot_funs_files(slice(files_local, 1:2))

contents \%>\%
  unnest_results()
}
}
\seealso{
\code{\link[=list_files_github_repo]{list_files_github_repo()}}, \code{\link[=list_files_github_gists]{list_files_github_gists()}}
}
