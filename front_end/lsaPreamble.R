#This is the file to get R to run when you start an RServe session for
#Tableau. It will give the R functionality needed to run the Tableau
#file. Note that it's important that the stopwordList and cleanCorpus
#functions are the same here as they are in DataCreator. If you want
#to make changes to them, you will want to regenerate the data too.

library(tm)
library(lsa)
library(cluster)
library(LSAfun)

#FUNCTIONS

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

#the following is a similarity query function
simQuery <- function(qtext,setoftexts) {
  qtext.stems <- tm_map(cleanCorpus(Corpus(VectorSource(qtext))),stemDocument)
  stemqText<-data.frame(text=unlist(sapply(qtext.stems, '[', 'content')), stringsAsFactors=F)
  SOTCorp <- tm_map(cleanCorpus(Corpus(VectorSource(setoftexts))),stemDocument)
  stemSOT <- data.frame(text=unlist(sapply(SOTCorp, '[', 'content')), stringsAsFactors=F)
  sapply(stemSOT$text,function(x) costring(stemqText$text,x,tvectors=lsaOut$tk),USE.NAMES = F)
}


#SCRIPT
#This loads stuff created by the DataCreator.R script

load(file = "lsaOut.rda")
load(file = "tdm.rda")
load(file = "klusters.rda")
