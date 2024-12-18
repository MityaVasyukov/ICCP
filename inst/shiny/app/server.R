server <- function(input, output, session) {

  # Load the data

#####     SETTINGS      #####

  ######     setting data sources      ######
  data <- get("data", envir = .GlobalEnv)#ICCP::feedShiny() #
  df <- as.data.frame(data$dataset)
  mdf <- as.data.frame(data$caves)
  exp <- as.data.frame(data$loggers)
  media_path <- system.file("www/images", package = "ICCP")

  ######     adding CHELSA      ######
    chelsa_file_path <- system.file("extdata", "CHELSA.csv", package = "ICCP")
    chelsa <- read.csv(chelsa_file_path)


    chelsa_rows <- unique(chelsa$name) %>%
      dplyr::tibble(name = .) %>%
      dplyr::mutate(
        logger_id = NA_integer_,
        light_zone = "CHELSA",
      ) %>%
      dplyr::left_join(mdf, by = "name",) %>%
      dplyr::select(id, logger_id, name, light_zone, latitude, longitude) %>%
      dplyr::rename(cave_name = name, cave_id = id)
      

    exp <- rbind(exp,chelsa_rows)

    # format CHELSA datase
      chelsa <- chelsa %>%
        tidyr::pivot_longer(cols = c(tas, pr), names_to = "var", values_to = "val") %>%
        dplyr::mutate(zone = "CHELSA") %>%
        dplyr::rename(datetime = date, cave_name = name) %>%
        dplyr::select(datetime, cave_name, zone, var, val)
    
    df <- rbind(df, chelsa)





  ###### style settings ######
  default_cave_colors <- c(
    "Skulls" = "#FF0000",
    "Pool" = "#00FF00",
    "Nahal Hemar" = "#0000FF",
    "Sela" = "#FFFF00",
    "Tzruya" = "#00FFFF",
    "Horror" = "#FF00FF",
    "Ureide" = "#800000",
    "Pitriya" = "#808000",
    "Murbaat 2" = "#008000",
    "Qina" = "#1E90FF",
    "Har Sifsof" = "#008080",
    "Teomim" = "#C0C0C0"
  )

  cave_colors <- reactiveVal(default_cave_colors)

  default_zone_colors <- c(
    "dark" = "#000000",
    "light" = "#f1ee0f",
    "twilight" = "#404040",
    "control" = "#880000"
    )

  zone_colors <- reactiveVal(default_zone_colors)

  zone_styles <- list(
    "dark" = list(
      "background-color" = default_zone_colors["dark"],
      "border" = "1px solid #808080",
      "color" = "#ffffff"
    ),
    "light" = list(
      "background-color" = default_zone_colors["light"],
      "border" = "1px solid #808080",
      "color" = "#000000"
    ),
    "twilight" = list(
      "background-color" = default_zone_colors["twilight"],
      "border" = "1px solid #000000",
      "color" = "#d3d3d3"
    ),
    "control" = list(
      "background-color" = default_zone_colors["control"],
      "border" = "none",
      "color" = "#000000",
      "font-style" = "italic"
    )
  )

  show_file_description <- function(file_path) {
    file_content <- readLines(file_path)
    showModal(
      modalDialog(
        title = "File Description",
        tags$pre(paste(file_content, collapse = "\n")),
        easyClose = TRUE,
        footer = modalButton("Close")
      )
    )
  }

  ###### setting the list of choices and selected choices ######
  observe({
    req(df, mdf, selected_caves())

    freeze_inputs <- c("variable", "cave", "zone", "plot_mode", "units", "resolution", "year", "season", "month", "day", "dateRange", "time")
    lapply(freeze_inputs, function(input_var) freezeReactiveValue(input, input_var))
    updateSelectInput(session, "variable", choices = unique(df$var), selected = c("tm", "rh", "dp") ) # ex: selected = unique(df$var)
    updateSelectizeInput(session, "cave", choices = mdf$name, selected = selected_caves())
    updateSelectizeInput(session, "zone", choices = unique(exp$light_zone), selected = "dark", options = list(maxItems = 1))
    updateSelectInput(session, "plot_mode", choices = c("line", "smooth"), selected = "line")
    updateSelectInput(session, "units", choices = c("C°", "K"), selected = "K")
    updateSelectInput(session, "resolution", choices = c("hours", "days", "months"), selected = "hours")
    updateSelectInput(session, "year", choices = c("all", unique(lubridate::year(df$datetime))), selected = "all")
    updateSelectInput(session, "season", choices = c("any", "winter", "spring", "summer", "autumn"), selected = "any")
    updateSelectInput(session, "month", choices = c("any", month.name), selected = "any")
    updateDateRangeInput(session, "dateRange", min = min(as.Date(df$datetime)), max = max(as.Date(df$datetime)), start = min(as.Date(df$datetime)), end = max(as.Date(df$datetime)))
    updateSliderInput(session, "day", value = c(1, 31))
    updateSliderInput(session, "time", value = c(0, 24))
    updateSelectInput(session, "save_input", choices = c("", "filtered", "dataset", "metadata", "loggers"), selected = NULL)
  })

  ###### dynamic UI rules ######
  observeEvent(input$season, {
    if (input$season != "any") {
      updateSelectInput(session, "month", selected = "any")
    }
  })

  observeEvent(input$month, {
    if (input$month != "any") {
      updateSelectInput(session, "season", selected = "any")
    }
  })

  observe({
    if (input$selection_mode == "zones") {
      updateSelectizeInput(session, "cave", choices = mdf$name, selected = selected_caves()[1], options = list(maxItems = 1))
      updateSelectizeInput(session, "zone", choices = unique(exp$light_zone), selected = "dark", options = list(maxItems = length(unique(exp$light_zone))))
    } else {
      updateSelectizeInput(session, "cave", choices = mdf$name, selected = selected_caves(), options = list(maxItems =  length(unique(mdf$name))))
      updateSelectizeInput(session, "zone", choices = unique(exp$light_zone), selected = "dark", options = list(maxItems = 1))
    }
  })

  selected_caves <- reactiveVal(c("Skulls"))

  ###### filtering data ######
  filtered_data <-  reactive({
    #req(input$resolution, input$cave, input$zone)

    conditions <- list()

    if (!is.null(input$cave)) { conditions <- c(conditions, sprintf("cave_name %%in%% input$cave")) }

    if (!is.null(input$zone)) { conditions <- c(conditions, sprintf("zone %%in%% input$zone")) }

    if (input$year != "all") { conditions <- c(conditions, sprintf("lubridate::year(datetime) == %d", as.numeric(input$year))) }

    if (input$season != "any") {
      seasonMonthes <- list(
        winter = c(1, 2, 12),
        spring = 3:5,
        summer = 6:8,
        autumn = 9:11
      )
      mnths <- seasonMonthes[[input$season]]
      conditions <- c(conditions, sprintf("lubridate::month(datetime) %%in%% c(%s)", paste(mnths, collapse = ",")))
    }

    if (input$month != "any") {
      month_num <- match(input$month, month.name)
      conditions <- c(conditions, sprintf("month(datetime) == %d", month_num))
    }

    if (input$day[1] != 1 || input$day[2] != 31) {
      conditions <- c(conditions, sprintf("day(datetime) >= %s & day(datetime) <= %s", input$day[1], input$day[2] ))
    }

    if (input$time[1] != 0 || input$time[2] != 24) {
      conditions <- c(conditions, sprintf("lubridate::hour(datetime) >= %s & lubridate::hour(datetime) <= %s", input$time[1], input$time[2] ))
    }

    if (input$dateRange[1] > min(as.Date(df$datetime)) | input$dateRange[2] < max(as.Date(df$datetime))) {
      conditions <- c(conditions, sprintf("as.Date(datetime) >= '%s' & as.Date(datetime) <= '%s'", input$dateRange[1], input$dateRange[2]))
    }

    conditions_str <- paste(conditions, collapse = " & ")
    #print(conditions_str) #remove later

    if (length(conditions) == 0) {
      fd <- df
    } else {
        fd <- df %>% dplyr::filter(eval(parse(text = conditions_str)))
        }

    if (input$resolution == "months") {
      data <- fd %>%
        dplyr::mutate(year_month = format(as.Date(datetime), "%Y-%m-01")) %>%
        dplyr::group_by(cave_name, var, zone, year_month) %>%
        dplyr::summarize(mean_val = mean(val, na.rm = TRUE), .groups = 'drop') %>%
        dplyr::rename(datetime = year_month, val = mean_val)
    } else if (input$resolution == "days") {
      data <- fd %>%
        dplyr::mutate(date = as.Date(datetime)) %>%
        dplyr::group_by(cave_name, var, zone, date) %>%
        dplyr::summarize(mean_val = mean(val, na.rm = TRUE), .groups = 'drop') %>%
        dplyr::rename(datetime = date, val = mean_val)
    } else {data <- fd}

    if (nrow(data) == 0) {
      cat("filtered_data -- No data available\n")
      return(NULL)
    }

    #cat("filtered_data -- OK\n") # remove later
    return(data)
  })


  ###### transforming filtered data based on input values ######
  transformed_data <- reactive({
    data <- filtered_data()

    if (is.null(data)) {
      return(NULL)
    }

    if (input$units == "C°") {
      data <- data %>%
        dplyr::mutate(val = ifelse(!var %in% c("rh", "pr") , val - 273.15, val))
    }

    if (input$flatten) {
      data <- ICCP::fitGam(data)
    }

    return(data)
  }) #%>% bindEvent(filtered_data(), input$units, input$flatten)

#####     RENDERING     #####


  ###### map output ######
    output$map <- leaflet::renderLeaflet({
      req(mdf, exp)

      leaflet::leaflet() %>%
        leaflet::addProviderTiles(leaflet::providers$Esri.WorldImagery) %>%
        leaflet::setView(lng = 35.1, lat = 31.4, zoom = 7)
    })


  ###### PHOTOS AND PDF ######
    # Preload photo and pdf paths
    photo_files <- reactive({
      list.files(media_path, full.names = TRUE, pattern = "\\.(jpg|jpeg|png|gif)$", ignore.case = TRUE)
    })

    # Generate slickR object with photos
    slick_photos <- reactive({
      slickR(
        photo_files(),
        height = "100%",
        width = "100%"
      ) + settings(slidesToShow = 1, adaptiveHeight = TRUE)
    })

    observeEvent(input$view_photos, {
      req(input$view_photos$cave)

      cave_name <- gsub(" ", "_", input$view_photos$cave)
      filtered_photos <- grep(cave_name, photo_files(), value = TRUE)

      if (length(filtered_photos) > 0) {
        showModal(modalDialog(
          title = paste(input$view_photos$cave, "cave"),
          size = "l",
          easyClose = TRUE,
          footer = NULL,
          shinycssloaders::withSpinner(
            slickR::slickROutput("photo_carousel", width = "100%", height = "500px"),
            type = 4
          )
        ))

        output$photo_carousel <- slickR::renderSlickR({
          validate(
            need(length(filtered_photos) > 0, "No images found for this cave.")
          )
          slickR::slickR(filtered_photos, height = 500, width = "100%") +
            slickR::settings(slidesToShow = 1, adaptiveHeight = TRUE)
        })
      } else {
        shiny::showModal(modalDialog(
          title = paste("No Photos for", cave_name),
          easyClose = TRUE,
          footer = NULL,
          h4("There are no photos available for this cave.")
        ))
      }
    })

    # PDF
    observeEvent(input$view_pdf, {
      req(input$view_pdf$cave)

      cave_name <- gsub(" ", "_", input$view_pdf$cave)
      filtered_pdfs <- list.files(media_path, full.names = TRUE, pattern = paste0(cave_name, ".*\\.pdf$"), ignore.case = TRUE)

      if (length(filtered_pdfs) > 0) {

          utils::browseURL(filtered_pdfs[1])

      } else {
        showModal(modalDialog(
          title = paste("No PDF for", cave_name),
          easyClose = TRUE,
          footer = NULL,
          h4("No PDF available for this cave.")
        ))
      }
    })



  ###### metadata table output #######
  output$metadata_table <- DT::renderDT({
    #req(selected_caves(), mdf)

    data <- mdf %>%
      dplyr::select(
        "name", "region", "occupation_periods", "elevation", "length", "topography",
        "phytogeographic_region", "main_entrance",
        "secondary_entrance", "lithostratigraphy",
        "cave_formation", "current_environment",
        "structure", "research_history", "findings", "notes")

    selected_caves_list <- selected_caves()

    # Add a 'Photo' button column to the data
    data$photo_button <- sapply(data$name, function(name) {
      paste0(
        '<button class="photo-btn" data-cave="', name, '">Photo</button>',
        ' <button class="pdf-btn" data-cave="', name, '">Scheme</button>'
      )
    })

    # abbreviation dictionary
    # should be taken from netcdf file
    abbreviations <- list(
      "Epi" = "Epipaleolithic",
      "PPN" = "Pre_Pottery Neolithic",
      "PN" = "Pottery Neolithic",
      "LC" = "Late Chalcolithic",
      "EBA" = "Early Bronze Age",
      "IBA" = "Intermediate Bronze Age",
      "MBA" = "Middle Bronze Age",
      "LBA" = "Late Bronze Age",
      "IA" = "Iron Age",
      "PER" = "Persian Period",
      "HEL" = "Hellenistic Period",
      "ROM" = "Roman Period",
      "BYZ" = "Byzantine Period",
      "MAM" = "Mamluk Period",
      "OTT" = "Ottoman Period"
    )

    # convert the abbreviations into clickable links
    data$occupation_periods <- sapply(data$occupation_periods, function(periods) {
      for (abbr in names(abbreviations)) {
        periods <- gsub(
          pattern = paste0("\\b", abbr, "\\b"),
          replacement = sprintf('<a href="#" class="abbr-link" data-abbr="%s">%s</a>', abbr, abbr),
          x = periods,
          fixed = FALSE
        )
      }
      periods
    })

    # building data table
    DT::datatable(
      data,
      escape = FALSE,
      options = list(
        dom = 'ft',
        lengthChange = FALSE,
        pageLength = 12,
        autoWidth = FALSE,
        columnDefs = list(
          list(
            visible = FALSE,
            targets = c(3:(ncol(data)-1))
          ),
          list(
            targets = "_all",
            className = 'details-control'
          )
        ),
        rowCallback = DT::JS(
          'function(row, data, displayNum, displayIndex, dataIndex) {',
          '  var selectedCaves = ', jsonlite::toJSON(selected_caves_list), ';',
          '  if (selectedCaves.indexOf(data[0]) !== -1) {',
          '    $(row).css("background-color", "#FFFF99");',
          '  } else {',
          '    $(row).css("background-color", "");',
          '  }',
          '}'
        )
      ),
      extensions = c('Responsive', 'Buttons'),
      class = "display compact",
      rownames = FALSE,
      callback = DT::JS(
      sprintf("
        // change cursor to pointer when hovering
        $('body').on('mouseenter', 'table.dataTable tbody tr', function() {
          $(this).css('cursor', 'pointer');
        });

        // Handle button click to show the photo modal for the clicked cave
        $('body').on('click', '.photo-btn', function() {
          var caveName = $(this).data('cave');
          var timestamp = new Date().getTime(); // Unique timestamp
          Shiny.setInputValue('view_photos', { cave: caveName, time: timestamp }, { priority: 'event' });
        });

        $('body').on('click', '.pdf-btn', function() {
          var caveName = $(this).data('cave');
          var timestamp = new Date().getTime();
          Shiny.setInputValue('view_pdf', { cave: caveName, time: timestamp }, { priority: 'event' });
        });

        table.on('click', 'tr', function() {
          var row = table.row(this);
          if (row.child.isShown()) {
            row.child.hide();
            $(this).removeClass('shown');
          } else {
            var data = row.data();
            var details = '';
            for (var i = 4; i < data.length; i++) {
              details += '<b>' + table.column(i).header().innerText + ':</b> ' + data[i] + '<br>';
            }
            row.child(details).show();
            $(this).addClass('shown');
          }
        });

        // handle abbreviation hover with delay
        var hoverTimeout;
        $('body').on('mouseenter', '.abbr-link', function(e) {
          var abbr = $(this).data('abbr');
          var descriptions = %s;
          var description = descriptions[abbr];
          var $this = $(this);

          hoverTimeout = setTimeout(function() {
            var popup = $('<div class=\"abbr-popup\"></div>')
              .text(description)
              .css({
                position: 'absolute',
                top: $this.offset().top + $this.outerHeight(),
                left: $this.offset().left,
                border: '1px solid #ccc',
                background: '#fff',
                padding: '5px',
                'z-index': 1000,
                'max-width': '200px'
              })
              .appendTo('body');
            $this.data('popup', popup);
          }, 500); // Delay for 500ms
        });

        $('body').on('mouseleave', '.abbr-link', function() {
          clearTimeout(hoverTimeout);
          var popup = $(this).data('popup');
          if (popup) {
            popup.remove();
            $(this).removeData('popup');
          }
        });
      ", jsonlite::toJSON(abbreviations))
    )
  )
})

  ###### data scope output #######
  output$dateRangePlot <- renderPlot({

    agdf <- df %>%
      dplyr::group_by(cave_name, zone) %>%
      dplyr::summarise(
        start_date = min(datetime),
        end_date = max(datetime),
        .groups = 'drop'
      )

    ggplot2::ggplot(
      agdf,
      ggplot2::aes(
        y = reorder(cave_name, start_date),
        xmin = start_date,
        xmax = end_date,
        color = zone)
    ) +
      ggplot2::geom_errorbarh(
        ggplot2::aes(
          xmin = start_date,
          xmax = end_date
        ),
        height = 0.5,
        linewidth = 1.5,
        position = ggplot2::position_dodge2(width = 0.7)
      ) +
      ggplot2::scale_x_datetime(
        name = "Date",
        date_labels = "%Y-%m-%d",
        date_breaks = "1 month"
      ) +
      ggplot2::scale_y_discrete(name = "Cave") +
      ggplot2::labs(title = "Date ranges for different caves and logger zones within the caves") +
      ggplot2::theme_minimal() +
      ggplot2::theme(
        axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
        axis.text.y = ggplot2::element_text(angle = 0, hjust = 1),
        panel.grid.major.y = ggplot2::element_line(color = "grey80")
      )
  })

  ###### plot header #######
  output$header <- renderUI({
    #req(filtered_data())

    colored_cave_name<- paste0("<span style='color:", cave_colors()[input$cave], "'>", input$cave, "</span>")

    cave_elements <- lapply(input$cave, function(cave) {
      color <- cave_colors()[[cave]]
      cave_id <- gsub(" ", "_", cave)
      tagList(
        span(id = cave_id, class = "cave-name", style = paste0("color:", color, "; cursor: pointer;"), cave),
        tags$input(id = paste0(cave_id, "_color"), type = "color", style = "display:none;", value = color, onchange = sprintf("Shiny.onInputChange('%s_color', this.value)", cave_id))
      )
    })

    cave <- if (length(input$cave) == 1) {
      tagList(cave_elements[[1]], " cave")
    } else {
      tagList(do.call(tagList, cave_elements), " caves")
    }

    if (length(input$zone) > 1) {
      zones <- sapply(input$zone, function(z) {
        zone_style <- zone_styles[[z]]
        zone_style_str <- paste(names(zone_style), zone_style, sep = ": ", collapse = "; ")
        paste0("<span style='", zone_style_str, "'>", toupper(z), "</span>")
      })
      zone_text <- paste(paste(zones, collapse = ", "), " zones")
    } else if (length(input$zone) == 1) {
      zone_style <- zone_styles[[input$zone]]
      zone_style_str <- paste(names(zone_style), zone_style, sep = ": ", collapse = "; ")
      zone_text <- paste0("<span style='", zone_style_str, "'>", toupper(input$zone), " zone</span>")
    } else {
      zone_text <- ""
    }

    HTML(paste("selection:  ", cave, zone_text))
  })


  ###### data plotting ######
  output$dataplot <- plotly::renderPlotly({

    data <- transformed_data()

    if (is.null(data) || nrow(data) == 0) {
      fig <- plotly::plot_ly() %>%
        plotly::add_trace(x = c(0), y = c(0), type = 'scatter', mode = 'text',
                  text = "No data available for the selected filters",
                  textposition = 'middle center',
                  showlegend = FALSE) %>%
        plotly::layout(title = "No Data", xaxis = list(visible = FALSE), yaxis = list(visible = FALSE))
      return(fig)
    } else {
      data$datetime <- as.POSIXct(data$datetime)

      plot_builder <- function(df, var) {
        varname <- switch(
          var,
          "tm" = paste("Temperature,", input$units),
          "rh" = "Relative humidity, %",
          "dp" = paste("Dew point,", input$units),
          "tas" = paste("Mean Air Temperature (CHELSA),", input$units),
          "pr" = "Precipitation, kg/ m2 (CHELSA)",
          "unknown"
        )

        color_aesthetic <- if (input$selection_mode == "caves") "cave_name" else "zone"
        colors <- if (input$selection_mode == "caves") cave_colors() else zone_colors()

        plot <- ggplot2::ggplot(
          df %>% dplyr::filter(var == !!var),
          ggplot2::aes(x = datetime, y = val, color = .data[[color_aesthetic]], text = paste("Variable:", varname))
        ) +
          ggplot2::scale_color_manual(values = colors) +
          ggplot2::theme(
            legend.position = "none",
            axis.text = ggplot2::element_text(color = "black"),
            axis.title = ggplot2::element_text(color = "black"),
            panel.grid.major = ggplot2::element_line(color = "gray", linewidth = 1.5),
            panel.grid.minor = ggplot2::element_blank(),
            axis.line.y = ggplot2::element_line(linewidth = 1.5)
          )  +
          if (var == "tm") { ggplot2::ylab(paste("Temperature,", input$units)) }
        else if (var == "dp") { ggplot2::ylab(paste("Dew point,", input$units)) }
        else if (var == "rh") { ggplot2::ylab("Relative humidity, %") }
        else if (var == "tas") { ggplot2::ylab(paste("Mean Air Temperature (CHELSA),", input$units)) }
        else if (var == "pr") { ggplot2::ylab("Precipitation, kg/ m2 (CHELSA)") }
        else { ggplot2::ylab("Variable") }

        if ("line" %in% input$plot_mode) {
          plot <- plot + ggplot2::geom_line()
        }
        if ("smooth" %in% input$plot_mode) {
          plot <- plot + ggplot2::geom_smooth(method = "gam", formula = y ~ s(x, bs = "cs"))
        }

        plotly::ggplotly(plot, dynamicTicks = TRUE, height = input$height)
      }

      plots <- lapply(input$variable, function(var) plot_builder(data, var))

      fig <- plotly::subplot(
        plots,
        nrows = length(plots),
        titleY = TRUE,
        titleX = FALSE,
        shareX = TRUE
      ) %>%
        plotly::layout(
          xaxis = list(
            type = 'date',
            showgrid = FALSE,
            #rangeslider = list(visible = T),
            rangeselector=list(
              buttons=list(
                list(count=1, label="1d", step="day", stepmode="todate"),
                list(count=7, label="7d", step="day", stepmode="todate"),
                list(count=1, label="1m", step="month", stepmode="todate"),
                list(count=3, label="3m", step="month", stepmode="todate"),
                list(count=6, label="6m", step="month", stepmode="todate"),
                list(count=1, label="1y", step="year", stepmode="todate"),
                list(step="all")
              )
            )
          ),
          yaxis = list(showgrid = TRUE, title = list(standoff = 20)),
          plot_bgcolor = '#ffffff'
        )
      return(fig)
    }
  }) # %>% bindEvent(transformed_data(), input$variable, input$plot_mode, cave_colors(), input$height, input$selection_mode)



  ###### output for summary data ######
  output$sum <- renderPrint({
    data <- transformed_data()

    if (is.null(data)) { return(NULL) }

    summary <- data %>%
      dplyr::group_by(cave_name, var, zone) %>%
      dplyr::summarize(
        mean_val = round(mean(val, na.rm = TRUE), 1),
        min_val = round(ifelse(all(is.na(val)), NA, min(val, na.rm = TRUE)), 1),
        max_val = round(ifelse(all(is.na(val)), NA, max(val, na.rm = TRUE)), 1),
        sd_val = round(sd(val, na.rm = TRUE), 1),
        n = dplyr::n(),
        .groups = 'drop'
      )

    return(as.data.frame(summary))
  }) # %>% bindEvent(transformed_data())


#####      OBSERVERS     #####

  selected_data <- reactive({
    switch(input$save_input,
      "filtered" = filtered_data(),
      "dataset" = df,
      "metadata" = mdf,
      "loggers" = exp,
      NULL
    )
  })

  output$save_btn <- downloadHandler(
    filename = function() {
      paste("ICCP", input$save_input, Sys.Date(), ".csv", sep = "_")
    },
    content = function(file) {
      data_to_save <- selected_data()

      if (is.null(data_to_save)) {
        showNotification("No data selected for saving.", type = "error")
        return(NULL)
      }

      # Notify the user that the process has started
      showNotification("Saving data, please wait...", type = "message", duration = NULL)

      # Generate the CSV file
      write.csv(data_to_save, file, row.names = FALSE)

      # Notify the user that the process is complete
      showNotification("Data saved successfully!", type = "message")
    }
  )

    ###### dynamic map layout ######
    observe({
      selected <- selected_caves()

      leaflet::leafletProxy("map") %>%
        leaflet::clearMarkers() %>%
        leaflet::addCircleMarkers(
          data = mdf,
          lat = ~latitude,
          lng = ~longitude,
          color = ~ifelse(name %in% selected, "yellow", "blue"),
          radius = 5,
          label = ~name,
          stroke = TRUE,
          fillOpacity = 1,
          popup = ~paste(
            "<span style='font-size: 14px;'><b style='font-size: 15px;'>",
            name,
            "</b> cave </span> <br/>",
            "<b style='font-size:15px;'>Region:</b>",
            "<span style='font-size:12px;'>",
            region,
            "</span><br/>",
            "<b style='font-size:15px;'>Elevation:</b>",
            "<span style='font-size:12px;'>",
            elevation,
            "m</span><br/>",
            "<b style='font-size:15px;'>Topography:</b>",
            "<span style='font-size:12px;'>",
            topography,
            "</span><br/>",
            "<form id='popup-form' method='post'>",
            "<button type='button' onclick=\"Shiny.setInputValue('add_cave', '",
            name,
            "', {priority: 'event'})\">Select ",
            name,
            "</button>",
            "</form>"
          )
        ) %>%
        leaflet::addLabelOnlyMarkers(
          data = mdf,
          lng = ~longitude,
          lat = ~latitude,
          label = ~as.character(name),
          group = "mdf_points",
          labelOptions = leaflet::labelOptions(
            noHide = TRUE,
            textOnly = TRUE,
            direction = "auto",
            offset = c(25, 0),
            style = list(
              "font-size" = "15px",
              "font-weight" = "bold",
              "color" = "#000000",
              "text-shadow" = "0px 0px 4px #ffffff"
            )
          )
        )
    })


    ###### plot header coloring ######
    observeEvent(input$cave, {
      lapply(input$cave, function(cave) {
        cave_id <- gsub(" ", "_", cave)

        observeEvent(input[[paste0(cave_id, "_color")]], {
          new_color <- input[[paste0(cave_id, "_color")]]
          colors <- cave_colors()
          colors[[cave]] <- new_color
          cave_colors(colors)
        })
      })
    })

    ###### selected_caves dynamic updating ######
    observeEvent(input$cave, { selected_caves(input$cave) }, ignoreInit = TRUE)

    observeEvent(input$add_cave, {
      #req(input$add_cave)

      current_caves <- trimws(selected_caves())
      new_cave <- trimws(input$add_cave)

      if (!new_cave %in% current_caves) {
        selected_caves(c(current_caves, new_cave))
        updateSelectInput(session, "cave",  selected = selected_caves())
      }
    })

    # Button observers
    observeEvent(input$view_description1, {
      file_path <- system.file("extdata", "israel_caves-2024.txt", package = "ICCP")
      show_file_description(file_path)
    })
    
    observeEvent(input$view_description2, {
      file_path <- system.file("extdata", "caves_CHELSA.txt", package = "ICCP")
      show_file_description(file_path)
    })



}
