# library(httptest)
# library(testthat)
# library(readr)
# library(dplyr)
# library(lubridate)
# library(jsonlite)
# library(stringr)

# expected_endpoint   <- "http://lda.data.parliament.uk/answeredquestions"
# answering_body      <- "AnsweringBody=Ministry+of+Justice"
# date_filter         <- "min-answer.dateOfAnswer=2017-03-23"

# dummy_pqs_api_response <- readRDS(file.path(SHINY_ROOT, 'tests/testthat/examples/api-responses', 'response-full.rds'))

# context("api functions; ARCHIVE PRESENT")

# test_that("last_answer_date() returns date of most recent answer", {
#   with_mock(
#     `file.exists`     = function(filepath) { TRUE                              },
#     `readr::read_csv` = function(filepath) { readRDS('./examples/data/archive.rds') },
#     expect_equal(last_answer_date(), ymd("2017-05-02"))
#   )
# })

# test_that("number_to_fetch() calls the API with the correct params", {

#   download_size     <- "_pageSize=1"
#   expected_API_call <- str_interp(
#     "${expected_endpoint}.json?${date_filter}&${answering_body}&${download_size}&_sort=dateOfAnswer"
#   )

# 	with_mock(
#     `file.exists`        = function(filepath) { TRUE         },
# 		`last_answer_date`   = function()         { '2017-03-23' },
# 		`jsonlite::fromJSON` = function(actual_API_call) {
# 			expect_equal(actual_API_call, expected_API_call)
#       readRDS('./examples/api-responses/response-update.rds')
# 		},
#     number_to_fetch()
# 	)
# })

# test_that("number_to_fetch() returns the number of questions to fetch", {
  
#   with_mock(
#     `file.exists`        = function(filepath) { TRUE                             },
#     `last_answer_date`   = function()         { '2017-03-23'                     },
#     `jsonlite::fromJSON` = function(...)      { readRDS('./examples/api-responses/response-update.rds') },
#     expect_equal(number_to_fetch(), 978)
#   )
# })

# test_that("fetch_questions() calls the API with the correct params", {

#   page_param        <- "_page=0"
#   download_size     <- "_pageSize=1000"
#   expected_API_call <- str_interp(
#     "${expected_endpoint}.json?${date_filter}&${answering_body}&${download_size}&_sort=dateOfAnswer&${page_param}"
#   )

#   with_mock(
#     `file.exists`          = function(filepath)              { TRUE         },
#     `write_csv`            = function(questions, filepath)   { NULL         },
#     `last_answer_date`     = function()                      { '2017-03-23' },
#     `number_in_archive`    = function()                      { 1000         },
#     `number_to_fetch`      = function()                      { 1000         },
#     `number_held_remotely` = function()                      { 2000         },
#     `update_archive`       = function(questions)             { NULL         },
#     `get_parties`          = function(names, constituencies) { NULL         },
#     `jsonlite::fromJSON`   = function(actual_API_call) {
#       expect_equal(actual_API_call, expected_API_call)
#       dummy_pqs_api_response
#      },
#     fetch_questions()
#   )
# })

# context("api functions; NO ARCHIVE PRESENT")

# test_that("number_to_fetch() calls the API with the correct params", {

#   download_size     <- "_pageSize=1"
#   expected_API_call <- str_interp("${expected_endpoint}.json?${answering_body}&${download_size}")

#   with_mock(
#     `file.exists`        = function(filepath) { FALSE },
#     `jsonlite::fromJSON` = function(actual_API_call) { 
#       expect_equal(actual_API_call, expected_API_call)
#       dummy_pqs_api_response
#     },
#     number_to_fetch()
#   )
# })

# test_that("number_to_fetch() returns the number of questions to fetch", {
	
#   with_mock(
# 		`file.exists`        = function(filepath) { FALSE                         },
# 		`jsonlite::fromJSON` = function(...)      { readRDS('./examples/api-responses/response-full.rds') },
# 		expect_equal(number_to_fetch(), 7352)
# 	)
# })

# test_that("fetch_questions() calls the API with the correct params", {

#   page_param        <- "_page=0"
#   download_size     <- "_pageSize=1000"
#   expected_API_call <- str_interp(
#     "${expected_endpoint}.json?${answering_body}&${download_size}&_sort=dateOfAnswer&${page_param}"
#   )

#   with_mock(
#     `file.exists`          = function(filepath)              { FALSE   },
#     `number_to_fetch`      = function()                      { 1000    },
#     `number_held_remotely` = function()                      { 1000    },
#     `file.create`          = function(filepath)              { NULL    },
#     `write_csv`            = function(questions, filepath)   { NULL    },
#     `update_archive`       = function(questions)             { NULL    },
#     `get_parties`          = function(names, constituencies) { NULL    },
#     `jsonlite::fromJSON`   = function(actual_API_call) {
#       expect_equal(actual_API_call, expected_API_call)
#       dummy_pqs_api_response
#     },

#     fetch_questions()
#   )
# })

# test_that("fetch_questions creates an archive file if one does not already exist", {

#   with_mock(
#     `file.exists`          = function(filepath)              { FALSE },
#     `number_to_fetch`      = function()                      { 1000  },
#     `number_held_remotely` = function()                      { 1000  },
#     `get_parties`          = function(names, constituencies) { NULL  },
#     `jsonlite::fromJSON`   = function(actual_API_call) {
#       dummy_pqs_api_response
#     },
#     `write_csv`      = function(questions, filepath) { NULL },
#     `update_archive` = function(new_questions)       { NULL }, 

