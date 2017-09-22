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

answering_bodies_lookup <- read_csv("./Data/answering_body_lookup.csv")

<<<<<<< HEAD
for(i in answering_bodies_lookup$Code){
  load(file = file.path("./Data", i, paste0(i, "_SearchSpace.rda")))
  assign(paste0(i, ".search.space"), search.space)
  # load(file = file.path("./Data", i, paste0(i, "_allTopics.rda")))
  # assign(paste0(i, "_allTopics"), allTopics)
}
  load(file = "./Data/allMPs.rda")
=======

answering_bodies_lookup <- data.table(read_csv("./Data/answering_body_lookup.csv"))


data_file <- reactive({
  return(file.path("./Data", answering_bodies_lookup$Code[answering_bodies_lookup$Name == input$answering_body_choice]))
})

load(file = file.path(data_file(), "searchSpace.rda"))
load(file = file.path(data_file(), "allMPs.rda"))
load(file = file.path(data_file(), "allTopics.rda"))
>>>>>>> 236ba1112764bc76e33de84071e93c515b5d1b8f

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
