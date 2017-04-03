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


v_names<-sappy(tdm_i, function(c) tdmDimNames[[1]][c])
space_names<-sapply(search.space$i, function(c) tdmDimNames[[1]][c])

clust<-function(n){
  t<-which(bigSKmeans2$cluster==n)
  return(t)
}

prot<- function(n,tol){
  if(is.string(n)){
    t<-bigSKmeans2$prototypes[which(bigSKmeans2$prototypes[,n]>tol),n]
  }else{
    t<-bigSKmeans2$prototypes[n,which(bigSKmeans2$prototypes[n,]>tol)]
  }
  return(sort(t, decreasing = TRUE))
}



doc<- function(n){
  t<-tdm$v[tdm$j==n]
  return(t)
}

test_query<-function(query, tol=1e-02){
  query<-query%>%tolower()%>%removeWords(stopwords_en)%>%
          strsplit(" ")%>%
          sapply(stemDocument)%>%
          (function(vec){
            return(vec[sapply(vec, function(x) x %in% v_names)])
          })
  return(lapply(query, function(x) prot(x,tol)))
}



qtext<-'Example query with words in it.'
qtext.stems <- tm_map(Corpus(VectorSource(qtext)),stemDocument)
stemqText<-data.frame(text=unlist(sapply(qtext.stems, '[', 'content')), stringsAsFactors=F)
