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

ANSWERING_BODIES_LOOKUP <- read_tsv("./Data/answering_body_lookup.tsv")

for(code in ANSWERING_BODIES_LOOKUP$Code){
  load(file = file.path("./Data", code, paste0(code, "_SearchSpace.rda")))
  assign(paste0(code, ".search.space"), search.space)
  # load(file = file.path("./Data", i, paste0(i, "_allTopics.rda")))
  # assign(paste0(i, "_allTopics"), allTopics)
}

