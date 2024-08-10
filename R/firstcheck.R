
#' Functions for checking if netcdf file is available
#'
#' @param file_name
#'
#' @return No return, just info
#' @export
#'
#' @examples
#' check_netcdf_file("israel_caves-2024.nc")
#' @import RNetCDF

check_netcdf_file <- function(file_name = "israel_caves-2024.nc") {

  file_path <- system.file("extdata", file_name, package = "ICCP")

  nc <- tryCatch(RNetCDF::open.nc(file_path), error = function(e) NULL)

  # Check if the file opened successfully
  if (!is.null(nc)) {
    cat("netcdf is ok\n")
    RNetCDF::close.nc(nc)
  } else {
    stop("Failed to open netcdf file.")
  }
}
