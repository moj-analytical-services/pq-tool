library(tm)

#need to source DataCreator functions

setwd("./tests/testthat")
file <- "./examples/data/MoJWrittenPQs.csv"
aPQ <- read.csv(file, stringsAsFactors = F)
corpus <- Corpus(VectorSource(aPQ$Question_Text))
cleancorpus <- cleanCorpus(corpus)

saveRDS(corpus, file = "./examples/data/corpus.rda")
saveRDS(cleancorpus, file = "./examples/data/cleaned_corpus.rda")
