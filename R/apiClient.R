source('./R/Functions.R')
library(jsonlite)
library(stringr)
library(gtools)
library(readr)
library(purrr)

if((s3_file_exists(ARCHIVE_FILEPATH)=='TRUE')) {
  s3_archived_pqs <- s3tools::s3_path_to_full_df(ARCHIVE_FILEPATH, overwrite = FALSE)[2:10]
}

number_in_archive <- function() {
  if((s3_file_exists(ARCHIVE_FILEPATH)=='TRUE')) {
    nrow(s3tools::s3_path_to_full_df(ARCHIVE_FILEPATH, overwrite = FALSE)[2:10])
  } else {
    0
  }
}

last_answer_date <- function() {
  archive_not_NA <- s3tools::s3_path_to_full_df(ARCHIVE_FILEPATH, overwrite = FALSE)[2:10] %>%
    filter(!(is.na(Answer_Date)))
  max(archive_not_NA$Answer_Date)
}

number_held_remotely <- function() {
  response <- fromJSON(str_interp("${API_ENDPOINT}?${MOJ_ONLY}&${MIN_DOWNLOAD}"))
  response$result$totalResults
}
  
number_to_fetch <- function() {
  if ((s3_file_exists(ARCHIVE_FILEPATH)=='TRUE')) {
      date        <- last_answer_date()
      date_filter <- str_interp(
        "_where=?item%20parl:answer%20?a1.?a1%20parl:dateOfAnswer%20?dt.%20filter(str(?dt)%3E=%22${date}%22)"
      )
      response    <- fromJSON(str_interp("${API_ENDPOINT}?${date_filter}&${MOJ_ONLY}&${MIN_DOWNLOAD}&_sort=dateOfAnswer"))
      response$result$totalResults
    } else {
      number_held_remotely()
    }
  }
  

get_constituencies <- function(raw_response) {
  map_chr(1:nrow(raw_response), function(n) {
    constituency <- raw_response$tablingMemberConstituency$'_value'[n]
    
    if(length(constituency) == 0 | invalid(constituency)) {
      'NA'
    } else {
      constituency
    }
  })}

parse_response <- function(raw_response) {
  tibble(
    Question_MP     = do.call("rbind", raw_response$tablingMemberPrinted)$'_value',
    Question_Text   = raw_response$questionText,
    Question_ID     = raw_response$uin,
    MP_Constituency = get_constituencies(raw_response),
    Question_Date   = raw_response$date$'_value',
    Answer_Text     = raw_response$answer$answerText$'_value',
    Answer_MP       = raw_response$answer$answeringMemberPrinted$'_value',
    Answer_Date     = raw_response$answer$dateOfAnswer$'_value'
  )
}

update_archive <- function(questions_tibble) {
  if((s3_file_exists(ARCHIVE_FILEPATH)=='TRUE')) {
    archive <- s3tools::s3_path_to_full_df(ARCHIVE_FILEPATH, overwrite = FALSE)[2:10]
    updated_archive <- rbind(archive, questions_tibble)
  } else {
    updated_archive <- questions_tibble
  }
  
  duplicates_filter <- duplicated(updated_archive)
  updated_archive   <- updated_archive[!duplicates_filter,]
  s3tools::write_df_to_csv_in_s3(updated_archive, ARCHIVE_FILEPATH, overwrite =TRUE)
  
}

total_members <- function() {
  fromJSON('http://lda.data.parliament.uk/members.json?exists-party=true&_pageSize=1')$result$totalResults
}

get_all_members <- function(page_size) {
  members <- fromJSON(
    str_interp(
      "http://lda.data.parliament.uk/members.json?exists-party=true&_pageSize=${page_size}"
    )
  )$result$items
  members$fullName <- sapply(members$fullName[[1]], nameCleaner)
  members
}

get_parties <- function(names, constituencies) {
  page_size <- total_members()
  members   <- get_all_members(page_size)
  parties   <- map_chr(1:length(names), function(n) get_party(names[n], constituencies[n], members))
  parties
}

get_party <- function(name, constituency, members) {
  party <- members$party[ members$fullName == name & members$constituency$label == constituency, ]
  if(length(party) == 0) {
    return('Not found')
  } else {
    return(party)
  }
}

fetch_questions <- function(show_progress = FALSE) {
  
  number_to_fetch      <- number_to_fetch()
  number_in_archive    <- number_in_archive()
  number_held_remotely <- number_held_remotely()
  
  if(show_progress == TRUE) {
    missing_number <- number_held_remotely - number_in_archive
    print(str_interp("Fetching ${number_to_fetch} questions"))
    print(str_interp("(there are ${missing_number} relevant new questions)"))
  }
  
  iterations <- ceiling(number_to_fetch / 1000)
  
  if(iterations == 0) {
    stop("There are no new questions to fetch")
  }
  
  questions <- tibble()
  
  if((s3_file_exists(ARCHIVE_FILEPATH)=='TRUE')) {
    date        <- last_answer_date()
    date_param  <- str_interp("_where=?item%20parl:answer%20?a1.?a1%20parl:dateOfAnswer%20?dt.%20filter(str(?dt)%3E=%22${date}%22)")
    base_params <- str_interp("${date_param}&${MOJ_ONLY}&${MAX_DOWNLOAD}")
  } else {
    #s3tools::write_df_to_csv_in_s3(output, "alpha-app-pq-tool/archived_pqs.csv", overwrite =TRUE)
    base_params <- str_interp("${MOJ_ONLY}&${MAX_DOWNLOAD}")
  }
  
  if( (number_to_fetch + number_in_archive) < number_held_remotely ) {
    stop("An error has occurred. Please delete archived_pqs.csv (on S3) and re-run `fetch_questions()`")
  }
  
  for(iteration in c(1:iterations)) {
    page       <- iteration - 1
    page_param <- str_interp("_page=${page}")
    if(show_progress == TRUE) { print(str_interp("Fetching page ${iteration} of ${iterations}")) }
    response   <- fromJSON(str_interp("${API_ENDPOINT}?${base_params}&_sort=dateOfAnswer&${page_param}"))
    parsed_response <- parse_response(response$result$items)
    parsed_response$Question_MP <- sapply(parsed_response$Question_MP, nameCleaner)
    parsed_response$Answer_MP   <- sapply(parsed_response$Answer_MP, nameCleaner)
    parsed_response$Party       <- get_parties(parsed_response$Question_MP, parsed_response$MP_Constituency)
    update_archive(parsed_response)
  }
}


