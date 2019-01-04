#### -- Packrat Autoloader (version 0.4.8-1) -- ####
SHINY_ROOT <- getwd()
TRAVIS <- FALSE
ARCHIVE_FILEPATH  <- "alpha-app-pq-tool/archived_pqs.csv"
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
  "matters",
  "provision",
  "provisions",
  "usage",
  "dr",
  "mr",
  "mrs",
  "ms",
  "miss",
  "lord",
  "sir",
  "held",
  "extent",
  "comprehensive"
)

#The following list of tokens to be swapped out so that they are represented by one clear marker in the data,
# e.g. making the three words "young offender institute" into one token.
# The syntax is as follows: first the phrase or phrases to be removed from the original data, in regex format
# second, the string to replace it
# third, the string to use to mark this token in wordclouds and output.
JUSTICE_SWAP_TOKENS <- list(
 #put "re-offending" and "reoffending" together
 c("re off", "reoff", "reoff"),
 #put "post-morterm" and "postmortem" together
 c("post mortem", "postmortem", "postmortem"),
 #anti- always part of the word that follows it,
 #eg antisemitism not anti-semitism
 c("anti ", "anti", "anti"),
 #ditto for cross-examination
 c("cross exam", "crossexam", "crossexam"),
 #ditto for co-operation
 c("co oper", "cooper", "cooper"),
 #ditto for socio-economic
 c("socio eco", "socioeco", "socioeco"),
 #ditto for inter-library and inter-parliamentary
 c("inter ", "inter", "inter"),
 #ditto for non-profit, non-molestation, non-payroll, etc
 c("non ", "non", "non"),
 #ditto for pre-nuptial, pre-recorded, etc
 c("pre ", "pre", "pre"),
 #ditto for ex-offenders, etc, while not accidentally doing
 #it for Essex probation
 c(" ex ", " ex", " ex"),
 #correct one-off spelling mistakes in data
 c("rehabilitaiton", "rehabilitation", "rehabilitation"),
 c("organisaiton", "organisation", "organisation"),
 #issue with "directive" and "direction" being stemmed to the same thing.
 c("directive(s*)", "drctv", "directive"),
 c("direction(s*)", "drctn", "direction"),
 #issue with "internal" and "international" being stemmed to the same thing (!).
 c("internal", "intrnl", "internal"),
 #replace instances of the word "probation" with "probatn" to avoid the
 #issue with "probate" and "probation" being stemmed to the same thing.
 c("probation", "probatn", "probation"),
 #make sure Network Rail is seen as distinct from other mentions of network
 c("network rail", "networkrail", "Network Rail"),
 #make sure shared services is seen as distinct from other types of sharing
 c("shared service(s*)", "shrdsrvcs", "Shared Services"),
 #properly tokenize young offender's institutions, secure training centres, secure children's homes
 c("young offender(s*) institut(ion|e)(s*)", "yngoi", "Young Offenders Institute"),
 c("secure training centre(s*)", "sectc", "Secure Training Centre"),
 c("secure childrens home(s*)", "secch", "Secure Children's Home"),
 c("secure training college(s*)", "sectcol", "Secure Training College"),
 #make "pre-sentence" and "presented" not stemmed to the same thing
 c("presentence", "prsntc", "pre-sentence"),
 #make "secure" and "security" not stemmed to the same thing
 c("security", "scrty", "security"),
 #change "terrorist" and "terrorists" to "terrorism" so that they are stemmed to the same thing
 c("terrorist(s*)", "terrorism", "terrorism"),
 c("legal aid( *) sentencing and punishment of offenders act 2012", "laspo", "LASPO"),
 c("small claims", "smllclms", "small claims"),
 c("youth justice board", "yjb", "youth justice board"),
 c("holocaust memorial day", "holmemday", "Holocaust Memorial Day"),
 c("black history month", "blkhstmnt", "Black History Month"),
 c("national hate crime awareness week", "nathcaw", "National Hate Crime Awareness Week"),
 c("personal independence payment", "perinpay", "personal independence payment"),
 c("employment support allowance", "empsuppal", "employment support allowance"),
 c("disability living allowance", "dislivall", "disability living allowance"),
 c("jobseeker( *)s allowance", "jbsall", "jobseeker's allowance"),
 c("criminal cases review commission", "crimcrc", "Criminal Cases Review Commission"),
 c("independent monitoring board", "indmonbo", "independent monitoring board"),
 c("ernst and young", "erndy", "ernst and young")
)


source("packrat/init.R")
#### -- End Packrat Autoloader -- ####
