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

dates <- data.table(read_csv("./Data/moj/moj_WrittenPQs.csv"))
answering_bodies_lookup <- read_csv("./Data/answering_body_lookup.csv")


for(i in answering_bodies_lookup$Code){
  load(file = file.path("./Data", i, paste0(i, "_SearchSpace.rda")))
  assign(paste0(i, ".search.space"), search.space)
  # topic <- data.table(read_csv(file.path("./Data", i, paste0(i, "_TopDozenWordsPerTopic.csv"))))
  # assign(paste0(i, "_TopDozenWordsPerTopic"), topic)
  # member <- data.table(read_csv(file.path("./Data", i, paste0(i, "_TopDozenWordsPerMember.csv"))))
  # assign(paste0(i, "_TopDozenWordsPerMember"), member)
  # load(file = file.path("./Data", i, paste0(i, "_allTopics.rda")))
  # assign(paste0(i, "_allTopics"), allTopics)
}
  load(file = "./Data/allMPs.rda")


# Define R_date date type - to read in Long Date format in csv
setAs("character", "R_date", function(from) as.Date(from, "%d %B %Y"))
setClass("R_date")

