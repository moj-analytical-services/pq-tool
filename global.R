source('./R/Functions.R')

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


load(file = "./Data/ho/searchSpace.rda")
load(file = "./Data/ho/allMPs.rda")
load(file = "./Data/ho/allTopics.rda")

# Define R_date date type - to read in Long Date format in csv
setAs("character", "R_date", function(from) as.Date(from, "%d %B %Y"))
setClass("R_date")

rawData <- read_csv("./Data/writtenPQs.csv")
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



