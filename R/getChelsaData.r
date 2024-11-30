#' Fetching the data from CHELSA project for each cave
#'
#'
#' @return returns a table of daily mean temperature and precipitation for each cave for the longest time period of a certain logger set in the cave
#' @import Rchelsa
#' @import dplyr
#' @import tibble
#' @export
#'
#' @examples

library(Rchelsa)
library(dplyr)

get_CHELSA_for_Caves <- function() {

  data <- ICCP::feedShiny()

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


  fetch_chelsa_data <- function(row) {

      cutoff_date <- as.Date("2020-12-31")
      exclusive_dates <- as.Date(c("2020-01-05", "2020-03-02", "2020-04-05",
                                  "2020-05-02", "2020-06-02", "2020-11-05"))
      coordinates <- data.frame(row$longitude, row$latitude)

      tas <- Rchelsa::getChelsa("tas", coords = coordinates, startdate = as.Date(row$startdate), enddate = as.Date(row$enddate), freq = "daily", verbose = F)
      tas_data <- tibble::tibble(name = row$name, date = tas[,1], tas = tas[,2])

      if (row$startdate > cutoff_date) {
          ranges <- NULL
      } else {
          if (row$enddate < min(exclusive_dates)) {
              ranges <- data.frame(
                  start = row$startdate,
                  end = row$enddate
                  )
          } else {
              if (row$enddate > cutoff_date) {
                  row$enddate <- cutoff_date
                  }
              # Filter dates within the range
              filtered_dates <- exclusive_dates[exclusive_dates > row$startdate & exclusive_dates < row$enddate]
              # Include the range boundaries
              all_dates <- sort(c(row$startdate, filtered_dates, row$enddate))

              # Form ranges
              ranges <- data.frame(
                      start = head(all_dates, -1),
                      end = c(filtered_dates - 1, row$enddate)
                  )
              ranges$start[ranges$start %in% filtered_dates] <- ranges$start[ranges$start %in% filtered_dates] + 1
              ranges$end[ranges$end %in% exclusive_dates] <- ranges$end[ranges$end %in% exclusive_dates] -1
          }
      }

      precipitation <- function(start_date, end_date) {
          Rchelsa::getChelsa(
              "pr",
              coords = coordinates,
              startdate = start_date,
              enddate = end_date,
              freq = "daily",
              verbose = FALSE
              )
      }

      pr <- do.call(
          rbind, # Combine all results into a single data frame
          lapply(1:nrow(ranges), function(i) {
          precipitation(ranges$start[i], ranges$end[i])
          })
          )

      pr_data <- tibble::tibble(name = row$name, date = pr[,1], pr = pr[,2])

      missing_dates <- exclusive_dates[exclusive_dates >= min(pr_data$date) &
                                    exclusive_dates <= max(pr_data$date) &
                                    !exclusive_dates %in% pr_data$date]

      if (length(missing_dates) > 0) {
          additional_rows <- tibble::tibble(
              name = row$name,
              date = missing_dates,
              pr = NA
          )
      pr_data <- dplyr::bind_rows(pr_data, additional_rows) %>%
          dplyr::arrange(date)
      }

      result <- tas_data %>%
          dplyr::left_join(pr_data, by = c("name", "date"))

      return(result)
  }

  # Apply the function to all rows of agdf and bind results
  caves_CHELSA <- agdf %>%
      dplyr::rowwise() %>%
      dplyr::do(fetch_chelsa_data(.)) %>%
      dplyr::ungroup() %>%
      dplyr::as_tibble()

  # write.csv(caves_CHELSA, file = "inst/extdata/CHELSA.csv", row.names = FALSE)
}
