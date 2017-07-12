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
library(aws.s3)

# You need to put our AWS credentials in .Renviron for this to work
latest.searchSpace <- get_bucket(
    bucket = 'parliamentary-questions-tool',
    prefix = 'search_space'
  )$Contents$Key
search.space <- s3readRDS(bucket = 'parliamentary-questions-tool', object = latest.searchSpace)

latest.pqs <- get_bucket(
    bucket = 'parliamentary-questions-tool',
    prefix = 'moj_questions'
  )$Contents$Key
data <- s3readRDS(bucket = 'parliamentary-questions-tool', object = latest.pqs)

latest.topDozenWords <- get_bucket(
    bucket = 'parliamentary-questions-tool',
    prefix = 'top_dozen_words'
  )$Contents$Key
topic_data <- s3readRDS(bucket = 'parliamentary-questions-tool', object = latest.topDozenWords)

merged_clusters <- ddply(
  data,
  .(Date, Answer_Date, Topic),
  summarize,
  Question_Text = paste0(Question_Text, collapse = " "))

stopwordList <- c(
  stopwords(), "a", "b", "c", "d", "i", "ii", "iii", "iv",
  "secretary", "state", "ministry", "majesty","majestys",
  "government", "many", "ask", "whether",
  "assessment", "further", "pursuant",
  "minister", "steps", "department", "question"
)
  
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
  query <- query %>% iconv(to = "utf-8", sub = "byte") %>%
    gsub("[^[:alnum:\\s]]", "", .) %>%
    removePunctuation() %>%
    stripWhitespace() %>%
    removeWords(c("Justice")) %>%
    tolower() %>%
    gsub("probation", "probatn", .) %>%
    removeWords(stopwordList) %>%
    strsplit(" ") %>%
    sapply(stemDocument) %>%
    (function(vec){
      return(vec[sapply(vec, function(x) x %in% vocab)])
    })
  return(which(vocab %in% query))
}