#     `file.create` = function(filepath) {
#       expect_equal(
#         filepath,
#         file.path(SHINY_ROOT, 'Data', 'archived_pqs.csv')
#       )
#     },

#     fetch_questions()
#   )
# })

# test_that("fetch_questions() downloads new questions and calls the update_archive function", {

#   with_mock(
#     `file.exists`          = function(filepath)              { FALSE   },
#     `number_to_fetch`      = function()                      { 3000    },
#     `number_held_remotely` = function()                      { 3000    },
#     `file.create`          = function(filepath)              { NULL    },
#     `get_parties`          = function(names, constituencies) { NULL    },
#     `jsonlite::fromJSON`   = function(actual_API_call) {
#       dummy_pqs_api_response
#     },

#     `update_archive` = function(questions) {
#       expect_equal(
#         nrow(questions),
#         1000
#       )
#     },

#     fetch_questions()
#   )
# })

# test_that("fetch_questions() stops and raises an error if there are no new qs to fetch", {
#   with_mock(
#     `number_to_fetch` = function() { 0    },
#     `file.create`     = function() { NULL },
#     expect_error(fetch_questions(), "There are no new questions to fetch")
#   )
# })

# context('total_members')

# test_that('total_members() calls the members API to get the total number of member records', {

#   expected_API_call <- 'http://lda.data.parliament.uk/members.json?exists-party=true&_pageSize=1'

#   with_mock(
#     `fromJSON` = function(actual_API_call) {
#       expect_equal(actual_API_call, expected_API_call)
#       readRDS('./examples/api-responses/members_api_response.rda')
#     },
#     total_members()
#   )
# })

# context('get_all_members')

# test_that('get_all_members() calls the members API to retrieve all member records in one go', {
#   expected_API_call <- 'http://lda.data.parliament.uk/members.json?exists-party=true&_pageSize=10'

#   with_mock(
#     `fromJSON` = function(actual_API_call) {
#       expect_equal(actual_API_call, expected_API_call)
#       readRDS('./examples/api-responses/members_api_response.rda')
#     },
#     get_all_members(10)
#   )
# })

# context('get_constituencies')

# test_that('returns NA for members of the HoL', {
#   questions     <- readRDS('./examples/api-responses/response-full.rds')$result$items
#   hol_questions <- questions[questions$houseId$'_value' == 2,][1:2,]
#   expect_equal(get_constituencies(hol_questions), c('NA', 'NA'))
# })

# test_that('returns the constituency for member of the HoC', {
#   questions     <- readRDS('./examples/api-responses/response-full.rds')$result$items
#   hoc_questions <- questions[questions$houseId$'_value' == 1,][1:2,]
#   expect_equal(get_constituencies(hoc_questions), c('Blaydon', 'Blaydon'))
# })


# context('get_parties')

# test_that('get_parties calls total_members, get_all_members and get_party', {

#   with_mock(
#     `total_members`   = function()  { 10 },
#     `get_all_members` = function(x) {
#       expect_equal(x, 10)
#       readRDS('./examples/api-responses/members_api_response.rda')$result$items
#     },
#     `get_party` = function(name, constituency, data) {
#       expect_equal(name, 'Jane Smith')
#       'Party'
#     },
#     parties <- get_parties(c('Jane Smith'), c('constituency')),
#     expect_equal(parties, 'Party')
#   )
# })

# context('get_party')

# members_data <- readRDS('./examples/api-responses/members_api_response.rda')

# test_that('get_party() resturns "Not found" when unable to rerieve party', {

#   hol_parties <- c(
#     get_party('Not a member', 'constituency', members_data),
#     get_party('Another random person', 'constituency', members_data)
#   )

#   expect_true( all(hol_parties %in% 'Not found') )
# })

# test_that('get_party() can return the party for people in the members response', {
#     member_party <- get_party('Abbott, Diane', 'Hackney North and Stoke Newington', members_data)
#     expect_equal(member_party, 'Labour')
# })

# context('api response parser')

# test_that("colnames are correct", {
#   initial_response <- dummy_pqs_api_response
#   parsed_response  <- parse_response(initial_response$result$items)
#   parsed_answers   <- parsed_response$Answer_Text
#   actual_cols      <- colnames(parsed_response)
#   expected_cols    <- c(
#     'Question_MP',
#     'Question_Text',
#     'Question_ID',
#     'MP_Constituency',
#     'Question_Date',
#     'Answer_Text',
#     'Answer_MP',
#     'Answer_Date'
#   )

#   expect_equal(actual_cols, expected_cols)
# })

# context('update_archive')

# test_that("The archive is updated without duplcation", {

#   archive       <- readRDS('./examples/data/archive.rds')[1:10,]
#   new_questions <- readRDS('./examples/data/archive.rds')[5:14,]

#   with_mock(
#     `read_csv` = function(filepath) { archive },
#     `write_csv` = function(updated_archive, filepath) {
#       expect_equal(nrow(updated_archive), 14)
#       expect_equal(filepath, ARCHIVE_FILEPATH)
#     },

#     update_archive(new_questions)
#   )

# })

