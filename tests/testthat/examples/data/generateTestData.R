library(tm)
library(dplyr)

#need to source DataCreator functions

setwd("./tests/testthat")
file <- "./examples/data/MoJWrittenPQs.csv"
aPQ <- read.csv(file, stringsAsFactors = F)
corpus <- Corpus(VectorSource(aPQ$Question_Text))
cleancorpus <- cleanCorpus(corpus)

saveRDS(corpus, file = "./examples/data/corpus.rda")
saveRDS(cleancorpus, file = "./examples/data/cleaned_corpus.rda")


origl <- read.csv("./examples/data/archived_pqs.csv", stringsAsFactors = F)

both <- left_join(origl,
                  origl,
                  by = c("Question_ID",
                         "Answer_Date"),
                  suffix = c(".remote", ".local")) %>%
  unique()

write.csv(both, file = "./examples/data/TestQsData.csv")
