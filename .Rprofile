#### -- Packrat Autoloader (version 0.4.8-1) -- ####
source("packrat/init.R")
library(data.table)
library(readr)

SHINY_ROOT <- getwd()
TRAVIS <- FALSE
API_ENDPOINT      <- "http://lda.data.parliament.uk/answeredquestions.json"
MIN_DOWNLOAD      <- "_pageSize=1"
MAX_DOWNLOAD      <- "_pageSize=500"
ANSWERING_BODIES_LOOKUP <- data.table(read_tsv("./Data/answering_body_lookup.tsv"))



JUSTICE_STOP_WORDS <- c(
  "a", "b", "c", "d", "i", "ii", "iii", "iv",
  "secretary", "state", "ministry", "majesty","majestys",
  "government", "many", "ask", "whether",
  "assessment", "further", "pursuant",
  "minister", "steps", "department", "question",
  "step", "taking", "steps", "take", "make", "statement",
  "tackle", "policy", "latest", "period", "figures",
  "available", "representations", "ensure", "ensuring",
  "timetable", "much", "reduce", "since", "created", "came",
  "changes", "changed",
  "ability", "among", "announced", "bring", "change", "col",
  "column", "date", "deb", "definition", "delay", "early",
  "effect", "engage", "former", "hall", "highest", "hon",
  "implications", "items", "last", "matter", "merits",
  "paragraph", "plans", "questions", "tabled",
  "announce", "determining", "determine", "determines",
  "columns",
  "improve",
  "forward",
  "discussions",
  "taken", "recent",
  "cooperation",
  "matters",
  "provision",
  "provisions"
)




#### -- End Packrat Autoloader -- ####
