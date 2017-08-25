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

cleanPQ <- function(PQ){
  PQ <- PQ %>% iconv(to = "utf-8", sub = "") %>%
    #inelegant special cleaning steps 1
    #ensure High Down doesn't get confused with Legal Highs
    gsub("High Down", "Highdown", .) %>%
    gsub("-", " ", .) %>%
    gsub("<i>|</i>", "", .) %>%
    gsub("'", "", .) %>%
    gsub("[^A-Z a-z 0-9 //s]", " ", .) %>%
    #we now remove Justice with a capital J here before the transformation to lower
    #case, because this deals with the fact that a lot of questions start with "To ask
    #the Secretary of State for Justice" without losing potential information about eg
    #access to justice related questions
    removeWords(c("Justice")) %>%
    tolower() %>%
    #inelegant special cleaning steps 2
    #put "re-offending" and "reoffending" together
    gsub("re off", "reoff", .) %>%
    #put "post-morterm" and "postmortem" together
    sub("post mortem", "postmortem", .) %>%
    #anti- always part of the word that follows it,
    #eg antisemitism not anti-semitism
    gsub("anti ", "anti", .) %>%
    #ditto for cross-examination
    gsub("cross exam", "crossexam", .) %>%
    #ditto for co-operation
    gsub("co oper", "cooper", .) %>%
    #ditto for socio-economic
    gsub("socio eco", "socioeco", .) %>%
    #ditto for inter-library and inter-parliamentary
    gsub("inter ", "inter", .) %>%
    #ditto for non-profit, non-molestation, non-payroll, etc
    gsub("non ", "non", .) %>%
    #ditto for pre-nuptial, pre-recorded, etc
    gsub("pre ", "pre", .) %>%
    #ditto for ex-offenders, etc
    gsub(" ex ", " ex", .) %>%
    #correct one-off spelling mistakes in data
    gsub("rehabilitaiton", "rehabilitation", .) %>%
    gsub("organisaiton", "organisation", .) %>%
    #issue with "directive" and "direction" being stemmed to the same thing.
    gsub("directive|directives", "drctv", .) %>%
    gsub("direction|directions", "drctn", .) %>%
    #issue with "internal" and "international" being stemmed to the same thing (!).
    gsub("internal", "intrnl", .) %>%
    #replace instances of the word "probation" with "probatn" to avoid the
    #issue with "probate" and "probation" being stemmed to the same thing.
    gsub("probation", "probatn", .) %>%
    #make sure Network Rail is seen as distinct from other mentions of network
    gsub("network rail", "networkrail", .) %>%
    removeWords(c(stopwords(), JUSTICE_STOP_WORDS)) %>%
    stripWhitespace()
}

queryVec <- function(query){
  query <- query %>%
    cleanPQ() %>%
    stemDocument() %>%
    strsplit(" ") %>%
    unlist() %>%
    (function(vec){
      return(vec[sapply(vec, function(x) x %in% vocab)])
    })
  return(which(vocab %in% query))
}

#some stuff to transform MP/peer names into URLs

familyName <- function(name){
  commaPosn <- regexpr(",", name) %>% as.vector()
  substr(name, 1, commaPosn-1)
}

firstName <- function(name){
  commaPosn <- regexpr(",", name) %>% as.vector()
  substr(name, commaPosn+2, nchar(name))
}

urlName <- function(name){
  fn <- firstName(name)
  if(
    grepl(
      "Lord|Lady|The|Baroness|Baron|Viscount",
      name
    )){
    name %>%
      gsub("The ", "", .) %>%
      gsub("Lord Bishop", "Bishop", .) %>%
      gsub(" ", "_", .)
  } else {
    paste0(firstName(name), "_", familyName(name), sep="") %>%
      gsub("Dr |Sir ", "", .) %>%
      gsub("de ", "de_", .) %>%
      gsub(" ", "-", .)
  }
}

