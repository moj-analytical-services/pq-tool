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

load(file = "./Data/searchSpace.rda")
load(file = "./Data/allMPs.rda")
load(file = "./Data/allTopics.rda")

# Define R_date date type - to read in Long Date format in csv
setAs("character", "R_date", function(from) as.Date(from, "%d %B %Y"))
setClass("R_date")

rawData <- read_csv("./Data/MoJwrittenPQs.csv")
data <- data.frame(rawData)
drops <- c("X1","Document_Number", "Corrected_Date")
tables_data <- data[ , !(names(data) %in% drops)]


topic_data <- read.csv("./Data/topDozenWordsPerTopic.csv")

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
    gsub("re-off", "reoff", .) %>%
    gsub("-", " ", .) %>%
    gsub("[^(A-Z a-z 0-9 //s)]", "", .) %>%
    removePunctuation() %>%
    removeWords(c("Justice")) %>%
    tolower() %>%
    gsub("probation", "probatn", .) %>%
    removeWords(c(stopwords(), JUSTICE_STOP_WORDS)) %>%
    stripWhitespace() %>%
    strsplit(" ") %>%
    sapply(stemDocument) %>%
    (function(vec){
      return(vec[sapply(vec, function(x) x %in% vocab)])
    })
  return(which(vocab %in% query))
}

plotWordcloud <- function(analysisObject){
  words <- analysisObject$Questions$Question_Text %>%
    iconv(to = "utf-8", sub = "byte") %>%
    gsub("[^[:alnum:\\s]]", "", .) %>%
    removePunctuation() %>%
    removeWords(c("Justice")) %>%
    tolower() %>%
    # JUSTICE_STOP_WORDS assigned in .Rprofile
    removeWords(c(stopwords(), JUSTICE_STOP_WORDS))
  wordcloud(words, max.words = 50)
}
