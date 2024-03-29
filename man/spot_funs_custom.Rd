% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/spot-funs.R
\name{spot_funs_custom}
\alias{spot_funs_custom}
\title{Spot Functions Custom}
\usage{
spot_funs_custom(
  pkgs,
  file_path,
  show_each_use = FALSE,
  keep_search_list = FALSE,
  copy_local = TRUE,
  print_pkgs_load_status = FALSE,
  error_if_missing_pkg = FALSE,
  keep_in_multiple_pkgs = FALSE
)
}
\arguments{
\item{pkgs}{Character vector of packages that are added to search space via
\code{require()} or \code{import::from()} so can be found by \code{utils::find()}.
Generally will be the returned value from \code{spot_pkgs(file_path, show_explicit_funs = TRUE)}.}

\item{file_path}{character vector of path to file.}

\item{show_each_use}{Logical, default is \code{FALSE}. If changed to \code{TRUE} will
return individual rows for each time a function is used (rather than just
once for the entire file).}

\item{keep_search_list}{Logical, default is \code{FALSE}. If changed to \code{TRUE}
will include entire search list for function. May be helpful for debugging
in cases where funspotr may not be doing a good job of recreating the
search list for identifying which packages function(s) came from. This will
print all packages in the search list for each function.}

\item{copy_local}{Logical, if changed to \code{FALSE} will not copy to a local
temporary folder prior to doing analysis. Many functions require file to
already be an .R file and for the file to exist locally. This should
generally not be set to \code{TRUE} unless these hold.}

\item{print_pkgs_load_status}{Logical, default is \code{FALSE}. If set to \code{TRUE}
will print a named vector of logicals showing whether packages are on
machine along with any warning messages that come when running \code{require()}.
Will continue on to produce output of function.}

\item{error_if_missing_pkg}{Logical, default is \code{FALSE}. If set to \code{TRUE} then
\code{print_pkgs_load_status = TRUE} automatically. If a package is not
installed on the machine then will print load status of individual pkgs and
result in an error.}

\item{keep_in_multiple_pkgs}{Logical, default is \code{FALSE}. If set to \code{TRUE}
will include in the outputted dataframe a column \code{in_multiple_pkgs}:
logical, whether a function exists in multiple packages loaded (i.e. on the
search space of \code{utils::find()}.}
}
\value{
Given default arguments and no missing packages, a dataframe with the
following columns is returned:

\code{funs}: specifying functions in file.
\code{pkgs}: the package a function came from. If \code{funs} is a custom function or
if it came from a package not installed on your machine, \code{pkgs} will return
"(unknown)".

Note that any unused loaded packages / \code{pkgs} are dropped from output.
Any functions without an available package are returned with the value
"(unknown)".

See README for further documentation.
}
\description{
Engine that runs \code{spot_funs()}. \code{spot_funs_custom()} has options for changing
returned output and for producing print statements and errors. It also
requires you to provide a character vector for \code{pkgs} rather than identifying
these automatically via \code{spot_pkgs()}.
}
\details{
\code{spot_funs_custom()} is also what you should use in cases where you don't
trust \code{spot_pkgs()} to properly identify package dependencies from within the
same file and instead want to pass in your own character vector of packages.

See README for a description of how the function works.

If a package is not included in \code{pkgs}, any functions called that should come
from that package will be assigned a value of "(unknown)" in the \code{pkgs}
column of the returned output. You can also use the \code{print_pkgs_load_status}
and \code{error_if_missing_pkg} arguments to alter how output works in cases when
not all packages are on the machine.

Explicit calls to unexported functions i.e. \code{pkg:::fun()} will have \code{pkgs = "(unknown)"} in the returned dataframe.
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

pkgs <- spot_pkgs(file_output)

spot_funs_custom(pkgs, file_output)

# If you'd rather it error when a pkg doesn't exist e.g. for {madeUpPkg}
# set`error_if_missing_pkg = TRUE`
}
\seealso{
\code{\link[=spot_funs]{spot_funs()}}
}
