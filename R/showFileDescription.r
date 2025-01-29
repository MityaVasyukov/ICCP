#' Helper function to return Shiny modal window with a file details of a specific file
#'
#' @param file_path the path of the file
#' @export
#' @import shiny
#'

showFileDescription <- function(file_path) {
    file_content <- readLines(file_path)
    shiny::showModal(
        shiny::modalDialog(
            title = "File Description",
            tags$pre(paste(file_content, collapse = "\n")),
            easyClose = TRUE,
            footer = modalButton("Close")
            )
        )
    }
