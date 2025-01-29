#' Helper function to annotate a photo with the set of texts
#'
#' @param photo_path path to the foto
#' @param artist_text photo author name
#' @param date_created year when the photo was made
#' @param caption_abstract foto description
#' 
#' @return returns foto with text
#' @export
#' @import magick

annotatePhoto <- function(photo_path, artist_text, date_created, caption_abstract) {
    image <- magick::image_read(photo_path) # Read the image
    info <- magick::image_info(image) # Get image dimensions
    img_width <- info$width
    img_height <- info$height
    text_size <- max(20, img_width * 0.025) # Adjust text size dynamically based on image width
    wrapped_caption <- strwrap(caption_abstract, width = 70) # Wrap the caption_abstract into lines
    # Create a blank canvas for the overlay
    text_overlay <- magick::image_blank(
        width = img_width,
        height = img_height,
        color = "transparent"
        )
    # Annotate each line of the caption separately
    for (i in seq_along(wrapped_caption)) {
        line <- wrapped_caption[i]
        y_offset <- img_height * 0.98 - (i * text_size * 1.2)
        text_overlay <- magick::image_annotate(
            text_overlay,
            text = line,
            size = text_size,
            color = "black",
            boxcolor = "white",
            kerning = 0,
            gravity = "southwest",
            location = sprintf("+50+%d", as.integer(y_offset))
            )
        }
    # Add the credentials to the bottom right
    bottom_right_text <- paste0("Photo by ", artist_text, " (", date_created, ")")
    text_overlay <- magick::image_annotate(
        text_overlay,
        text = bottom_right_text,
        size = text_size,
        color = "gray",
        boxcolor = "white",
        gravity = "southeast",
        location = "+20+10"
        )
    # Composite the text overlay onto the original image
    image_with_text <- magick::image_composite(image, text_overlay, operator = "atop")

    return(image_with_text)
    }
