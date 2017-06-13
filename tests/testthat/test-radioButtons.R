context("radio")

library(shiny)
library(RSelenium)
library(testthat)

remDr       <- remoteDriver(port = 4444)
remDr$open(silent = TRUE)
sysDetails  <- remDr$getStatus()
browser     <- remDr$sessionInfo$browserName
appURL      <- "http://127.0.0.1:8888"

test_that("radio buttons work", {  
  remDr$setImplicitWaitTimeout(10000)
  remDr$navigate(appURL)
  searchBox  <- remDr$findElement("css selector", "#question")
  query      <- "prison joint enterprise cost"
  searchBox$sendKeysToElement(list(query))
  radioButtons <- remDr$findElements("css selector", '.shiny-options-group .radio-inline')
  numButtons <- length(remDr$findElements("css selector", "#points input"))
  buttonOptions <- c(10, 25, 50, 100)
  
  for(i in c(1:numButtons)){
    chosenButton <- radioButtons[[i]]
    buttonText <- chosenButton$getElementText()[[1]]
    expect_equal(as.numeric(buttonText), buttonOptions[i])
    chosenButton$clickElement()
    Sys.sleep(2)
    oddResultsRows  <- length(remDr$findElements("css selector", "#similarity_table .odd"))
    evenResultsRows  <- length(remDr$findElements("css selector", "#similarity_table .even"))
    totalRowCount   <- oddResultsRows + evenResultsRows
    expect_equal(totalRowCount, buttonOptions[i])
  }

})

remDr$close()
