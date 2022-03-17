
#' Funspotr Network Plot
#'
#' Output simple network plot using
#' [visNetwork](https://github.com/datastorm-open/visNetwork) connecting either
#' `funs` or `pkgs` to `contents`/`urls`.
#'
#' @param df Dataframe containing columns `contents`, `urls` and either `funs`
#'   or `pkgs`. Generally the output from running:
#'   `github_spot_*() %>% unnest_github_results()`
#' @param to `funs` or `pkgs`
#' @param show_each_use Binary, default is `FALSE`. If `TRUE` edge thickness
#'   will be based on the number of times a package or function is used.
#'
#' @return visNetwork plot
#' @export
#'
#' @examples
#' library(dplyr)
#' library(funspotr)
#'
#' gh_ex_pkgs <- github_spot_pkgs(
#'   repo = "brshallo/feat-eng-lags-presentation",
#'   branch = "main")
#'
#' gh_ex_pkgs %>%
#'   unnest_github_results() %>%
#'   network_plot(to = pkgs)
#'
network_plot <- function(df, to = pkgs, show_each_use = FALSE){

  if (!requireNamespace("visNetwork", quietly = TRUE) | !requireNamespace("igraph", quietly = TRUE)) {
    stop("funspotr::network_plot() requires 'visNetwork' and 'igraph' be installed.
         At least one of these seems to be missing.")
  }

  if(!show_each_use) df <- distinct(df, {{to}}, contents, urls)

  ## used colors 1,5,10 from  -- inspired by cranly: https://github.com/ikosmidis/cranly
  # colors <- colorspace::diverge_hcl(10, c = 100, l = c(50, 100), power = 1)

  ## prep nodes and edges data
  nodes_pkgs <- df %>%
    count( {{to}} ) %>%
    select(id = {{to}}, value = n) %>%
    mutate(color = "#ECEEFC",
           shape = "dot") %>%
    mutate(title = paste0("<p><b>", id,"</b><br>"))

  nodes_contents <- df %>%
    count(contents, urls) %>%
    select(id = contents, value = n, urls) %>%
    mutate(color = "#4A6FE3",
           shape = "square") %>%
    mutate(title = paste0("<p><b>", id,"</b><br> ", urls, "</p>"))

  nodes <- bind_rows(nodes_pkgs,
                     nodes_contents) %>%
    mutate(label = id)

  edges <- df %>%
    select(from = contents, to = {{to}}) %>%
    count(from, to) %>%
    rename(value = n) %>%
    # mutate(color = colors[10]) %>% # this messes-up highlighting for some reason
    mutate(title = "in file")

  if(max(edges$value <= 1)) edges <- select(edges, -value)

  ## Set-up legend
  lnodes <- data.frame(label = c("contents / urls", "Packages Used"),
                       color = c("#4A6FE3", "#ECEEFC"),
                       font.align = "top")

  ledges <- data.frame(label = "used/loaded in file",
                       color = "#D33F6A",
                       font.align = "top")

  export_name <- paste0("funspotr-network-", format(Sys.Date(), format = "%Y%m%d"), ".csv")

  visNetwork::visNetwork(nodes,
                         edges,
                         height = "100vh",
                         width = "100%") %>%
    visNetwork::visIgraphLayout(randomSeed = 1) %>%
    visNetwork::visEdges(color = list(highlight = "#D33F6A", hover = "#D33F6A")) %>%
    visNetwork::visOptions(highlightNearest = list(
      enabled = TRUE,
      degree = 1,
      labelOnly = FALSE,
      hover = TRUE
    )) %>%
    visNetwork::visLegend(addNodes = lnodes,
                          addEdges = ledges,
                          useGroups = FALSE) %>%
    visNetwork::visExport(name = export_name,
                          label = "PNG snapshot",
                          style = "")

}
