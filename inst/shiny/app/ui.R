ui <- shinydashboard::dashboardPage(
    shinydashboard::dashboardHeader(
        title = "Israel Cave Climate Project",
        tags$li(
            id = "nav-button_filter",
            class="dropdown action-button",
            actionButton(
                inputId = "reset_app",
                label = NULL,
                title = "Restore default settings",
                icon = icon("refresh")
                )
            ),
        tags$li(
            id = "nav-button_reload",
            class="dropdown action-button",
            actionButton(
                inputId = "apply_filter",
                label = NULL,
                title = "Apply filter",
                icon = icon("filter")
                )
            ),
        tags$li(
            id = "nav-caves",
            class="dropdown",
            tags$a(
            href = "#",
            "Caves",
            onclick = "handleNavClick('firstRow');"
            )
        ),
        tags$li(
            id = "nav-loggers",
            class="dropdown",
            tags$a(
            href = "#",
            "Loggers",
            onclick = "handleNavClick('secondRow');"
            )
        ),
        tags$li(
            id = "nav-measurements",
            class="dropdown",
            tags$a(
            href = "#",
            "Measurements",
            onclick = "handleNavClick('thirdRow');"
            )
        ),
        tags$li(
            id = "plotHeaderContainer",
            class="dropdown",
            conditionalPanel(
            condition = "input.show_3Row",
            id = "plotHeader",
            uiOutput("header")
            )
        )
        ),
    shinydashboard::dashboardSidebar(
      shinydashboard::sidebarMenu(
        shinydashboard::menuItem(
          "Filters",
          tabName = "filtering",
          icon = icon("chart-line"),
          startExpanded=FALSE,
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
        shinydashboard::menuItem(
          "Plot",
          tabName = "settings",
          icon = icon("wrench"),
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
        shinydashboard::menuItem(
          "Data",
          tabName = "data",
          startExpanded=TRUE,
          icon = icon("floppy-disk"),
          actionButton("view_description1", "Data file details"),
          actionButton("view_description2", "CHELSA data details"),
          selectInput(
            inputId = "save_input",
            label = "Choose df to save",
            choices = NULL,
            multiple = FALSE
          ),
          downloadButton("save_btn", label = "Save"),
          checkboxInput("show_1Row", "Overview", TRUE),
          checkboxInput("show_2Row", "Data scope", TRUE),
          checkboxInput("show_3Row", "Selected data plot", TRUE),
          checkboxInput("show_4Row", "Selected data summary", TRUE)
        )
      )
    ),
    shinydashboard::dashboardBody(
      shinyjs::useShinyjs(),
      shinyjs::extendShinyjs(
        text = " shinyjs.init = function() {
                  $(document).on('click', '.cave-name', function() {
                    let cave = $(this).attr('id');
                    $('#' + cave + '_color').click();
                  });
                }",
                functions = "init"),
        tags$script(HTML(
          " Shiny.addCustomMessageHandler('clickFilterButton', function(message) {
            $('#filter').click();
          });"
          )),
        tags$head(
          tags$script(HTML(
            " function handleNavClick(sectionId) {
                setTimeout(function() {
                  document.getElementById(sectionId).scrollIntoView({ behavior: 'instant'});
                }, 5);

                setTimeout(function() {
                  window.scrollBy(0, -50);
                }, 10);
              }"
          ))
        ),
        tags$style(HTML("
          .pending-changes {
            background-color: #dc3545 !important; /* or any color you prefer */
            color: white !important;
            border-color: #dc3545 !important;
          }
          dropdown .action-button {
            padding: 0 !important;
            margin: 0 auto !important;
            padding-top: 10px !important;
          }
          .main-sidebar {
            position: fixed;
            max-height: 100vh;
            overflow: auto;
          }
          .navbar-custom-menu > .navbar-nav > li {
            display: flex;
            align-items: center;
            }
          .main-header {
            height: 50px !important;
            margin-bottom: 0 !important;
            position: fixed;
            width: 100vw;
          }
          .navbar-custom-menu {
            float: left !important;
            min-width: 93%;
          }
          .navbar-nav {
            float: left !important;
            display: flex !important;
            flex-wrap: nowrap !important;
            justify-content: space-between !important;
            width: 100% !important;
          }
          li {
            font-size: 15px;
            padding: 0 !important;
            padding-top: 15px;
            padding-bottom: 15px;
            }
          
           #nav-button_filter .btn, #nav-button_reload .btn {
            border-radius: 50% !important; 
            font-size: 12px !important;
            width: 30px !important;
            height: 30px !important;
            display: flex !important;
            align-items: center !important;
            justify-content: center !important;
            padding: 0 !important;
            margin: 0 10px !important;
            }



          #plotHeaderContainer  {
            background: none;
            border: none;
            box-shadow: none;
            line-height: 50px;
            padding: 0 15px;
             margin-left: auto;
            flex-grow: 3;
            margin-right: 10px;
          }
          #plotHeader {
            height: 38px;
            min-width: fit-content;
            padding-left: 10px;
            padding-right: 10px;
            margin-top: 6px;
            margin-bottom: 4px;
            display: flex;
            justify-content: center;
            align-items: center;
            font-size: 16px;
            border-radius: 5px;
            box-shadow: 1px 1px 5px #555 inset;
            background-color: white;
          }
          .box {
            margin-bottom: 0;
          }
          .fluidRow {
            display: flex;
            max-height: 90vh;
          }
          .leaflet {
            height: 100% !important;
          }
          .box-body {
            height: 100%;
          }
          #firstRow {
            padding-top: 50px;
          }
          #secondRow {
            margin-top: 50px;
          }
          #thirdRow {
            height: 100%;
          }
          #plot {
            height: 1200px;
          }
          #rangePlot {
              height: 600px
          }
          #metadataCol {
            overflow: auto;
            resize: both;
          }
          .form-group {
            padding: 0 !important;
            width: 80% !important;
            margin-left: 10% !important;
          }
         ")),
      tabName = "data",
      fluidRow(id = "firstRow",
        conditionalPanel(
          condition = "input.show_1Row",
          class = "fluidRow",

          shinydashboard::box(
            id = "mapCol",
            width = 6,
            height = "100%",
            leaflet::leafletOutput("map")
          ),
          shinydashboard::box(
            id = "metadataCol",
            width = 6,
            height = "100%",
            DT::DTOutput("metadata_table")
          )
        )
      ),
      fluidRow(id = "secondRow",
        conditionalPanel(
          condition = "input.show_2Row",
          class = "fluidRow",

          shinydashboard::box(
            id = "rangePlot",
            width = 12,
            plotOutput("dateRangePlot", height = "100%")
          )
        )
      ),
      fluidRow(id = "thirdRow",
        conditionalPanel(
          condition = "input.show_3Row",
          class = "fluidRow",

          shinydashboard::box(
            id = "plot",
            width = 12,
            height = "100%",
            shinycssloaders::withSpinner(
              plotly::plotlyOutput("dataplot"),
              type = 7,
              color.background = "#FFFFFF",
              hide.ui = FALSE)
          )
        )
      ),
      fluidRow(id = "fourthRow",
        conditionalPanel(
          condition = "input.show_4Row",
          class = "fluidRow",
          shinydashboard::box(
            id = "summary",
            width = 12,
            height = "100%",
            verbatimTextOutput("sum")
          )
        )
      )
    )
  )
