#This code returns an index of PQ documents of decreasing similarity given a search query.
#
#The idea behind it is to use the sparsity of a normalised lsa space, so that cosine calcuations can be done with fast vector sums.  
#
#In a normalised lsa space, we have a rank-reduced term document matrix with columns (corresponding to documents) normalised to length 1.  By pre-processing the query into a binary vector, each query-document dot product q^Td is simply the sum of the entries of the column corresponding to d, but only those entries corresponding to terms (rows) found in the query.  We have q^Td = |q||d|cos(t) (where t is the angle between q and d), |d| = 1 for all documents, and |q| is constant for a given query, we obtain a constant multiple (|q| times) of the cosine between q and d by doing this quick summation (made quicker thanks to Karik introducing me to data.table).
#
#CAVEAT: to make this run fast, I have 'sparsified' the normalised rank-reduced tdm by setting all values within 0.01 of zero to zero  and put it into simple-triplet format (which doesn't store zero values in memory).  The result is that |d| is no longer constant across all documents.  They now vary slightly in length, but only differ by 0.035 at most (summary stats on the distribution of lengths can be found in the code) so it's not too uch of a problem.
#
#

#This loads stuff created by the DataCreator.R script

load(file = "lsaOut.rda")
load(file = "tdm.rda")
load(file = "klusters.rda")

library(data.table) #Thanks Karik
library(tm)
library(lsa)
library(cluster)

#First create global lsa space- lsaDim function lets us produce lsa space of arbitrary dimension

lsaAll <- lsa(tdm,dimcalc_raw())  #tdm is the TermDocumentMatrix generated in DataCreator.R

lsaDim<-function(dim){return(lsaAll$tk[,1:dim] %*% diag(lsaAll$sk[1:dim]) %*% t(lsaAll$dk[,1:dim]))}

#We use rank-1000 space as we are forcing 1000 clusters
space.share <- lsaAll$tk[,1:1000] %*% diag(lsaAll$sk[1:1000]) %*% t(lsaAll$dk[,1:1000])


#A couple of utility functions, the first gets the length of a vector, the second normalizes
#the lengths of a matrix to length 1
normVec <- function(vec){return(sqrt(sum(vec^2)))}

normalize <- function(mat){
  col.lengths <- sapply(1:ncol(mat), function(x) sqrt(sum(mat[,x]^2)))
  return(sweep(mat,2,col.lengths,"/"))
}
space.share.norm <- normalize(space.share)

search.space <- space.share.norm
search.space[which(abs(search.space)<0.01)] <- 0
##This is just a check to see that this sparsification doesn't lead to wildly varying document lengths
collengths <- sapply(1:5461, function(x) normVec(search.space[,x]))
summary(collengths)
##################

search.space <- as.simple_triplet_matrix(search.space)

#Search space for query vector
werdz <- search.space$dimnames[[1]]

#Function to vectorize query
queryVec <- function(query){
    query <- query%>%tolower()%>%removePunctuation%>%
        removeWords(stopwordList)%>%
        strsplit(" ")%>%
        sapply(stemDocument)%>%
        (function(vec){
            return(vec[sapply(vec, function(x) x %in% werdz)])
        })
    
    return(which(werdz %in% query))
}
