#' Helper function to fetch specific metadata from foto files
#'
#' @param path Path to foto file
#' @return data frame
#' @export
#' @import exifr

getMeta <- function(path) {
    fields_needed <- c("Artist", "Caption-Abstract", "DateCreated")
    md <- exifr::read_exif(path, tags = fields_needed)
    return(md)
    }