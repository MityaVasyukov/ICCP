#' Function retreiving the data from a netcdf file
#'
#' @param file_name netcdf file path/name
#'
#' @return returns a list of data frames
#' @import RNetCDF
#' @import tidyr
#' @import dplyr
#' @importFrom utils capture.output
#' @export
#'
#' @examples
#' filename <- "israel_caves-2024.nc"
#' feedShiny(filename)
#'
feedShiny <- function(file_name = "israel_caves-2024.nc") {

    # SETTINGS #

    ## Start logging ##
    start_time <- Sys.time()

    ## Check if user specified an nc file; if not - load the default data ##
    if (file_name == "israel_caves-2024.nc") {
        file_path <- system.file("extdata", file_name, package = "ICCP")
    } else {
        file_path <- file_name
    }

    ## Loading netcdf file ##
    nc <- tryCatch(RNetCDF::open.nc(file_path), error = function(e) NULL)

    ## Writing metadata on Netcdf file ##
    nc_info <- capture.output(RNetCDF::print.nc(nc))

    ## Check if netcdf file loaded successfully ##
    if (!is.null(nc)) {
    cat("netcdf is ok\n")
    } else {
    stop(cat("Failed to open netcdf file.\n"))
    }

    ## Retrieving the data from netcdf file ##

    ### Generating caves/locations metadata table ###
    caves <- data.frame(
        id = RNetCDF::var.get.nc(nc, "cave"),
        name = RNetCDF::var.get.nc(nc, "Cave_Name"),
        region = RNetCDF::var.get.nc(nc, "Region"),
        longitude = RNetCDF::var.get.nc(nc, "Longitude"),
        latitude = RNetCDF::var.get.nc(nc, "Latitude"),
        elevation = RNetCDF::var.get.nc(nc, "Elevation"),
        length = RNetCDF::var.get.nc(nc, "Total_Length"),
        topography = RNetCDF::var.get.nc(nc, "Topography"),
        phytogeographic_region = RNetCDF::var.get.nc(nc, "Phytogeographic_Region"),
        main_entrance = paste(
            round(RNetCDF::var.get.nc(nc, "Main_Entrance_Width"),1),
            substr(RNetCDF::att.get.nc(nc, "Main_Entrance_Width", "units"), 1, 1),
            "x",
            round(RNetCDF::var.get.nc(nc, "Main_Entrance_Height"),1),
            substr(RNetCDF::att.get.nc(nc, "Main_Entrance_Height", "units"), 1, 1)
        ),
        secondary_entrance = ifelse(
            is.na(RNetCDF::var.get.nc(nc, "Secondary_Entrance_Width")) | is.na(RNetCDF::var.get.nc(nc, "Secondary_Entrance_Height")),
            "",
            paste(
                round(RNetCDF::var.get.nc(nc, "Secondary_Entrance_Width"),1),
                substr(RNetCDF::att.get.nc(nc, "Secondary_Entrance_Width", "units"), 1, 1),
                "x",
                round(RNetCDF::var.get.nc(nc, "Secondary_Entrance_Height"),1),
                substr(RNetCDF::att.get.nc(nc, "Secondary_Entrance_Height", "units"), 1, 1)
            )
        ),
        lithostratigraphy = RNetCDF::var.get.nc(nc, "Lithostratigraphy"),
        cave_formation = RNetCDF::var.get.nc(nc, "Cave_Formation"),
        current_environment = RNetCDF::var.get.nc(nc, "Current_Environment"),
        structure = RNetCDF::var.get.nc(nc, "Structure"),
        research_history = RNetCDF::var.get.nc(nc, "Research_History"),
        findings = RNetCDF::var.get.nc(nc, "Findings"),
        occupation_periods = RNetCDF::var.get.nc(nc, "Occupation_Periods"),
        notes = RNetCDF::var.get.nc(nc, "Notes")
        )

    ### Generating loggers/sensors metadata table ###
    loggers <- data.frame(
        cave_id = apply(RNetCDF::var.get.nc(nc, "logger_cave_mapping"), 1, function(x) which(x == 1)),
        logger_id = RNetCDF::var.get.nc(nc, "logger"),
        light_zone = tolower(RNetCDF::var.get.nc(nc, "Lighting_Zone"))
    ) %>%
    dplyr::left_join( caves[,1:2], by = c("cave_id" = "id") ) %>%
    dplyr::select(cave_id, logger_id, cave_name = name,  light_zone)
    loggers_mapper <-  loggers %>% dplyr::select(logger_id, cave_id)

    ### Generating the dataset ###
    #### Retrieving the data vectors from netcdf file ####
    time_id <- as.integer(RNetCDF::var.get.nc(nc, "time"))
    time <- ICCP::getTimeStamp(nc, "time", time_id)

    temperature <- RNetCDF::var.get.nc(nc, "Temperature")
    dew_point <- RNetCDF::var.get.nc(nc, "Dew_Point")
    rel_humidity <- RNetCDF::var.get.nc(nc, "Relative_Humidity")

    dataset <- data.frame(
        datetime = rep(time, nrow(loggers)),
        logger_id = rep(loggers$logger_id, each = length(time)),
        zone = rep(loggers$light_zone, each = length(time)),
        tm = as.vector(temperature),
        dp = as.vector(dew_point),
        rh = as.vector(rel_humidity)
    ) %>%
    #### removing NA-s ####
    dplyr::filter(!is.na(tm) | !is.na(dp) | !is.na(rh)) %>%
    #### joining with cave_id ####
    dplyr::left_join(loggers_mapper, by = "logger_id")  %>%
    #### grouping by cave_id, time stamp and lighting zone ####
    dplyr::group_by(cave_id, datetime, zone)  %>%
    ### averaging measurements received from the same light zones in the same caves
    dplyr::summarize(
        tm = mean(tm, na.rm = TRUE),
        rh = mean(rh, na.rm = TRUE),
        dp = mean(dp, na.rm = TRUE),
        .groups = 'drop'
    ) %>%
    #### joining with the cave_name ####
    dplyr::left_join(caves, by = c("cave_id" = "id")) %>%
    dplyr::select(datetime, cave_name = name, zone, tm, rh, dp)

    data <- list(nc_info, caves, loggers, dataset)
    RNetCDF::close.nc(nc)
    return(data)
    total_time <- Sys.time() - start_time
    cat(sprintf("\nData retrieving time: %.3f seconds\n\n", as.numeric(total_time, units = "secs")))
}
