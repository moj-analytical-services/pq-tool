library(shiny)
library(DT)
library(dplyr)
library(plyr)
library(ggplot2)
library(plotly)
library(wordcloud)
library(tm)
library(lsa)
library(cluster)
library(slam)
library(data.table) #Thanks Karik
library(shinythemes)
library(shinyBS)
library(scales)
library(readr)
library(rintrojs)
library(aws.s3)

# You need to put our AWS credentials in .Renviron for this to work
latest.searchSpace <- get_bucket(
    bucket = S3_BUCKET,
    prefix = 'search_space'
  )$Contents$Key
search.space <- s3readRDS(bucket = S3_BUCKET, object = latest.searchSpace)

latest.pqs <- get_bucket(
    bucket = S3_BUCKET,
    prefix = 'moj_questions'
  )$Contents$Key
data <- s3readRDS(bucket = S3_BUCKET, object = latest.pqs)

latest.topDozenWords <- get_bucket(
    bucket = S3_BUCKET,
    prefix = 'top_dozen_words'
  )$Contents$Key
topic_data <- s3readRDS(bucket = S3_BUCKET, object = latest.topDozenWords)

member_data <- read.csv("./Data/topDozenWordsPerMember.csv")

merged_clusters <- ddply(
  data,
  .(Date, Answer_Date, Topic),
  summarize,
  Question_Text = paste0(Question_Text, collapse = " "))

#Search space for query vector
vocab <- search.space$dimnames[[1]]

#Function to vectorize query - steps here need to match those in the cleanCorpus 
#function in the DataCreator file so that we are consistent in our treatment.
#This program requires the argument "query", which is the search text, and the 
#global object "vocab", defined above, which is our global vocabulary comprised
#of all the words in our corpus of PQs (appropriately stemmed and so on).

#The idea behind it is to use the sparsity of a normalised lsa space, so that
#cosine calcuations can be done with fast vector sums.  
#
#In a normalised lsa space, we have a rank-reduced term document matrix with
#columns (corresponding to documents) normalised to length 1.  By
#pre-processing the query into a binary vector, each query-document dot product
#q^Td is simply the sum of the entries of the column corresponding to d, but
#only those entries corresponding to terms (rows) found in the query. 
#We have q^Td = |q||d|cos(t) (where t is the angle between q and d), |d| = 1
#for all documents, and |q| is constant for a given query, we obtain a constant
#multiple (|q| times) of the cosine between q and d by doing this quick summation
#(made quicker thanks to Karik introducing me to data.table).

#If you change this you also need to change cleanCorpus function in
#the dataCreator.R file

queryVec <- function(query){
  query <- query %>% iconv(to = "utf-8", sub = "") %>%
    gsub("High Down", "Highdown", .) %>%
    gsub("-", " ", .) %>%
    gsub("<i>|</i>", "", .) %>%
    gsub("[^(A-Z a-z 0-9 //s)]", "", .) %>%
    removePunctuation() %>%
    removeWords(c("Justice")) %>%
    tolower() %>%
    gsub("re off", "reoff", .) %>%
    gsub("anti ", "anti", .) %>%
    gsub("cross exam", "crossexam", .) %>%
    gsub("socio eco", "socioeco", .) %>%
    gsub("inter ", "inter", .) %>%
    gsub("rehabilitaiton", "rehabilitation", .) %>% #included out of completeness to be the same as cleanCorpus
    gsub("organisaiton", "organisation", .) %>% #included out of completeness to be the same as cleanCorpus
    gsub("directive|directives", "drctv", .) %>%
    gsub("direction|directions", "drctn", .) %>%
    gsub("internal", "intrnl", .) %>%
    gsub("probation", "probatn", .) %>%
    gsub("network rail", "networkrail", .) %>%
    removeWords(c(stopwords(), JUSTICE_STOP_WORDS)) %>%
    stripWhitespace() %>%
    strsplit(" ") %>%
    sapply(stemDocument) %>%
    (function(vec){
      return(vec[sapply(vec, function(x) x %in% vocab)])
    })
  return(which(vocab %in% query))
}

