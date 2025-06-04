#' Fetching the data from CHELSA project for each cave
#' @return returns a table of daily mean temperature and precipitation for each cave for the longest time period of a certain logger set in the cave

#' @import dplyr
#' @import tibble
#' @import purrr
#' @export
#'

get_CHELSA <- function() {
    # curl issues fix
        old_ca <- Sys.getenv("CURL_CA_BUNDLE", unset = NA)
        old_ssl <- Sys.getenv("SSL_CERT_FILE", unset = NA)
        Sys.setenv(CURL_CA_BUNDLE = "inst/extdata/cacert.pem")
        Sys.setenv(SSL_CERT_FILE = "inst/extdata/cacert.pem")

    # Download Rchelsa if missing and load it
        if (!requireNamespace("Rchelsa", quietly = TRUE)) {
            install.packages("devtools")
            library(devtools)
            devtools::install_git("https://gitlabext.wsl.ch/karger/rchelsa.git", force = T)
        }
    
        library(Rchelsa)
    
    # Fetch data from the netCDF file
        data <- ICCP::feedShiny()

    # Get necessary time ranges and cave coordinates
        agdf <- data$dataset %>%
            dplyr::group_by(cave_name, zone) %>%
            dplyr::summarise(
                startdate = as.Date(min(datetime)),
                enddate = as.Date(max(datetime)),
                .groups = 'drop'
            ) %>%
            dplyr::mutate(duration = as.numeric(difftime(enddate, startdate, units = "secs"))) %>%
            dplyr::group_by(cave_name) %>%
            dplyr::slice_max(order_by = duration, n = 1, with_ties = FALSE) %>%
            dplyr::rename(name = cave_name) %>%
            dplyr::left_join(data$caves, by = "name") %>%
            dplyr::select(name, latitude, longitude, startdate, enddate)

    # Per row chelsa data fetching function
        fetch_chelsa_data <- function(row) {
            # parameters
                coordinates <- data.frame(row$longitude, row$latitude)
                startdate <- row$startdate
                enddate <- row$enddate

            # average daily temperature
                tas <- Rchelsa::getChelsa(
                    var = "tas",
                    coords = coordinates,
                    startdate = startdate,
                    enddate = enddate,
                    freq = "daily",
                    verbose = F
                    )

                tas_data <- tibble::tibble(name = row$name, date = tas[,1], tas = tas[,2])

            # average daily precipitation
                # some data is missing at 2025-06-05 state, so we set available dates only anc create time subranges
                    cutoff_date <- as.Date("2020-12-31")
                    missing_dates <- as.Date(c(
                        "2020-01-05", "2020-03-02", "2020-04-05",
                        "2020-05-02", "2020-06-02", "2020-11-05"
                        ))

                    if (startdate > cutoff_date) {
                        ranges <- NULL
                    } else {
                        if (enddate < min(missing_dates)) {
                            ranges <- data.frame(
                                start = startdate,
                                end = enddate
                                )
                        } else {
                            if (enddate > cutoff_date) {
                                enddate <- cutoff_date
                            }

                            # Filter dates within the range
                                filtered_dates <- missing_dates[missing_dates > startdate & missing_dates < enddate]
                            
                            # Include the range boundaries
                                all_dates <- sort(c(startdate, filtered_dates, enddate))

                            # Set ranges
                                ranges <- data.frame(
                                        start = head(all_dates, -1),
                                        end = c(filtered_dates - 1, enddate)
                                    )
                                ranges$start[ranges$start %in% filtered_dates] <- ranges$start[ranges$start %in% filtered_dates] + 1
                                ranges$end[ranges$end %in% missing_dates] <- ranges$end[ranges$end %in% missing_dates] -1
                        }
                    }

                    precipitation <- function(start_date, end_date) {
                        Rchelsa::getChelsa(
                            var = "pr",
                            coords = coordinates,
                            startdate = start_date,
                            enddate = end_date,
                            freq = "daily",
                            verbose = FALSE
                            )
                    }
                    
                    if (is.null(ranges)) {
                        pr_data <- tibble::tibble(
                            name = row$name,
                            date = as.Date(character(0)),
                            pr   = numeric(0)
                            )
                    } else { 
                        pr <- do.call(
                            rbind, # Combine all results into a single data frame
                            lapply(1:nrow(ranges), function(i) {
                                precipitation(ranges$start[i], ranges$end[i])
                            })
                            )
                    
                        pr_data <- tibble::tibble(name = row$name, date = pr[,1], pr = pr[,2])

                        missed_dates <- missing_dates[
                            missing_dates >= min(pr_data$date) &
                            missing_dates <= max(pr_data$date) &
                            !missing_dates %in% pr_data$date
                            ]

                        if (length(missed_dates) > 0) {
                            additional_rows <- tibble::tibble(
                                name = row$name,
                                date = missed_dates,
                                pr = NA
                            )

                        pr_data <- dplyr::bind_rows(pr_data, additional_rows) %>%
                            dplyr::arrange(date)
                        }
                    }

            # combine and output the results
                result <- tas_data %>%
                        dplyr::left_join(pr_data, by = c("name", "date"))
            
            return(result)
        }

    # Apply fetch_chelsa_data function to all rows of agdf and bind the results
        caves_CHELSA <- purrr::map_dfr(
            seq_len(nrow(agdf)),
            function(i) {
                fetch_chelsa_data(agdf[i, ])
                }
            )

    # Save the results
        write.csv(caves_CHELSA, file = "inst/extdata/CHELSA.csv", row.names = FALSE)
    
    # Restore curl/GDAL
        if (!is.na(old_ca)) Sys.setenv(CURL_CA_BUNDLE = old_ca) else Sys.unsetenv("CURL_CA_BUNDLE")
        if (!is.na(old_ssl)) Sys.setenv(SSL_CERT_FILE   = old_ssl) else Sys.unsetenv("SSL_CERT_FILE")
}
