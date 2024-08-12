#' Removes seasonal component via GAM fitting
#'
#' @param df data frame
#'
#' @return data frame
#' @export
#' @import dplyr
#' @importFrom mgcv gam
#' @importFrom purrr map
#' @importFrom stats predict
#' @examples
#' set.seed(123)
#' example_data <- data.frame(
#'  datetime = seq.POSIXt(from = as.POSIXct("2024-01-01"), by = "day", length.out = 365),
#'  val = sin(seq(1, 365) * 2 * pi / 365) + rnorm(365, sd = 0.5),
#'  cave_name = sample(c("CaveA", "CaveB"), 365, replace = TRUE),
#'  var = sample(c("Temp", "Humidity"), 365, replace = TRUE),
#'  zone = sample(c("Zone1", "Zone2"), 365, replace = TRUE)
#' )
#' fitGam(example_data)
#'
fitGam <- function(df) {

  fit_gam_model <- function(df) {
    gam_model <- gam(val ~ s(as.numeric(datetime), bs = "cs"), data = df)
    df$smoothed_val <- stats::predict(gam_model, newdata = df)
    df$residuals <- df$val - df$smoothed_val
    return(df)
  }

  data <- df %>%
    dplyr::group_by(cave_name, var, zone) %>%
    tidyr::nest() %>%
    dplyr::mutate(data = purrr::map(data, fit_gam_model)) %>%
    tidyr::unnest(data) %>%
    dplyr::mutate(val = residuals)

  return(data)
}
