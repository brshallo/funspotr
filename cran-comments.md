## R CMD check results

0 errors | 0 warnings | 0 notes

* This is a new release.

## Resubmission 

This is a resubmission. In this version I have:

* Corrected the "Used ::: in documentation" note
  * I have done this by adding @noRd to several functions and exporting a couple others that were previously left unexported and just making them internal

* I have replaced `\dontrun` with `\donttest` in all examples except for `install_missing_pkgs()`

