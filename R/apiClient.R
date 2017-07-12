last_answer_date <- function() {
  archive <- read_csv(ARCHIVE_FILEPATH())
  max(archive$Answer_Date)
}

number_to_fetch <- function() {
  API_endpoint   <- "http://lda.data.parliament.uk/answeredquestions.json"
  download_size  <- "_pageSize=1"
  answering_body <- "AnsweringBody.=Ministry+of+Justice"

  if( file.exists(ARCHIVE_FILEPATH()) ) {
    date        <- last_answer_date()
    date_filter <- str_interp("min-answer.dateOfAnswer=${date}")
    response    <- fromJSON(str_interp("${API_endpoint}?${date_filter}&${answering_body}&${download_size}"))
    response$result$totalResults
  } else {
    response    <- fromJSON(str_interp("${API_endpoint}?${answering_body}&${download_size}"))
    response$result$totalResults
  }
}

parse_response <- function(response) {
  useful_cols <- c(
    'uin',
    'question text',
    'answer > answer text',
    'tabling member printed',
    'tabling member constituency',
    'answer > answering member printed',
    'date',
    'answer > date of answer'
  )

  new_colnames <- c(
    'Question_ID',
    'Question_Text',
    'Answer_Text',
    'Question_MP',
    'MP_Constituency',
    'Answer_MP',
    'Date',
    'Answer_Date'
  )

  response <- response[useful_cols]
  colnames(response) <- new_colnames
  response$Answer_Text <- gsub('<.{1,2}>', '', response$Answer_Text)
  response
}

update_archive <- function(questions_tibble) {
  archive    <- read_csv(ARCHIVE_FILEPATH())

  if(nrow(archive) > 0) {
      duplicates      <- questions_tibble$Question_ID %in% archive$Question_ID
      updated_archive <- rbind(archive, questions_tibble[!duplicates,])
    } else {
      updated_archive <- questions_tibble
    }

  write_csv(updated_archive, ARCHIVE_FILEPATH())
}

party <- function(member) {

  upper_house_titles <- c('Lord', 'Baroness', 'Earl', 'Viscount', 'Marquess')

  member <- gsub('Mr |Ms |Mrs ', '', member)
  member <- strsplit(member, ' ')[[1]]
  
  first  <- member[1]
  last   <- member[2]
  member_endpoint <- 'http://lda.data.parliament.uk/members.json'
  party_api_call  <- str_interp(
      paste0(
        "${member_endpoint}?",
        "familyName=${last}",
        "&givenName=${first}",
        "&_view=members",
        "&_pageSize=10&_page=0"
      )
    )

  member_of_the_upper_house <- any(upper_house_titles %in% member[1:length(member) - 1])

  if(member_of_the_upper_house == TRUE) {
      return('Not found')
    } else {
      response <- fromJSON(party_api_call)
      return(response$result$items$party[[1]])
    }
}

fetch_questions <- function(show_progress = FALSE) {
  iterations     <- ceiling(number_to_fetch() / 1000)

  if(iterations == 0) {
    stop("There are no new questions to fetch")
  }

  questions      <- tibble()
  download_size  <- "_pageSize=1000"
  answering_body <- "AnsweringBody.=Ministry+of+Justice"
  API_endpoint   <- "http://lda.data.parliament.uk/answeredquestions.csv"

  if(file.exists(ARCHIVE_FILEPATH())) {
    date        <- last_answer_date()
    date_param  <- str_interp("min-answer.dateOfAnswer=${date}")
    base_params <- str_interp("${date_param}&${answering_body}&${download_size}")
  } else {
    file.create(ARCHIVE_FILEPATH())
    base_params <- str_interp("${answering_body}&${download_size}")
  }

  for(iteration in c(1:iterations)) {
    page       <- iteration - 1
    page_param <- str_interp("_page=${page}")
    if(show_progress == TRUE) { print(str_interp("Fetching page ${iteration} of ${iterations}")) }
    response   <- read_csv(str_interp("${API_endpoint}?${base_params}&${page_param}"))
    response   <- parse_response(response)
    questions  <- rbind(questions, response)
  }

  questions$Party <- mapply(questions$Question_MP, FUN = function(x) { party(x) })

  update_archive(questions)
}
