library(httptest)
library(testthat)
library(readr)
library(dplyr)
library(lubridate)
library(jsonlite)
library(stringr)

expected_endpoint   <- "http://lda.data.parliament.uk/answeredquestions"
dummy_data_filepath <- file.path(SHINY_ROOT, 'tests/testthat/examples', 'dummy_API_response.csv')
cols                <- colnames(read_csv(dummy_data_filepath))
answering_body      <- "AnsweringBody.=Ministry+of+Justice"
date_filter         <- "min-answer.dateOfAnswer=2017-03-23"

dummy_api_response <- function() {
  csv <- read.csv(dummy_data_filepath)
  colnames(csv) <- cols
  csv
}

dummy_member_api_response <- function() {
  party           <- 'Party'
  items           <- list(party)
  names(items)    <- 'party'
  result          <- list(items)
  names(result)   <- 'items'
  response        <- list(result)
  names(response) <- 'result'
  response
}

context("api functions; ARCHIVE PRESENT")

test_that("last_answer_date() returns date of most recent answer", {
  with_mock(
    `file.exists`     = function(filepath) { TRUE                              },
    `readr::read_csv` = function(filepath) { readRDS('./examples/archive.rds') },
    expect_equal(last_answer_date(), ymd("2017-05-02"))
  )
})

test_that("number_to_fetch() calls the API with the correct params", {

  download_size     <- "_pageSize=1"
  expected_API_call <- str_interp(
    "${expected_endpoint}.json?${date_filter}&${answering_body}&${download_size}"
  )

	with_mock(
    `file.exists`        = function(filepath) { TRUE         },
		`last_answer_date`   = function()         { '2017-03-23' },
		`jsonlite::fromJSON` = function(actual_API_call) {
			expect_equal(actual_API_call, expected_API_call)
      readRDS('./examples/update.rds')
		},
    number_to_fetch()
	)
})

test_that("number_to_fetch() returns the number of questions to fetch", {
  
  with_mock(
    `file.exists`        = function(filepath) { TRUE                             },
    `last_answer_date`   = function()         { '2017-03-23'                     },
    `jsonlite::fromJSON` = function(...)      { readRDS('./examples/update.rds') },
    expect_equal(number_to_fetch(), 978)
  )
})

test_that("fetch_questions() calls the API with the correct params", {

  page_param        <- "_page=0"
  download_size     <- "_pageSize=1000"
  expected_API_call <- str_interp(
    "${expected_endpoint}.csv?${date_filter}&${answering_body}&${download_size}&${page_param}"
  )

  with_mock(
    `file.exists`      = function(filepath)            { TRUE         },
    `write_csv`        = function(questions, filepath) { NULL         },
    `last_answer_date` = function()                    { '2017-03-23' },
    `number_to_fetch`  = function()                    { 1000         },
    `update_archive`   = function(questions)           { NULL         },
    `party`            = function(member)              { 'party'      },
    `readr::read_csv`  = function(actual_API_call) {
      expect_equal(actual_API_call, expected_API_call)
      dummy_api_response()
    },
    fetch_questions()
  )
})

context("api functions; NO ARCHIVE PRESENT")

test_that("number_to_fetch() calls the API with the correct params", {

  download_size     <- "_pageSize=1"
  expected_API_call <- str_interp("${expected_endpoint}.json?${answering_body}&${download_size}")

  with_mock(
    `file.exists`        = function(filepath) { FALSE },
    `jsonlite::fromJSON` = function(actual_API_call) { 
      expect_equal(actual_API_call, expected_API_call)
      readRDS('./examples/all.rds')
    },
    number_to_fetch()
  )
})

test_that("number_to_fetch() returns the number of questions to fetch", {
	
  with_mock(
		`file.exists`        = function(filepath) { FALSE                         },
		`jsonlite::fromJSON` = function(...)      { readRDS('./examples/all.rds') },
		expect_equal(number_to_fetch(), 130444)
	)
})

