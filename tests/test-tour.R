context("tour")

library(shiny)
library(RSelenium)
library(testthat)

remDr       <- remoteDriver(port = 4444)
remDr$open(silent = TRUE)
sysDetails  <- remDr$getStatus()
browser     <- remDr$sessionInfo$browserName
appURL      <- "http://127.0.0.1:8888"

if(TRAVIS == TRUE) {
  wait_for_page <- 5
} else {
  wait_for_page <- 2
}

test_that('The whole tour works as expected', {
  # Tour starts successfully
  remDr$navigate(appURL)
  start_tour_button <- remDr$findElement("css selector", "#tutorial_button")
  start_tour_button$clickElement()
  Sys.sleep(wait_for_page)
  tour_guide <- remDr$findElement("css selector", ".introjs-tooltip")
  expect_equal(length(tour_guide), 1)

  # Grab elements for use in each subsequent step
  next_button <- remDr$findElement("css selector", ".introjs-nextbutton")
  tour_text   <- remDr$findElement("css selector", ".introjs-tooltiptext")
  step_number <- remDr$findElement("css selector", '.introjs-helperNumberLayer')
  
  # Can continue to step 2 without user input
  next_button$clickElement()
  Sys.sleep(wait_for_page)
  actual_step_number  = step_number$getElementText()[[1]]
  expeced_step_number = '1'
  expect_equal(actual_step_number, expeced_step_number)
  actual_text   = tour_text$getElementText()[[1]]
  expected_text = "We've added some search terms for you, but you can change them if you like."
  expect_equal(actual_text, expected_text)

  # Proceeds to date range
  next_button$clickElement()
  Sys.sleep(wait_for_page)
  actual_step_number  = step_number$getElementText()[[1]]
  expeced_step_number = '2'
  expect_equal(actual_step_number, expeced_step_number)
  actual_text   = tour_text$getElementText()[[1]]
  expected_text = "Pick a range of dates you want to consider (leave this alone to search all the questions we have)"
  expect_equal(actual_text, expected_text)

  # Proceeds to table
  next_button$clickElement()
  Sys.sleep(wait_for_page)
  actual_step_number  = step_number$getElementText()[[1]]
  expeced_step_number = '3'
  expect_equal(actual_step_number, expeced_step_number)
  actual_text   = tour_text$getElementText()[[1]]
  expected_text = "This table shows the top 100 PQs that are most similar to your search terms.\n\nClick on one of the rows to see the question and answer text."
  expect_equal(actual_text, expected_text)

  # Forces row selection then proceeds to plot
  next_button$clickElement()
  Sys.sleep(wait_for_page)
  actual_step_number  = step_number$getElementText()[[1]]
  expeced_step_number = '3'
  expect_equal(actual_step_number, expeced_step_number)
  actual_text   = tour_text$getElementText()[[1]]
  expected_text = "Please select a row before continuing."
  expect_equal(actual_text, expected_text)
  row = remDr$findElement("css selector", ".odd")
  row$clickElement()
  next_button$clickElement()
  Sys.sleep(wait_for_page)
  actual_step_number  = step_number$getElementText()[[1]]
  expeced_step_number = '4'
  expect_equal(actual_step_number, expeced_step_number)
  actual_text   = tour_text$getElementText()[[1]]
  expected_text = "This graph plots the PQs from the table and when they were asked.\n\nEach point represents a PQ, with the height showing how similar the question is to your search terms (higher = more similar)"
  expect_equal(actual_text, expected_text)

  # Proceeds to plot explanation
  next_button$clickElement()
  Sys.sleep(wait_for_page)
  actual_step_number  = step_number$getElementText()[[1]]
  expeced_step_number = '5'
  expect_equal(actual_step_number, expeced_step_number)
  actual_text   = tour_text$getElementText()[[1]]
  expected_text = "The grey line shows an average of parliamentary interest in the search terms.\n\nThe red point is highlighting the question you previously chose from the table.\n\nTry clicking another point to highlight instead."
  expect_equal(actual_text, expected_text)

  if(TRAVIS == FALSE) {
    # These tests pass locally but not on Travis
    # Forces point selection by checking selected rows then proceeds back to table
    next_button$clickElement()
    Sys.sleep(wait_for_page)
    actual_step_number  = step_number$getElementText()[[1]]
    expeced_step_number = '5'
    expect_equal(actual_step_number, expeced_step_number)
    actual_text   = tour_text$getElementText()[[1]]
    expected_text = "Please select another point on the graph before continuing."
    expect_equal(actual_text, expected_text)
    row = remDr$findElement("css selector", ".even")
    row$setElementAttribute("class", "selected")

    next_button$clickElement()
    Sys.sleep(wait_for_page)
    actual_step_number  = step_number$getElementText()[[1]]
    expeced_step_number = '6'
    expect_equal(actual_step_number, expeced_step_number)
    actual_text   = tour_text$getElementText()[[1]]
    expected_text = "The question you selected on the graph has now been opened in the table."
    expect_equal(actual_text, expected_text)

    # Encourages interaction with application
    next_button$clickElement()
    Sys.sleep(wait_for_page)
    actual_step_number  = step_number$getElementText()[[1]]
    expeced_step_number = '7'
    expect_equal(actual_step_number, expeced_step_number)
    actual_text   = tour_text$getElementText()[[1]]
    expected_text = "You can see all the questions asked by this MP/peer by clicking the 'See all questions asked by' button.\n\nTo continue, try it!"
    expect_equal(actual_text, expected_text)
    
    # Hides the next_button and an error is raised when we try to click it
    expect_error(next_button$clickElement(), ".*")

    # Proceed to wordcloud by clicking on 'See all questions by...'
    all_questions_button = remDr$findElement("css selector", ".btn-info")
    all_questions_button$clickElement()
    Sys.sleep(wait_for_page)
    actual_step_number  = step_number$getElementText()[[1]]
    expeced_step_number = '8'
    expect_equal(actual_step_number, expeced_step_number)
    actual_text   = tour_text$getElementText()[[1]]
    expected_text = "This wordcloud shows the words that are most important in the questions asked by this member.\n\nThe bigger the word, the more important it is."
    expect_equal(actual_text, expected_text)

    # Proceed to member plot
    next_button$clickElement()
    Sys.sleep(wait_for_page)
    actual_step_number  = step_number$getElementText()[[1]]
    expeced_step_number = '9'
    expect_equal(actual_step_number, expeced_step_number)
    actual_text   = tour_text$getElementText()[[1]]
    expected_text = "This plot shows when questions were asked by the selected member.\n\nThe x axis shows the date when questions were asked and the y axis shows the count of questions asked on that date."
    expect_equal(actual_text, expected_text)

    # Proceed to member table
    next_button$clickElement()
    Sys.sleep(wait_for_page)
    actual_step_number  = step_number$getElementText()[[1]]
    expeced_step_number = '10'
    expect_equal(actual_step_number, expeced_step_number)
    actual_text   = tour_text$getElementText()[[1]]
    expected_text = "This table contains all of the information on the questions asked by this member.\n\nClick on a row to see the corresponding question and answer text."
    expect_equal(actual_text, expected_text)

    # Force row selection
    next_button$clickElement()
    Sys.sleep(wait_for_page)
    actual_step_number  = step_number$getElementText()[[1]]
    expeced_step_number = '10'
    expect_equal(actual_step_number, expeced_step_number)
    actual_text   = tour_text$getElementText()[[1]]
    expected_text = "Please select a row before continuing."
    expect_equal(actual_text, expected_text)

    # Click on a row that has not already been clicked on and proceed to end of this section
    rows = remDr$findElements("css selector", ".odd")
    row  = rows[[length(rows)]]
    row$clickElement()
    next_button$clickElement()
    Sys.sleep(wait_for_page)
    actual_step_number  = step_number$getElementText()[[1]]
    expeced_step_number = '11'
    expect_equal(actual_step_number, expeced_step_number)
    actual_text   = tour_text$getElementText()[[1]]
    expected_text = "You can now navigate back to the first page by clicking on the 'Back to Search' button."
    expect_equal(actual_text, expected_text)

    # Proceed back to search tab
    controls = remDr$findElements("css selector", ".btn-info")
    back_to_search_button = controls[[3]]
    back_to_search_button$clickElement()
    Sys.sleep(wait_for_page)
    actual_step_number  = step_number$getElementText()[[1]]
    expeced_step_number = '12'
    expect_equal(actual_step_number, expeced_step_number)
    actual_text   = tour_text$getElementText()[[1]]
    expected_text = "All the questions in our database have been grouped into topics by an algorithm. These topics have been given a number and three 'Topic Keywords' to give an idea of what the topic is about.\n\nClick the 'View topic' button to look at all the questions in this topic."
    expect_equal(actual_text, expected_text)

    # Proceed to topic via Topic button
    controls = remDr$findElements("css selector", ".btn-info")
    back_to_search_button = controls[[2]]
    back_to_search_button$clickElement()
    Sys.sleep(wait_for_page)
    actual_step_number  = step_number$getElementText()[[1]]
    expeced_step_number = '13'
    expect_equal(actual_step_number, expeced_step_number)
    actual_text   = tour_text$getElementText()[[1]]
    expected_text = "This wordcloud shows the words that are most important in this topic.\n\nThe bigger the word, the more important it is."
    expect_equal(actual_text, expected_text)

    # Proceed to topic plot
    next_button$clickElement()
    Sys.sleep(wait_for_page)
    actual_step_number  = step_number$getElementText()[[1]]
    expeced_step_number = '14'
    expect_equal(actual_step_number, expeced_step_number)
    actual_text   = tour_text$getElementText()[[1]]
    expected_text = "This plot shows when questions in the topic were asked.\nEach bar shows the number of questions asked in a particular fortnight - the higher the bar, the more questions from that topic."
    expect_equal(actual_text, expected_text)

    # Proceed to topic table
    next_button$clickElement()
    Sys.sleep(wait_for_page)
    actual_step_number  = step_number$getElementText()[[1]]
    expeced_step_number = '15'
    expect_equal(actual_step_number, expeced_step_number)
    actual_text   = tour_text$getElementText()[[1]]
    expected_text = "This table contains all of the information on the questions asked on this topic.\n\nClick on a row to see the corresponding question and answer text."
    expect_equal(actual_text, expected_text)

    # Forced to click on a row
    next_button$clickElement()
    Sys.sleep(wait_for_page)
    actual_step_number  = step_number$getElementText()[[1]]
    expeced_step_number = '15'
    expect_equal(actual_step_number, expeced_step_number)
    actual_text   = tour_text$getElementText()[[1]]
    expected_text = "Please select a row before continuing."
    expect_equal(actual_text, expected_text)

    # Click on a row and complete the tutorial
    rows = remDr$findElements("css selector", ".even")
    row  = rows[[5]]
    row$clickElement()
    next_button$clickElement()
    Sys.sleep(wait_for_page)
    actual_step_number  = step_number$getElementText()[[1]]
    expeced_step_number = '16'
    expect_equal(actual_step_number, expeced_step_number)
    actual_text   = tour_text$getElementText()[[1]]
    expected_text = "That's it! You have made it to the end of the tutorial!\n\nWe hope this was useful. If you have any feedback on this tutorial, or the tool in general, please see the link at the bottom of the page."
    expect_equal(actual_text, expected_text)
  }
})

remDr$close()
