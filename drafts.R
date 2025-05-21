# photos

wd <- setwd("x:/repo_iccp/ICCP/inst/www/images/")
filename <- "008.jpg"

#install.packages("exifr")
library(exifr)

metadata <- read_exif(filename)
colnames(metadata)

metadata$Title
metadata$Creator
metadata$FileType
metadata$Description
metadata$ImageSize
metadata$DateCreated
metadata$Keywords
metadata$URL
metadata$CaptionWriter

metadata$DocumentID

metadata$ThumbnailImage



install.packages("jpeg")
install.packages("grid")
library(jpeg)
library(grid)
# For JPEG images
img <- readJPEG("x:/repo_iccp/ICCP/inst/www/images/001.jpg")
grid.raster(img)






##### GET CHELSA data UNDER DEVELOPMENT ######

getChelsaPointData <- function(setup, df, temperature, precipitation, startDate, endDate) {
  start_time <- Sys.time()

  if (setup) {
    library(devtools)
    install_git("https://gitlabext.wsl.ch/karger/rchelsa.git", force = T)
  }

  library(Rchelsa)
  library(terra)
  library(sf)

  data <- as.data.frame(df)
  print(colnames(data))
  coords <- data[1,] %>% select(longitude, latitude) %>% rename(lon = longitude, lat = latitude)
  output <- list()

  if (precipitation) {
    pr <- getChelsa('pr',
                    coords = coords,
                    startdate = startdate,
                    enddate = enddate,
                    version = "CHELSA",
                    freq = "daily",
                    protocol = "vsicurl",
                    verbose = FALSE
    )
    output <- c(output, pr)
  }

  if (temperature) {
    tas <- getChelsa('tas',
                     coords = coords,
                     startdate = startdate,
                     enddate = enddate,
                     version = "CHELSA",
                     freq = "daily",
                     protocol = "vsicurl",
                     verbose = FALSE
    )
    output <- c(output, tas)
  }

  total_time <- Sys.time() - start_time
  cat(sprintf("\nData retrieving time: %.3f seconds\n\n", as.numeric(total_time, units = "secs")))
  return(output)
}

# output <- getChelsaPointData(FALSE, mdf, TRUE, TRUE, as.Date("2019-1-10"), as.Date("2019-1-19"))


# install.packages(c("exifr", "stringr"))
library(exifr)
library(stringr)

# your metadata‑pulling function
getMeta <- function(path) {
  tags <- c("Artist", "Caption-Abstract", "DateCreated")
  md   <- read_exif(path, tags = tags)
  return(md)
}

# 1. point to your folder
folder <- "p:/2025-ICCP/ICCP/inst/www/images"

# 2. find all .jpg/.jpeg files
jpgs <- list.files(folder, 
                   pattern = "\\.jpe?g$", 
                   full.names = TRUE, 
                   ignore.case = TRUE)

df <- do.call(rbind, lapply(jpgs, function(fp) {
  fn <- fp
  id <- as.integer(str_extract(fn, "^\\d+"))
  md <- getMeta(fp)
  
  # ensure it's a one‐row data.frame
  data.frame(
    id        = id,
    filename  = fn,
    Artist    = md$Artist,
    Caption   = md$`Caption-Abstract`,
    Date      = md$DateCreated,
    stringsAsFactors = FALSE
  )
}))

# 4. reset rownames
rownames(df) <- NULL


# assuming your data.frame is called `df`
write.table(
  df,
  file      = "p:/2025-ICCP/ICCP/inst/www/images/captions.txt",
  sep       = "\t",          # tab delimiter
  row.names = FALSE,         # don’t write row numbers
  quote     = FALSE,         # don’t wrap strings in quotes
  na        = ""             # empty string for missing values
)