test_that("fetch_questions() calls the API with the correct params", {

  page_param        <- "_page=0"
  download_size     <- "_pageSize=1000"
  expected_API_call <- str_interp(
    "${expected_endpoint}.csv?${answering_body}&${download_size}&${page_param}"
  )

  with_mock(
    `file.exists`     = function(filepath)            { FALSE   },
    `number_to_fetch` = function()                    { 1000    },
    `file.create`     = function(filepath)            { NULL    },
    `write_csv`       = function(questions, filepath) { NULL    },
    `update_archive`  = function(questions)           { NULL    },
    `party`           = function(member)              { 'party' },
    `readr::read_csv` = function(actual_API_call) {
      expect_equal(actual_API_call, expected_API_call)
      dummy_api_response()
    },

    fetch_questions()
  )
})

test_that("fetch_questions creates an archive file if one does not already exist", {

  with_mock(
    `file.exists`     = function(filepath) { FALSE   },
    `number_to_fetch` = function()         { 1000    },
    `party`           = function(memeber)  { 'party' },
    `readr::read_csv` = function(actual_API_call) {
      dummy_api_response()
    },
    `write_csv`      = function(questions, filepath) { NULL },
    `update_archive` = function(new_questions)       { NULL }, 

    `file.create` = function(filepath) {
      expect_equal(
        filepath,
        file.path(SHINY_ROOT, 'Data', 'archived_pqs.csv')
      )
    },

    fetch_questions()
  )
})

test_that("fetch_questions() downloads new questions and calls the update_archive function", {

  with_mock(
    `file.exists`       = function(filepath) { FALSE   },
    `number_to_fetch`   = function()         { 3000    },
    `file.create`       = function(filepath) { NULL    },
    `party`             = function(member)   { 'party' },
    `readr::read_csv` = function(actual_API_call) {
      dummy_api_response()
    },

    `update_archive` = function(questions) {
      expect_equal(
        nrow(questions),
        3000
      )
    },

    fetch_questions()
  )
})

test_that("fetch_questions() stops and raises an error if there are no new qs to fetch", {
  with_mock(
    `number_to_fetch` = function() { 0    },
    `file.create`     = function() { NULL },
    expect_error(fetch_questions(), "There are no new questions to fetch")
  )
})

context('party')

test_that('party() cannot retrieve party for members of HoL', {

  hol_parties <- c(
    party('Lord Someone'),
    party('Viscount Someone'),
    party('Baroness Someone'),
    party('Earl someone'),
    party('Marquess')
  )

  expect_true( all(hol_parties %in% 'Not found') )
})

test_that('party() calls the API with the correct params', {

  member_endpoint   <- 'http://lda.data.parliament.uk/members.json'
  first             <- 'Firstname'
  last              <- 'Surname'
  expected_API_call <- str_interp(
    "${member_endpoint}?familyName=${last}&givenName=${first}&_view=members&_pageSize=10&_page=0"
  )

  with_mock(
    `fromJSON` = function(actual_API_call) {
      expect_equal(expected_API_call, actual_API_call)
      dummy_member_api_response()
    },
    party('Mrs Firstname Surname'),
    party('Mr Firstname Surname'),
    party('Ms Firstname Surname')
  )

})

context('api response parser')

html_present <- function(list) {
  bools_list <- grepl('<.{1,2}>', list)
  T %in% bools_list
}

test_that("html tags are removed from answer text and colnames are correct", {
  initial_response <- read_csv(dummy_data_filepath)
  initial_answers  <- initial_response$'answer > answer text'
  parsed_response  <- parse_response(initial_response)
  parsed_answers   <- parsed_response$Answer_Text
  actual_cols      <- colnames(parsed_response)
  expected_cols    <- c(
    'Question_ID',
    'Question_Text',
    'Answer_Text',
    'Question_MP',
    'MP_Constituency',
    'Answer_MP',
    'Date',
    'Answer_Date'
  )

  expect_equal(actual_cols, expected_cols)
  expect_true(html_present(initial_answers))
  expect_false(html_present(parsed_answers))
})

context('update_archive')

test_that("The archive is updated without duplcation", {

  archive       <- readRDS('./examples/archive.rds')[1:10,]
  new_questions <- readRDS('./examples/archive.rds')[5:14,]

  with_mock(
    `read_csv` = function(filepath) { archive },
    `write_csv` = function(updated_archive, filepath) {
      expect_equal(nrow(updated_archive), 14)
      expect_equal(filepath, ARCHIVE_FILEPATH())
    },

    update_archive(new_questions)
  )

})

