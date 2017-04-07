ptm<-proc.time()
lsaOut<-lsa(tdm,dimcalc_kaiser())
proc.time()-ptm

ptm<-proc.time()
lsaShare<-lsa(tdm,dimcalc_share())
proc.time()-ptm


lsaAll<-lsa(tdm,dimcalc_raw())

lsaDim<-function(dim){return(lsaAll$tk[,1:dim] %*% diag(lsaAll$sk[1:dim]) %*% t(lsaAll$dk[,1:dim]))}

space<-lsaOut$tk %*% diag(lsaOut$sk) %*% t(lsaOut$dk)
dimcalc_share()(lsaAll$sk)

space.share<-lsaAll$tk[,1:1000] %*% diag(lsaAll$sk[1:1000]) %*% t(lsaAll$dk[,1:1000])
ptm<-proc.time()
tdmSKmeans<-skmeans(t(tdm), k=1000, method = 'pclust', control = list(maxiter = 15, nruns =100, verbose = TRUE))
proc.time()-ptm

ptm<-proc.time()
tdmSKmeans<-skmeans(t(tdm), k=1000, method = 'pclust', control = list(maxiter = 105, start = tdmSKmeans, maxchains = 30, verbose = TRUE))
proc.time()-ptm

normVec<-function(vec){return(sqrt(sum(vec^2)))}

normalize<-function(mat){
  col.lengths<-sapply(1:ncol(mat), function(x) sqrt(sum(mat[,x]^2)))
  return(sweep(mat,2,col.lengths,"/"))
}
space.share.norm<-normalize(space.share)

search.space<-space.share.norm
search.space[which(search.space<0.01)]<-0
search.space<-as.simple_triplet_matrix(search.space)

ptm<-proc.time()
bigSKmeans<-skmeans(t(search.space), k=1000, method = 'pclust', control = list(maxiter = 15, nruns =5, verbose = TRUE))
proc.time()-ptm

ptm<-proc.time()
bSKmeans_start<-skmeans(t(search.space), k=1000, method = 'pclust', control = list(maxiter = 50, maxchains = 20, start = bSKmeans_start, verbose = TRUE))
proc.time()-ptm

bigSKmeans2<-bSKmeans_start
sparseSKmeans<-bigSKmeans2$prototypes
sparseSKmeans[which(abs(sparseSKmeans)<0.01)]<-0

sparseSKmeans<-skmeans(t(search.space), k=1000, method = 'pclust', control = list(maxiter =1, nruns = 1, start = sparseSKmeans, verbose = TRUE))

shinyKlust<-MoJallPQsforTableau$Cluster
shinySKmeans<-skmeans(t(lsaOut), k=1000, method = 'pclust', control = list(maxiter =1, maxchains = 1, start = shinyKlust, verbose = TRUE))


v_names<-sapply(tdm$i, function(c) tdmDimNames[[1]][c])
space_names<-sapply(search.space$i, function(c) tdmDimNames[[1]][c])

clust<-function(n){
  t<-which(bigSKmeans2$cluster==n)
  return(t)
}

prot<- function(n,tol, skProt){
  if(is.string(n)){
      print(n)
    t<-skProt[which(skProt[,n]>tol),n]
  }else{
    t<-skProt[n,which(skProt[n,]>tol)]
  }
  return(sort(t, decreasing = TRUE))
}



doc<- function(n){
  t<-tdm$v[tdm$j==n]
  return(t)
}
stopwordList <- c(
    stopwords(),'a','b','c','d','i','ii','iii','iv',
    'secretary','state','ministry','majesty',
    'government','many','ask','whether',
    'assessment','further','pursuant','justice',
    'minister','steps','department','question'
)
test_query<-function(query, tol=1e-02, skProt = bigSKmeans2$prototypes){
  query<-query%>%tolower()%>%removeWords(stopwordList)%>%
          strsplit(" ")%>%
          sapply(stemDocument)%>%
          (function(vec){
            return(vec[sapply(vec, function(x) x %in% v_names)])
          })
  return(lapply(query, function(x){
                                    k<-prot(x,tol, skProt)
                                    return(k[which(k>0.1)])
                                    }
                                    ))
}


#Search space for query vector
werdz<-search.space$dimnames[[1]]

#Function to vectorize query
queryVec<-function(query){
    query<-query%>%tolower()%>%removePunctuation%>%
        removeWords(stopwordList)%>%
        strsplit(" ")%>%
        sapply(stemDocument)%>%
        (function(vec){
            return(vec[sapply(vec, function(x) x %in% werdz)])
        })
    
    return(which(werdz %in% query))
}

#Function to return top 30 matches - needs search.space.rda to run
returnNearestMatches<-function(que, space = tdm){
foundWords<-which(space$i %in% queryVec(que))
#eyes<-search.space$i[foundWords]
jays<-space$j[foundWords]
vees <-space$v[foundWords]
JayVees <- data.table(jays = jays, vees = vees)
outGroup <- JayVees[, .("Vee_sum" = sum(vees)), by = jays ][order(-Vee_sum)]
outGroup[1:30]
}


qtext<-'Example query with words in it.'
qtext.stems <- tm_map(Corpus(VectorSource(qtext)),stemDocument)
stemqText<-data.frame(text=unlist(sapply(qtext.stems, '[', 'content')), stringsAsFactors=F)


sum(sapply(cands, 
       function(d) {
           sum(sapply(names(d), 
                      function(x){
                          length(clust(as.integer(x)))
               
           })
    
)})
)
names(search.space$v)<-sapply(search.space$i, function(x) search.space$dimnames[[1]][x])
stmScProd<-function(x,y, mat = search.space){
    
}


#### Karik being awesome
library(data.table)

