#This is a toy bit of code to try out automating the discovery of MPs
#with similar interests based on them asking questions under the same
#topics, or (equivalently) topics that have been asked by similar MPs
library(tm)
library(reshape2)
library(dplyr)
library(slam)
library(cluster)

stopwordList <- c(
  stopwords(), "a", "b", "c", "d", "i", "ii", "iii", "iv",
  "secretary", "state", "ministry", "majesty","majestys",
  "government", "many", "ask", "whether",
  "assessment", "further", "pursuant",
  "minister", "steps", "department", "question"
)

#This gets the length of a vector
normVec <- function(vec){
  return(sqrt(sum(vec^2)))
}

#This normalises the lengths of a matrix to length 1
normalize <- function(mat){
  col.lengths <- sapply(1:ncol(mat), function(x) sqrt(sum(mat[, x]^2)))
  return(sweep(mat, 2, col.lengths, "/"))
}

#A function to calculate the Inverse Document Frequency to take into account the fact that
#there are some topics which MPS rarely ask about (and so those that do ask about those topics
#can be considered to have similar interests)
IDF <- function(matrix){
  rowSumsVec <- rowSums(matrix)
  nrows <- dim(matrix)[1]
  data <- sapply(seq(nrows),
                 function(x) sapply(matrix[x,],function(y) y*log2(nrow(matrix)/rowSumsVec[x])))
  output <- matrix(t(data), nrow = length(rowSumsVec))
  rownames(output) <- rownames(matrix)
  colnames(output) <- colnames(matrix)
  output
}

#MP analysis
#This gives the topics per MP, given the name of an MP
#and the MPTopicMatrix
TopicsForMP <- function(MP, MPTopicMatrix){
  MPTopicMatrix[MP,] %>%
    melt() %>%
    mutate(topic = colnames(MPTopicMatrix)) %>%
    filter(value != 0) %>%
    select(topic, value) %>%
    arrange(desc(value)) %>%
    as.list()
}

#This gives MPS who've asked about similar topics, given
#a focal MP and an MP Distance List
SimilaritiesForMP <- function(MP, MPDistList){
  MPDistList %>%
    filter(Member1 == MP) %>%
    arrange(value)
}

#This gives all the questions an MP has asked
QuestionsForMP <- function(MP, rawData){
  rawData[which(rawData$Question_MP == MP),] %>%
    as.list()
}

#This is a wrapper to return an object carrying all of the above
#analysis for a given MP
MPAnalysis <- function(MP, MPTopicMatrix, MPDistList, rawData){
  list(Topics = TopicsForMP(MP, MPTopicMatrix),
       SimilarMPs = SimilaritiesForMP(MP, MPDistList),
       Questions = QuestionsForMP(MP, rawData))
}


#topic analysis
#Top MPs per topic
MPsforTopic <- function(topicNum, MPTopicMatrix){
  MPTopicMatrix[,topicNum] %>%
    melt() %>%
    mutate(MP = rownames(MPTopicMatrix)) %>%
    filter(value != 0) %>%
    select(MP, value) %>%
    arrange(desc(value)) %>%
    rename(NumberOfQuestions = value) %>%
    as.list()
}

#Topics that have been asked by similar MPs to the focal topic
SimilaritiesForTopic <- function(topicNum, topicDistList){
  topicDistList %>%
    filter(Topic1 == topicNum) %>%
    arrange(value) %>%
    as.list()
}

#All the questions in a given topic
QuestionsForTopic <- function(topicNum, rawData){
  rawData[which(rawData$Cluster == topicNum),] %>%
    as.list()
}

#Wrapper to provide an object with all of the analysis in it
topicAnalysis <- function(topicNum, MPTopicMatrix, topicDistList, rawData){
  list(MPs = MPsforTopic(topicNum, MPTopicMatrix),
       SimilarTopics = SimilaritiesForTopic(topicNum, topicDistList),
       Questions = QuestionsForTopic(topicNum, rawData))
}

#Wordcloud (whoop!)
plotWordcloud <- function(analysisObject){
  words <- analysisObject$Questions$Question_Text %>%
             iconv(to = "utf-8", sub = "byte") %>%
             gsub("[^[:alnum:\\s]]", "", .) %>%
             removePunctuation() %>%
             removeWords(c("Justice")) %>%
             tolower() %>%
             removeWords(stopwordList)
  wordcloud(words, max.words = 50)
}


#Analysis

#get data
setwd("../Data")
file <- "MoJwrittenPQs.csv"
rawData <- read.csv(file, stringsAsFactors = F)

#A data frame of the data
MPTopicDf <- rawData %>%
  dcast(Question_MP ~ Cluster)

#now turning it into a matrix
MPTopicMatrix <- MPTopicDf %>%
                     select(-Question_MP) %>%
                     as.matrix()

#topic three key word descriptions
keywords <- unique(rawData$Cluster_Keywords[order(rawData$Cluster)])

rownames(MPTopicMatrix) <- MPTopicDf$Question_MP
colnames(MPTopicMatrix) <- keywords

#apply IDF to the data, and then normalise to that all MPs are considered
#to have the same amount of total 'interest'
MPTopicMatrixNormalised <- MPTopicMatrix %>%
                               IDF() %>%
                               t() %>%
                               normalize() %>%
                               t()

#do the same for the topic analysis
topicMPMatrixNormalised <- MPTopicMatrix %>%
  IDF() %>%
  normalize()
colnames(topicMPMatrixNormalised) <- NULL

#distances between MPs - we can use a dot product for shortcut
MPDist <- 1 - (MPTopicMatrixNormalised %*% t(MPTopicMatrixNormalised))
#to take out floating point crap we take out small numbers
MPDist[which(abs(MPDist) < 10^-10)] <- 0

#same for topic distances
topicDist <- 1 - (t(topicMPMatrixNormalised) %*% topicMPMatrixNormalised)
topicDist[which(abs(topicDist) < 10^-10)] <- 0

#give pairwise distances between all MPs (rather than the matrix)
MPDistList <- MPDist %>%
                as.matrix() %>%
                melt() %>%
                rename(Member1 = Var1, Member2 = Var2) %>%
                mutate(Member1 = as.character(Member1),
                       Member2 = as.character(Member2))

#ditto for topics
topicDistList <- topicDist %>%
                   as.matrix() %>%
                   melt() %>%
                   rename(Topic1 = Var1, Topic2 = Var2) %>%
                   mutate(Topic1 = as.character(Topic1),
                          Topic2 = as.character(Topic2),
                          TopicKeywords1 = keywords[as.numeric(Topic1)],
                          TopicKeywords2 = keywords[as.numeric(Topic2)]) %>%
                   select(Topic1, TopicKeywords1, Topic2, TopicKeywords2, value)


#Go output

DA <- MPAnalysis("Abbott, Diane", MPTopicMatrix, MPDistList, rawData)

PD <- MPAnalysis("Davies, Philip", MPTopicMatrix, MPDistList, rawData)

allMPs <- lapply(MPTopicDf$Question_MP,function(x) MPAnalysis(x, MPTopicMatrix, MPDistList, rawData))
names(allMPs) <- MPTopicDf$Question_MP

allTopics <- lapply(seq(1000), function(x) topicAnalysis(x, MPTopicMatrix, topicDistList, rawData))
names(allTopics) <- seq(1000)

save(MPDistList, file = "MPDistList")

save(allMPs, file = "allMPs.rda")
save(allTopics, file = "allTopics.rda")

