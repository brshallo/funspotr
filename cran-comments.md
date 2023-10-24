## R CMD check results

0 errors | 0 warnings | 0 notes

* This is a new release.

## Resubmission 

This is a resubmission. In this version I have:

* Fixed "Some code lines in examples are commented out."
    * deleted problem example from `spot_funs_custom()`
    * uncommented the example for `spot_tags()` and wrapped it in \dontrun{} (example can only be run interactively from within Rstudio)
    
* I ignored the feedback to 'choose a more meaningful vignette title than "title: This is a post."' The vignette in question, "inst/ex-rmd-tags.Rmd" is simply an example for a YAML header for an example in the README. See line 257 in 'R/README.Rmd' for context.


