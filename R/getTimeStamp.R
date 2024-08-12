#' Helper function to return a date vector from the time variable (interval since some date) of a NetCDF file
#'
#' @param nc_file NetCDF file path
#' @param var Variable name storing the time data inside the NetCDF file
#' @param interval Interval used to produce the date vector
#'
#' @return datetime_vector Date vector
#' @export
#' @import RNetCDF
#' @examples
#' getTimeStamp("israel_caves-2024.nc", "time", 1:10)
#'
getTimeStamp <- function(nc_file, var, interval) {
  if (is.character(nc_file)) {
    nc <- RNetCDF::open.nc(system.file("extdata", nc_file, package = "ICCP"))
    on.exit(RNetCDF::close.nc(nc))
  } else if (inherits(nc_file, "NetCDF")) {
    nc <- nc_file
  } else {
    stop("The nc_file parameter must be either a file path or an opened NetCDF object.")
  }

  if (!is.character(var)) {
    time_var <- as.character(substitute(var))
  } else {
      time_var <- var
      }

  if (!is.numeric(interval)) {
    stop(sprintf("The interval parameter '%s' is not numeric", interval))
  }

  nc_vars <- sapply(0:(RNetCDF::file.inq.nc(nc)$nvars - 1), function(i) RNetCDF::var.inq.nc(nc, i)$name)

  if (!time_var %in% nc_vars) {
    stop(sprintf("There is no variable '%s' in %s", var, nc_file))
  }

  splitted <- strsplit(RNetCDF::att.get.nc(nc, time_var, "units"), " ")[[1]]
  start_timestamp <- as.POSIXct(paste(splitted[3], splitted[4]), tz = "UTC")
  step <- splitted[1]

  datetime_vector <- as.POSIXct(sapply(interval, function(j) {
    start_timestamp + as.difftime(j, units = step)
  }), tz = "UTC")

  return(datetime_vector)
}
