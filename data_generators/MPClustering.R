#This is a toy bit of code to try out automating the discovery of MPs
#with similar interests based on them asking questions under the same
#topics, or (equivalently) topics that have been asked by similar MPs

library(reshape2)
#library(tibble)
library(dplyr)
library(slam)
library(cluster)

#This gets the length of a vector
normVec <- function(vec){
  return(sqrt(sum(vec^2)))
}

#This normalises the lengths of a matrix to length 1
normalize <- function(mat){
  col.lengths <- sapply(1:ncol(mat), function(x) sqrt(sum(mat[, x]^2)))
  return(sweep(mat, 2, col.lengths, "/"))
}

TopMPsForTopic <- function(TopicNum,dataMatrix){
  MpsAndTopic <- dataMatrix %>% select(1,TopicNum+1)
  colnames(MpsAndTopic) <- c("Person","Topic")
  MpsAndTopic <- arrange(MpsAndTopic,desc(Topic))
}


setwd("../Data")
file <- "MoJwrittenPQs.csv"

load("searchSpace.rda")


distMat <- t(as.matrix(search.space)) %*% as.matrix(search.space)

hier <- hclust(as.dist(distMat),method="complete")

k <- 1000

cluster <- cutree(hier,k)

rawData <- read.csv(file, stringsAsFactors = F)

rawData$Cluster <- cluster

MPTopicDf <- rawData %>%
  dcast(Question_MP ~ Cluster)

MPTopicMatrix <- MPTopicDf %>%
                     select(-Question_MP) %>%
                     as.matrix()

rownames(MPTopicMatrix) <- MPTopicDf$Question_MP

MPTopicMatrixNormalised <- MPTopicMatrix %>%
                               t() %>%
                               normalize() %>%
                               t()


MPDist <- 1 - (MPTopicMatrixNormalised %*% t(MPTopicMatrixNormalised))
MPDist[which(abs(MPDist) < 10^-10)] <- 0

MPDistList <- MPDist %>%
                as.matrix() %>%
                melt() %>%
                rename(Member1 = Var1, Member2 = Var2)

PD <- MPDistList %>%
        filter(Member1 == "Davies, Philip") %>%
        arrange(value)

KG <- MPDistList %>%
        filter(Member1 == "Green, Kate") %>%
        arrange(value)

topicDistList <- topicDist %>%
                   as.matrix() %>%
                   melt() %>%
                   rename(Topic1 = Var1, Topic2 = Var2)

top <- topicDistList %>%
         filter(Topic1 == 3) %>%
         arrange(value)

topicDistList %>% arrange(value) %>% View()
