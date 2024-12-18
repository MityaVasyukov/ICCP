
#' Launches a Shiny app to explore Israeli cave climate data.
#'
#' @return
#' This function is primarily invoked for its side effect of launching a Shiny app.
#' It does not return a value but will run the app until it is closed by the user.
#'
#' @export
#' @import shiny
#' @import shinydashboard
#' @importFrom shinyjs useShinyjs extendShinyjs
#' @importFrom lubridate year month hour
#' @import dplyr
#' @import leaflet
#' @importFrom DT datatable renderDT DTOutput
#' @import ggplot2
#' @importFrom plotly plot_ly add_trace layout ggplotly subplot plotlyOutput renderPlotly
#' @importFrom shinycssloaders withSpinner
#' @importFrom magrittr %>%
#' @importFrom usethis use_pipe
#' @import slickR
#'
#' @examples
#' \dontrun{
#' data <- feedShiny()
#' launchApp()
#' }
#'
launchApp <- function() {
  if (!exists("data", envir = .GlobalEnv)) {
    stop("data hasn't been added tp the global environment, please, run feedShiny()")
  }
  shiny::runApp(system.file("shiny/app", package = "ICCP"))
}
