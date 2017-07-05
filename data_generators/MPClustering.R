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
TopicsForMP <- function(MP, MPTopicMatrix){
  MPTopicMatrix[MP,] %>%
    melt() %>%
    mutate(topic = colnames(MPTopicMatrix)) %>%
    filter(value != 0) %>%
    select(topic, value) %>%
    arrange(desc(value)) %>%
    as.list()
}

SimilaritiesForMP <- function(MP, MPDistList){
  MPDistList %>%
    filter(Member1 == MP) %>%
    arrange(value)
}

QuestionsForMP <- function(MP, rawData){
  rawData[which(rawData$Question_MP == MP),] %>%
    as.list()
}

MPAnalysis <- function(MP, MPTopicMatrix, MPDistList, rawData){
  list(Topics = TopicsForMP(MP, MPTopicMatrix),
       SimilarMPs = SimilaritiesForMP(MP, MPDistList),
       Questions = QuestionsForMP(MP, rawData))
}


#topic analysis
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

SimilaritiesForTopic <- function(topicNum, topicDistList){
  topicDistList %>%
    filter(Topic1 == topicNum) %>%
    arrange(value) %>%
    as.list()
}

QuestionsForTopic <- function(topicNum, rawData){
  rawData[which(rawData$Cluster == topicNum),] %>%
    as.list()
}

topicAnalysis <- function(topicNum, MPTopicMatrix, topicDistList, rawData){
  list(MPs = MPsforTopic(topicNum, MPTopicMatrix),
       SimilarTopics = SimilaritiesForTopic(topicNum, topicDistList),
       Questions = QuestionsForTopic(topicNum, rawData))
}

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


setwd("../Data")
file <- "MoJwrittenPQs.csv"

rawData <- read.csv(file, stringsAsFactors = F)

MPTopicDf <- rawData %>%
  dcast(Question_MP ~ Cluster)

MPTopicMatrix <- MPTopicDf %>%
                     select(-Question_MP) %>%
                     as.matrix()

keywords <- unique(rawData$Cluster_Keywords[order(rawData$Cluster)])

rownames(MPTopicMatrix) <- MPTopicDf$Question_MP
colnames(MPTopicMatrix) <- keywords

MPsByNumOfQuestions <- MPTopicMatrix %>% rowSums() %>% sort(decreasing = TRUE)

TopicsByNumOfQuestions <- MPTopicMatrix %>% colSums() %>% sort(decreasing = TRUE)


MPTopicMatrixNormalised <- MPTopicMatrix %>%
                               IDF() %>%
                               t() %>%
                               normalize() %>%
                               t()

topicMPMatrixNormalised <- MPTopicMatrix %>%
  IDF() %>%
  normalize()
colnames(topicMPMatrixNormalised) <- NULL




MPDist <- 1 - (MPTopicMatrixNormalised %*% t(MPTopicMatrixNormalised))
MPDist[which(abs(MPDist) < 10^-10)] <- 0

topicDist <- 1 - (t(topicMPMatrixNormalised) %*% topicMPMatrixNormalised)
topicDist[which(abs(topicDist) < 10^-10)] <- 0

MPDistList <- MPDist %>%
                as.matrix() %>%
                melt() %>%
                rename(Member1 = Var1, Member2 = Var2) %>%
                mutate(Member1 = as.character(Member1),
                       Member2 = as.character(Member2))

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

