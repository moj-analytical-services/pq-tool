source("./R/apiClient.R")

library(optparse)

#command line options to implement
option_list = list(
  make_option(c("-n", "--numOfQs"),
              type    = "numeric",
              default = 2000, 
              help    = "number of questions",
              metavar = "character"
  )
)

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);

#Number of questions to analyse

iterations <- ceiling(opt$numOfQs / 1000)

print("getting s3 data")
S3Data <- s3tools::s3_path_to_full_df(ARCHIVE_FILEPATH, overwrite = FALSE)[2:10]
S3Items <- S3Data %>%
  mutate_all(as.character)

#startIndex <- nrow(localData) - opt$numOfQs + 1
#localItems <- localData %>%
#  mutate_all(as.character)

print("getting remote data")
remoteItems <- data.frame(
  Question_MP = character(),
  Question_Text = character(),
  Question_ID = character(),
  MP_Constituency = character(),
  Question_Date = character(),
  Answer_Text = character(),
  Answer_MP = character(),
  Answer_Date = character(),
  Party = character()
)
numOfQs <- as.character(opt$numOfQs) #turn this into a character to be incorporated into the URL below
for (iteration in c(1:iterations)){
  print(str_interp("Fetching page ${iteration} of ${iterations}"))
  page       <- iteration - 1
  page_param <- str_interp("_page=${page}")
  numPerPage <- min(opt$numOfQs, 1000)
  page_size_param <- str_interp("_pageSize=${numPerPage}")
  print(str_interp("http://lda.data.parliament.uk/answeredquestions.json?&AnsweringBody=Ministry+of+Justice&${page_size_param}&_sort=-answer.dateOfAnswer&${page_param}"))
  remoteData <- fromJSON(str_interp("http://lda.data.parliament.uk/answeredquestions.json?&AnsweringBody=Ministry+of+Justice&${page_size_param}&_sort=-answer.dateOfAnswer&${page_param}"))
  print(str_interp("Parsing results"))
  remotePage <- parse_response(remoteData$result$items)
  print(str_interp("Cleaning names"))
  remotePage$Question_MP <- sapply(remotePage$Question_MP, nameCleaner)
  remotePage$Answer_MP   <- sapply(remotePage$Answer_MP, nameCleaner)
  print(str_interp("Adding parties"))
  remotePage$Party <- get_parties(remotePage$Question_MP, remotePage$MP_Constituency)
  print("Adding to previous data")
  remoteItems <- rbind(remoteItems, remotePage)
}

remoteItems <- remoteItems %>%
  arrange(Answer_Date, Question_ID)

S3Items <- S3Items %>%
  arrange(Answer_Date, Question_ID)

print("joining data up")
allItems <- left_join(remoteItems,
                      S3Items,
                      by = c("Question_ID",
                             "Answer_Date"),
                      suffix = c(".remote", ".S3")) %>%
  unique() %>%
  arrange(Answer_Date, Question_ID)

print("assessing similarities")
results <- sapply(allItems$Question_ID,
                  function(x) {
                    index <- which(allItems$Question_ID == x)
                    test <- areRemoteAndS3Equal(allItems[index,])
                    return(test)
                  })

if (all(results)) {
  print(str_interp("most recent ${numOfQs} questions match up"))
} else {
  print(str_interp("mismatch in most recent ${numOfQs} questions. Mismatched questions in nonMatchingQuestions.csv."))
  resultsSummary <- sapply(1:ncol(results), function(x) all(results[,x]))
  names(resultsSummary) <- allItems$Question_ID
  
  nonMatchingIDs <- names(which(resultsSummary == FALSE))
  whereTheyDontMatch <- results[, which(resultsSummary == FALSE)] %>% t() %>% as_tibble()
  nonMatchingQs <- allItems %>%
    filter(Question_ID %in% nonMatchingIDs)
  
  output <- cbind(nonMatchingQs, whereTheyDontMatch)
  
  s3tools::write_df_to_csv_in_s3(output, "alpha-app-pq-tool/nonMatchingQuestions.csv", overwrite =TRUE)

}


