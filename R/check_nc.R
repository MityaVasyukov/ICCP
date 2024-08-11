
#' Functions for checking if netcdf file is available
#'
#' @param file_name nc file name you're gonna use
#'
#' @return Boolean True or False
#' @export
#' @import RNetCDF
#' @examples
#' filename <- "israel_caves-2024.nc"
#' check_nc(filename)

check_nc <- function(file_name = "israel_caves-2024.nc") {

  # Check if the user specified an nc file
  if (file_name == "israel_caves-2024.nc") {
    file_path <- system.file("extdata", file_name, package = "ICCP")
  } else {
    file_path <- file_name
  }

  nc <- tryCatch(RNetCDF::open.nc(file_path), error = function(e) NULL)

  # Check if the file opened successfully
  if (!is.null(nc)) {
    cat("netcdf is ok\n")
    return(TRUE)
    RNetCDF::close.nc(nc)
  } else {
    cat("Failed to open netcdf file.\n")
    return(FALSE)
  }
}
