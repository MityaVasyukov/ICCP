
#' Functions for checking if netcdf file is available
#'
#' @param file_name nc file name you're gonna use
#'
#' @return Boolean True or False
#' @export
#' @import RNetCDF
#' @examples
#' filename <- "israel_caves-2024.nc"
#' check_netcdf_file(filename)

check_netcdf_file <- function(file_name = "israel_caves-2024.nc") {

  file_path <- system.file("extdata", file_name, package = "ICCP")

  nc <- tryCatch(RNetCDF::open.nc(file_path), error = function(e) NULL)

  # Check if the file opened successfully
  if (!is.null(nc)) {
    cat("netcdf is ok\n")
    return(TRUE)
    RNetCDF::close.nc(nc)
  } else {
    return(FALSE)
    stop("Failed to open netcdf file.")
  }
}
