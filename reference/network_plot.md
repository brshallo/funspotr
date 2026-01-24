# funspotr Network Plot

Output simple network plot using
[visNetwork](https://github.com/datastorm-open/visNetwork) connecting
either `funs` or `pkgs` to `relative_paths`/`absolute_paths`.

## Usage

``` r
network_plot(df, to = .data$pkgs, show_each_use = FALSE)
```

## Arguments

- df:

  Dataframe containing columns `relative_paths`, `absolute_paths` and
  either `funs` or `pkgs`. Generally the output from running:
  `github_spot_*() %>% unnest_results()`

- to:

  `funs` or `pkgs`

- show_each_use:

  Binary, default is `FALSE`. If `TRUE` edge thickness will be based on
  the number of times a package or function is used.

## Value

visNetwork plot

## Examples

``` r
# \donttest{
library(dplyr)
library(funspotr)

gh_ex_pkgs <- list_files_github_repo(
  repo = "brshallo/feat-eng-lags-presentation",
  branch = "main") %>%
  spot_funs_files()

gh_ex_pkgs %>%
  unnest_results() %>%
  network_plot(to = pkgs)

{"x":{"nodes":{"id":["(unknown)","base","here","httr","jsonlite","knitr","stats","R/Rmd-to-R.R","R/feat-engineering-lags.R","R/load-inspections-save-csv.R","R/types-of-splits.R"],"value":[3,3,2,1,1,2,2,2,4,6,2],"color":["#ECEEFC","#ECEEFC","#ECEEFC","#ECEEFC","#ECEEFC","#ECEEFC","#ECEEFC","#4A6FE3","#4A6FE3","#4A6FE3","#4A6FE3"],"shape":["dot","dot","dot","dot","dot","dot","dot","square","square","square","square"],"title":["<p><b>(unknown)<\/b><br>","<p><b>base<\/b><br>","<p><b>here<\/b><br>","<p><b>httr<\/b><br>","<p><b>jsonlite<\/b><br>","<p><b>knitr<\/b><br>","<p><b>stats<\/b><br>","<p><b>R/Rmd-to-R.R<\/b><br> https://raw.githubusercontent.com/brshallo/feat-eng-lags-presentation/main/R/Rmd-to-R.R<\/p>","<p><b>R/feat-engineering-lags.R<\/b><br> https://raw.githubusercontent.com/brshallo/feat-eng-lags-presentation/main/R/feat-engineering-lags.R<\/p>","<p><b>R/load-inspections-save-csv.R<\/b><br> https://raw.githubusercontent.com/brshallo/feat-eng-lags-presentation/main/R/load-inspections-save-csv.R<\/p>","<p><b>R/types-of-splits.R<\/b><br> https://raw.githubusercontent.com/brshallo/feat-eng-lags-presentation/main/R/types-of-splits.R<\/p>"],"absolute_paths":[null,null,null,null,null,null,null,"https://raw.githubusercontent.com/brshallo/feat-eng-lags-presentation/main/R/Rmd-to-R.R","https://raw.githubusercontent.com/brshallo/feat-eng-lags-presentation/main/R/feat-engineering-lags.R","https://raw.githubusercontent.com/brshallo/feat-eng-lags-presentation/main/R/load-inspections-save-csv.R","https://raw.githubusercontent.com/brshallo/feat-eng-lags-presentation/main/R/types-of-splits.R"],"label":["(unknown)","base","here","httr","jsonlite","knitr","stats","R/Rmd-to-R.R","R/feat-engineering-lags.R","R/load-inspections-save-csv.R","R/types-of-splits.R"],"x":[0.4291964064115452,0.6105500229761882,-0.4225224362135931,1,0.4885569534754264,-0.7978087005594057,-0.0139460783711558,-1,-0.07141759977072704,0.3824444193673517,0.8955266653175649],"y":[0.6722669212956773,0.4559812945740722,-0.4029095520146737,-0.6100566147677688,-1,0.5839633312792263,0.1244574917857433,-0.04094216877061563,0.6611870815932168,-0.2150466028155888,1]},"edges":{"from":["R/Rmd-to-R.R","R/Rmd-to-R.R","R/feat-engineering-lags.R","R/feat-engineering-lags.R","R/feat-engineering-lags.R","R/feat-engineering-lags.R","R/load-inspections-save-csv.R","R/load-inspections-save-csv.R","R/load-inspections-save-csv.R","R/load-inspections-save-csv.R","R/load-inspections-save-csv.R","R/load-inspections-save-csv.R","R/types-of-splits.R","R/types-of-splits.R"],"to":["here","knitr","(unknown)","base","knitr","stats","(unknown)","base","here","httr","jsonlite","stats","(unknown)","base"],"title":["in file","in file","in file","in file","in file","in file","in file","in file","in file","in file","in file","in file","in file","in file"]},"nodesToDataframe":true,"edgesToDataframe":true,"options":{"width":"100%","height":"100%","nodes":{"shape":"dot","physics":false},"manipulation":{"enabled":false},"edges":{"smooth":false,"color":{"highlight":"#D33F6A","hover":"#D33F6A"}},"physics":{"stabilization":false},"interaction":{"hover":true,"zoomSpeed":1}},"groups":null,"width":"100%","height":"100vh","idselection":{"enabled":true,"style":"width: 150px; height: 26px","useLabels":true,"main":"Select by id"},"byselection":{"enabled":false,"style":"width: 150px; height: 26px","multiple":false,"hideColor":"rgba(200,200,200,0.5)","highlight":false},"main":null,"submain":null,"footer":null,"background":"rgba(0, 0, 0, 0)","igraphlayout":{"type":"square"},"tooltipStay":300,"tooltipStyle":"position: fixed;visibility:hidden;padding: 5px;white-space: nowrap;font-family: verdana;font-size:14px;font-color:#000000;background-color: #f5f4ed;-moz-border-radius: 3px;-webkit-border-radius: 3px;border-radius: 3px;border: 1px solid #808074;box-shadow: 3px 3px 10px rgba(0, 0, 0, 0.2);","highlight":{"enabled":false,"hoverNearest":false,"degree":1,"algorithm":"all","hideColor":"rgba(200,200,200,0.5)","labelOnly":true},"collapse":{"enabled":false,"fit":false,"resetHighlight":true,"clusterOptions":null,"keepCoord":true,"labelSuffix":"(cluster)"},"legend":{"width":0.2,"useGroups":false,"position":"left","ncol":1,"stepX":100,"stepY":100,"zoom":true,"edges":{"label":["used/loaded in file"],"color":["#D33F6A"],"font.align":["top"]},"edgesToDataframe":true,"nodes":{"label":["relative / absolute","Packages Used"],"color":["#4A6FE3","#ECEEFC"],"font.align":["top","top"]},"nodesToDataframe":true},"export":{"type":"png","css":"float:right;","background":"#fff","name":"funspotr-network-20260124.csv.png","label":"PNG snapshot"}},"evals":[],"jsHooks":[]}# }
```
