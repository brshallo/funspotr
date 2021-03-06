% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/spot-funs.R
\name{call_r_list_functions_doc}
\alias{call_r_list_functions_doc}
\alias{call_r_list_functions}
\alias{call_r_list_functions_explicit}
\title{Call R List Functions}
\usage{
call_r_list_functions(pkgs, file_temp, show_each_use = FALSE)

call_r_list_functions_explicit(
  pkgs,
  pkgs_explicit,
  file_temp,
  show_each_use = FALSE
)
}
\arguments{
\item{pkgs}{Character vector of packages loaded via library, require, etc,}

\item{file_temp}{character vector of path to file. In most cases will be a
temporary file.}

\item{show_each_use}{Logical, default is \code{FALSE}. If changed to \code{TRUE} will
return individual rows for each time a function is used (rather than just
once for the entire file).}

\item{pkgs_explicit}{Packages used explicitly, e.g. \code{pkg::fun()}.}
}
\description{
The next several function are all created to make namespaces \emph{slightly}
better -- honestly not sure is worth the added complexity this created. But
what I do is essentially: if there are no explicit function calls (i.e.
pkg::fun() ) \code{spot_funs()} / \code{spot_funs_custom()} will run
\code{call_r_list_functions()} to identify functions and packages, but if there
are explicit functions it will run \code{call_r_list_functions_explicit()} which
does the same thing as \code{call_r_list_functions()} except it first loads any
regular packages AND THEN attaches any explicit function calls -- this has
the impact of giving explicit function calls precedence in terms of being
identified while not attaching the entire package (the way prior approaches
did). This still has problems in some cases but on the whole I think is
better... These functions use the {import} package to manage this process and
takes the approach described here:
https://github.com/rticulate/import/issues/57
}
