
#' Launches a Shiny app to explore Israeli cave climate data.
#'
#' @return
#' This function is primarily invoked for its side effect of launching a Shiny app.
#' It does not return a value but will run the app until it is closed by the user.
#'

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
#' @import magick
#' @import exifr
#'
#' @examples
#' \dontrun{
#' launchApp()
#' }
#'
#' @export
.ICCP_env <- new.env(parent = emptyenv())
launchApp <- function() {

  if (!exists("data", envir = .ICCP_env)) {
    message("Data not found. Fetching data using feedShiny()...")
    .ICCP_env$data <- feedShiny()
  }
  shiny::runApp(system.file("shiny/app", package = "ICCP"))
}
