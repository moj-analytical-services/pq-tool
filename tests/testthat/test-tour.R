context("tour")

library(shiny)
library(RSelenium)
library(testthat)

remDr       <- remoteDriver(port = 4444)
remDr$open(silent = TRUE)
sysDetails  <- remDr$getStatus()
browser     <- remDr$sessionInfo$browserName
appURL      <- "http://127.0.0.1:8888"

test_that("Clicking 'Click here for a quick tour' starts the tout", {
  remDr$navigate(appURL)
  start_tour_button  <- remDr$findElement("css selector", "#tutorial_button")
  start_tour_button$clickElement()
  tour_guide <- remDr$findElement("css selector", ".introjs-tooltip")
  expect_equal(length(tour_guide), 1)
})

remDr$close()
