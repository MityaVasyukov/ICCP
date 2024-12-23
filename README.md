
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ICCP : Israeli caves climate project 2024

## Status

Under development.

## Overview

The package provides an example of climatic data exploring within a
Shiny Application. The data (`israel_caves-2024.nc`) origins from
climatic sensors set in 12 caves located in Israel. The climate data
(temperature, relative humidity, and dew point) was collected from
loggers set in various lighting zones (dark, light, twilight or control)
throughout each cave. The measurements were taken by the loggers each
hour from 2019-2021, with the measurement date or time spans varrying
across the loggers.

## Installation

``` r
library(devtools)
devtools::install_github("MityaVasyukov/ICCP")
```

## Usage

``` r
library(ICCP)
data <- feedShiny()
launchApp()
```
