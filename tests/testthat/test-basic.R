# context("basic")

# library(shiny)
# library(RSelenium)
# library(testthat)

# remDr       <- remoteDriver(port = 4444)
# remDr$open(silent = TRUE)
# sysDetails  <- remDr$getStatus()
# browser     <- remDr$sessionInfo$browserName
# appURL      <- "http://127.0.0.1:8888"

# test_that("can connect to app", {  
#   remDr$navigate(appURL)
#   appTitle <- remDr$getTitle()[[1]]
#   expect_equal(appTitle, "MoJ Parliamentary Analysis Tool")  
# })

# test_that("there are no errors on the page", {
#   expect_that(
#     remDr$findElement("css selector", ".shiny-output-error"),
#     throws_error('NoSuchElement')
#   )
# })

# remDr$close()
