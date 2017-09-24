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

dates <- data.table(read_csv("./Data/moj/moj_writtenPQs.csv"))
answering_bodies_lookup <- read_csv("./Data/answering_body_lookup.csv")


for(i in answering_bodies_lookup$Code){
  load(file = file.path("./Data", i, paste0(i, "_SearchSpace.rda")))
  assign(paste0(i, ".search.space"), search.space)
  
  # load(file = file.path("./Data", i, paste0(i, "_allTopics.rda")))
  # assign(paste0(i, "_allTopics"), allTopics)
}
  load(file = "./Data/allMPs.rda")


# Define R_date date type - to read in Long Date format in csv
setAs("character", "R_date", function(from) as.Date(from, "%d %B %Y"))
setClass("R_date")


# topic_data <- reactive({
#   read.csv(file.path(data_file, "topDozenWordsPerTopic.csv"))
# })
# 
# member_data <- reative({
#   read.csv(file.path(data_file, "topDozenWordsPerMember.csv"))
# })
# 
# merged_clusters <- reactive({ddply(
#   data(),
#   .(Date, Answer_Date, Topic),
#   summarize,
#   Question_Text = paste0(Question_Text, collapse = " "))
# })
