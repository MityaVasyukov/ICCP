ui <-

  dashboardPage(
    dashboardHeader(title = "Israel Cave Climate Project"),
    dashboardSidebar(
      sidebarMenu(
        menuItem(
          "Data filtering",
          tabName = "filtering",
          icon = icon("dashboard"),
          startExpanded=TRUE,
          radioButtons(
            inputId = "selection_mode",
            label = "Comparison between",
            choices = c("Caves" = "caves", "Zones" = "zones"),
            selected = "caves"
          ),
          selectizeInput(
            inputId = "cave",
            label = "Cave(-s)",
            choices = NULL,
            multiple = TRUE
          ),
          selectizeInput(
            inputId = "zone",
            label = "Lighting zone",
            choices = NULL,
            multiple = TRUE
          ),
          selectInput(
            inputId = "year",
            label = "Year",
            choices = NULL
          ),
          selectInput(
            inputId = "season",
            label = "Season",
            choices = NULL
          ),
          selectInput(
            inputId = "month",
            label = "Month",
            choices = NULL
          ),
          sliderInput(
            inputId = "day",
            label = "Days",
            min = 1,
            max = 31,
            value = c(1,31)
          ),
          dateRangeInput(
            "dateRange",
            label = "Select Date Range:",
            format = "yyyy-mm-dd",
            separator = " - "
          ),
          sliderInput(
            inputId = "time",
            label = "Time",
            min = 0,
            max = 24,
            value = c(0, 24)
          )
        ),
        menuItem(
          "Plot settings",
          tabName = "settings",
          icon = icon("dashboard"),
          startExpanded=FALSE,
          selectInput(
            inputId = "resolution",
            label = "Resolution",
            choices = NULL,
            multiple = FALSE
          ),
          numericInput(
            inputId = "height",
            label = "Subplot height",
            value = 600,
            min = 100,
            max= 1200,
            step = 100
          ),
          selectInput(
            inputId = "variable",
            label = "Variable(-s)",
            choices = NULL,
            multiple = TRUE
          ),

          selectInput(
            inputId = "units",
            label = "Units",
            choices = NULL,
            multiple = FALSE
          ),

          checkboxInput(
            inputId = "flatten",
            label = "Remove seasonal component",
            value = FALSE
          ),
          selectInput(
            inputId = "plot_mode",
            label = "Line type(-s)",
            choices = NULL,
            multiple = TRUE
          )
        ),
        menuItem(
          "Data",
          tabName = "data",
          icon = icon("chart-line"),
          checkboxInput("show_1Row", "Overview", TRUE),
          checkboxInput("show_2Row", "Data scope", TRUE),
          checkboxInput("show_34Row", "Selected data plot", TRUE),
          checkboxInput("show_5Row", "Selected data summary", TRUE)
        )
      )
    ),
    dashboardBody(
      useShinyjs(),
      extendShinyjs(text = "
                shinyjs.init = function() {
                    $(document).on('click', '.cave-name', function() {
                    let cave = $(this).attr('id');
                    $('#' + cave + '_color').click();
                    });
                }
            ", functions = "init"),
      tags$script(HTML("
                Shiny.addCustomMessageHandler('clickFilterButton', function(message) {
                    $('#filter').click();
                });
            ")),
      tags$head(
        tags$style(HTML("
                    .main-sidebar {
                        position: fixed;
                        max-height: 100vh;
                        overflow: auto;
                        }
                    .main-header {
                        height: 50px;
                        position: fixed;
                        width: 100vw;
                        }
                    #firstRow {
                        padding-top: 50px;
                        }
                    .fluidRow {
                        display: flex;
                        max-height: 90vh;
                        }
                    .leaflet {
                        height: 100% !important;
                        }
                    .box-body {
                        height:100%;
                        }
                    #secondRow {
                        margin-top: 50px;\
                    }
                    #thirdRow {
                        margins:0;
                        height: 40px;
                        }
                    #fourthRow {
                        height: 100%;
                        }
                    #plot {
                        height: 1200px;
                        }
                    #rangePlot {
                        height: 600px
                    }
                    #thirdRow .box {
                        background: none;
                        border: none;
                        box-shadow: none;
                        }
                    #plotHeader {
                        padding:0;
                        padding-right: 20px;
                        height: 40px;
                        font-size: 24px;
                        text-align: right;
                        margin: 0;
                        }
                    #metadataCol {
                        overflow: auto;
                        resize: both;
                        }
                ")),
      ),
      tabName = "data",
      fluidRow(
        conditionalPanel(
          condition = "input.show_1Row",
          class = "fluidRow",
          id = "firstRow",
          box(
            id = "mapCol",
            width = 6,
            height = "100%",
            leafletOutput("map")
          ),
          box(
            id = "metadataCol",
            width = 6,
            height = "100%",
            DT::DTOutput("metadata_table")
          )
        )
      ),
      fluidRow(
        conditionalPanel(
          condition = "input.show_2Row",
          class = "fluidRow",
          id = "secondRow",
          box(
            id = "rangePlot",
            width = 12,
            plotOutput("dateRangePlot", height = "100%")
          )
        )
      ),
      fluidRow(
        conditionalPanel(
          condition = "input.show_34Row",
          class = "fluidRow",
          id = "thirdRow",
          box(
            id = "plotHeader",
            width = 12,
            uiOutput("header")
          )
        )
      ),
     fluidRow(
        conditionalPanel(
          condition = "input.show_34Row",
          class = "fluidRow",
          id = "fourthRow",
          box(
            id = "plot",
            width = 12,
            height = "100%",
            withSpinner(
             plotlyOutput("dataplot", height = "100%"),
              type = 7,
              color.background = "#FFFFFF",
              hide.ui = FALSE)
          )
        )
      ),
      fluidRow(
        conditionalPanel(
          condition = "input.show_5Row",
          class = "fluidRow",
          id = "fifthRow",
          box(
            id = "summary",
            width = 12,
            height = "100%",
            verbatimTextOutput("sum")
          )
        )
      )
    )
  )
