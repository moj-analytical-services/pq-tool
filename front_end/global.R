library(tm)
library(lsa)
library(cluster)
library(LSAfun)
library(shiny)
library(DT)

# Define R_date date type - to read in Long Date format in csv
setAs("character", "R_date", function(from) as.Date(from, "%d %B %Y"))
setClass('R_date')
myColClasses = c("Date" = "R_date",
                 "Answer_Date" = "R_date")

rawData = read.csv('/Users/admin/Documents/PQtools/Data/MoJallPQsforTableau.csv',colClasses = myColClasses)
d = data.frame(rawData )

#This loads stuff created by the DataCreator.R script

load(file = "lsaOut.rda")
load(file = "tdm.rda")
load(file = "klusters.rda")

stopwordList <- c(
  stopwords(),'a','b','c','d','i','ii','iii','iv',
  'secretary','state','ministry','majesty',
  'government','many','ask','whether',
  'assessment','further','pursuant','justice',
  'minister','steps','department','question'
)

cleanCorpus <- function(corp) {
  corp <-tm_map(corp, content_transformer(function(x) iconv(x, to='UTF-8-MAC', sub='byte')))
  toSpace <- content_transformer(function(x, pattern) { return (gsub(pattern, ' ', x))})
  corp <- tm_map(corp, toSpace, '-')
  corp <- tm_map(corp, toSpace, '’')
  corp <- tm_map(corp, toSpace, '‘')
  corp <- tm_map(corp, toSpace, '•')
  corp <- tm_map(corp, toSpace, '”')
  corp <- tm_map(corp, toSpace, '“')
  corp <- tm_map(corp,content_transformer(tolower))
  corp <- tm_map(corp,removePunctuation)
  corp <- tm_map(corp,stripWhitespace)
  corp <- tm_map(corp, function(x) removeWords(x,stopwordList))
}