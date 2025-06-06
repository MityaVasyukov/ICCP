% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/getTimeStamp.R
\name{getTimeStamp}
\alias{getTimeStamp}
\title{Helper function to return a date vector from the time variable (interval since some date) of a NetCDF file}
\usage{
getTimeStamp(nc_file, var, interval)
}
\arguments{
\item{nc_file}{NetCDF file path}

\item{var}{Variable name storing the time data inside the NetCDF file}

\item{interval}{Interval used to produce the date vector}
}
\value{
datetime_vector Date vector
}
\description{
Helper function to return a date vector from the time variable (interval since some date) of a NetCDF file
}
\examples{
getTimeStamp("israel_caves-2025.nc", "time", 1:10)

}
