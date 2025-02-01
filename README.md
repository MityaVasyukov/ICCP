
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ICCP : Israeli caves climate project 2025

## Status

Under development.

## Overview

The package provides an example of climatic data exploring within a
Shiny Application. The data (`israel_caves-2024.nc`) origins from
climatic sensors set in 12 caves located in Israel. The climate data
(temperature, relative humidity, and dew point) was collected from
loggers set in various lighting zones (dark, light, twilight or control)
throughout each cave. The measurements were taken hourly from 2019-2021.

## Installation

Download and install [R and
Rstudio](https://posit.co/download/rstudio-desktop). We recommend using
RStudio, since it works faster with the application.

Run following commands:

``` r
install.packages("remotes")
library(remotes)
install_github("MityaVasyukov/ICCP@main")
```

## Usage

Run following commands:

``` r
library(ICCP)
launchApp()
```
