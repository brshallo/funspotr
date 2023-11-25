# funspotr 0.0.4

* Clean-up CRAN documentation (remove unnecessary man files)

# funspotr 0.0.3

* Add support for quarto documents
* In `spot*files()` remove `keep_non_r` argument and add `pattern` argument
* No longer export `github_*` functions 
  (instead use `list_*() |> spot_{pkgs|funs}_files()`)
* Update old [blog post on gists](https://www.bryanshalloway.com/2022/02/07/identifying-r-functions-packages-in-your-github-gists/) so as to be compatible with up-to-date funspotr API
* Publish to CRAN

# funspotr 0.0.2

* Fix quoted library calls not being identified, e.g. `library("dplyr")`

# funspotr 0.0.1

* Initial release and rstudio conf presentation
