#' Helper function for returning system time in a specific time format
#'
#' @return time value in a specific time format
#' @export
#'
#' @examples
#' formatSystime()
formatSystime <- function() {
  now <- format(Sys.time(), "%Y-%m-%d %H:%M:%S", tz = "UTC")
  return(now)
}
