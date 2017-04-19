library(shiny)
library(DT)
library(dplyr)
library(plyr)
library(ggplot2)
library(plotly)
library(wordcloud)
library(slam)

# Define R_date date type - to read in Long Date format in csv
setAs("character", "R_date", function(from) as.Date(from, "%d %B %Y"))
setClass('R_date')
myColClasses <- c("Date" = "R_date",
                 "Answer_Date" = "R_date")

rawData <- read.csv('../Data/MoJallPQsforTableau.csv',colClasses = myColClasses)
data <- data.frame(rawData)
data[is.na(data$MP_Constituency)] = "None"
data["Question_MP"] <- lapply(data["Question_MP"], function(x) { 
  gsub("Mr |Mrs |Ms ", "", x)
  })

cluster_data <- read.csv("../Data/topDozen.csv")

stopwordList <- c(
  stopwords(),'a','b','c','d','i','ii','iii','iv',
  'secretary','state','ministry','majesty',
  'government','many','ask','whether',
  'assessment','further','pursuant','justice',
  'minister','steps','department','question'
  
  
col_names <- c('Document #', 'Question ID', 'Question', 'Answer', 'Question MP', 'Answer MP', 'Q Date','A Date', 'Cluster','Similarity Score')

merged_clusters <- ddply(data, .(Date, Answer_Date, Cluster), summarize, Question_Text = paste0(Question_Text, collapse = " "))
