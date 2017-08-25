#### -- Packrat Autoloader (version 0.4.8-1) -- ####
SHINY_ROOT <- getwd()
ARCHIVE_FILEPATH  <- file.path(SHINY_ROOT, 'Data', 'archived_pqs.csv')
API_ENDPOINT      <- "http://lda.data.parliament.uk/answeredquestions.json"
MOJ_ONLY          <- "AnsweringBody=Ministry+of+Justice"
MIN_DOWNLOAD      <- "_pageSize=1"
MAX_DOWNLOAD      <- "_pageSize=1000"
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
  "matters"

)
source("packrat/init.R")
#### -- End Packrat Autoloader -- ####
