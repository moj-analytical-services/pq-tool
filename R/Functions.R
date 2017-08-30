library(tm)
library(lsa)
library(cluster)
library(dplyr)
library(slam)
library(stringr)

#FUNCTIONS

#Data Creator functions

#a function to clean a corpus of text, making sure of the encoding, removing punctuation, putting it
#all in lower case, stripping white space, and removing stopwords.
#If you update this you also need to update queryVec in global.R to be in line with any changes, so
#that we are consistent in how we are treating search text and PQ text.

cleanPQ <- function(PQ){
  PQ <- PQ %>% iconv(to = "utf-8", sub = "") %>%
    #inelegant special cleaning steps 1
    #ensure High Down doesn't get confused with Legal Highs
    gsub("High Down", "Highdown", .) %>%
    gsub("-", " ", .) %>%
    gsub("<i>|</i>", "", .) %>%
    gsub("'", "", .) %>%
    gsub("[^A-Z a-z 0-9 //s]", " ", .) %>%
    #we now remove Justice with a capital J here before the transformation to lower
    #case, because this deals with the fact that a lot of questions start with "To ask
    #the Secretary of State for Justice" without losing potential information about eg
    #access to justice related questions
    removeWords(c("Justice")) %>%
    tolower() %>%
    #inelegant special cleaning steps 2
    #put "re-offending" and "reoffending" together
    gsub("re off", "reoff", .) %>%
    #put "post-morterm" and "postmortem" together
    sub("post mortem", "postmortem", .) %>%
    #anti- always part of the word that follows it,
    #eg antisemitism not anti-semitism
    gsub("anti ", "anti", .) %>%
    #ditto for cross-examination
    gsub("cross exam", "crossexam", .) %>%
    #ditto for co-operation
    gsub("co oper", "cooper", .) %>%
    #ditto for socio-economic
    gsub("socio eco", "socioeco", .) %>%
    #ditto for inter-library and inter-parliamentary
    gsub("inter ", "inter", .) %>%
    #ditto for non-profit, non-molestation, non-payroll, etc
    gsub("non ", "non", .) %>%
    #ditto for pre-nuptial, pre-recorded, etc
    gsub("pre ", "pre", .) %>%
    #ditto for ex-offenders, etc, while not accidentally doing
    #is for Essex probation
    gsub(" ex ", " ex", .) %>%
    #correct one-off spelling mistakes in data
    gsub("rehabilitaiton", "rehabilitation", .) %>%
    gsub("organisaiton", "organisation", .) %>%
    #issue with "directive" and "direction" being stemmed to the same thing.
    gsub("directive|directives", "drctv", .) %>%
    gsub("direction|directions", "drctn", .) %>%
    #issue with "internal" and "international" being stemmed to the same thing (!).
    gsub("internal", "intrnl", .) %>%
    #replace instances of the word "probation" with "probatn" to avoid the
    #issue with "probate" and "probation" being stemmed to the same thing.
    gsub("probation", "probatn", .) %>%
    #make sure Network Rail is seen as distinct from other mentions of network
    gsub("network rail", "networkrail", .) %>%
    removeWords(c(stopwords(), JUSTICE_STOP_WORDS)) %>%
    stripWhitespace()
}

cleanCorpus <- function(corp) {
  corp <- corp %>% tm_map(function(x) cleanPQ(x))
}

#a function useful in debugging so you can read a given document in a given corpus easily
writeDoc <- function(num, corpus){
  writeLines(as.character(corpus$content[[num]]))
}

#this will help us unstem words for summary
fromItoY <- function(word){
  return(gsub("i$", "y", word))
}

#a function to summarise the top terms of a given cluster or for a given MP
summarise <- function(type = "cluster", #type can be either cluster or MP
                      ID, #this is the cluster number if type == cluster, or the MPs name in "Surname, Forename" format if type == MP
                      matr, #the tdm as a matrix
                      data, #a hierarchy if type is cluster, or a list of answer MPs if type is MP
                      numTerms, #how many terms to return
                      listOfVectors, #the questions themselves
                      totalClusters = NULL #the number of clusters if type is cluster 
                      ){
  if (type == "cluster"){
    set <- cutree(data, totalClusters)
  } else if (type == "MP"){
    set <- data
  }
  relevantQs <- matr[, which(set == ID)]
  clusterDict <- cleanCorpus(Corpus(VectorSource(listOfVectors[which(set == ID)])))
  termsAndSums <- if (is.null(dim(relevantQs))){
                    relevantQs
                  } else rowSums(relevantQs)
  termsAndSumsN <- termsAndSums[order(termsAndSums, decreasing = T)[1:numTerms]]
  
  #we now complete the word stems, using the fromItoY function to deal with occasions
  #where the unstemming produces blanks
  partialCompletion <- stemCompletion(names(termsAndSumsN), clusterDict)
  toFix <- which(partialCompletion == "")
  fixed <- sapply(names(partialCompletion[toFix]), fromItoY)
  partialCompletion[toFix] <- fixed
  names(termsAndSumsN) <- partialCompletion # update names
  #replace "drctv" with "directive"
  names(termsAndSumsN) <- gsub("drctv", "directive", names(termsAndSumsN))
  #replace "drctn" with "direction"
  names(termsAndSumsN) <- gsub("drctn", "direction", names(termsAndSumsN))
  #replace "intrnl" with "internal"
  names(termsAndSumsN) <- gsub("intrnl", "internal", names(termsAndSumsN))
  #replace "probatn" with "probation"
  names(termsAndSumsN) <- gsub("probatn", "probation", names(termsAndSumsN))
  #replace "probabl" with "probability"
  names(termsAndSumsN) <- gsub("probabl", "probability", names(termsAndSumsN))
  #replace "networkrail" with "network rail"
  names(termsAndSumsN) <- gsub("networkrail", "network rail", names(termsAndSumsN))
  #replace "disabl" with "disability" (for clusters where the word disabled isn't present)
  names(termsAndSumsN) <- gsub("disabl", "disability", names(termsAndSumsN))
  
  termsAndSumsN
}

#This gets the length of a vector
normVec <- function(vec){
             return(sqrt(sum(vec^2)))
  }

#This normalises the lengths of a matrix to length 1
normalize <- function(mat){
  col.lengths <- sapply(1:ncol(mat), function(x) sqrt(sum(mat[, x]^2)))
  return(sweep(mat, 2, col.lengths, "/"))
}

#This cleans up the names of those asking the questions
nameCleaner <- function(name){
  #first remove surplus white space (I'm looking at you, "Richard  Arkless")
  name <- stripWhitespace(name)
  #first take out Mr/Mrs/Ms
  name <- name %>% gsub("Mr |Mrs |Ms |Miss ","",.)
  #we aim to get everyone's name in the format
  #"surname, {title} firstname {initials}"
  #get the first occurrence of a space
  firstSpace <- regexpr(" ", name) %>% as.vector()
  #use this to get what is usually first name
  firstname <- substr(name, 1, firstSpace - 1)
  #first deal with special cases from the Lords'
  if (firstname == "Lord"|
      firstname == "Lady"|
      firstname == "The"|
      firstname == "Baroness"|
      firstname == "Baron"|
      firstname == "Viscount"){
    #just keep them as Lord/Lady Blah of Blahchester
  }
  #now special cases where someone has a middle initial,
  #or a title like Sir or Dr that we don't want to chop
  else if(length(unlist(gregexpr(" ",name))) > 1){
    #we find the last space, and call everything before it the
    #first name, and every after it the surname
    lastSpace <- unlist(gregexpr(" ", name))[length(unlist(gregexpr(" ",name)))]
    firstname <- substr(name, 1, lastSpace - 1)
    surname <- substr(name, lastSpace + 1, nchar(name))
    name <- paste(surname, firstname, sep = ", ")
  }
  else {
    surname <- substr(name, firstSpace + 1, nchar(name))
    name <- paste(surname, firstname, sep = ", ")
  }
  #now a series of horrible inelegant special cases
  #covering issues like MPs being in the list twice
  #or whatever
  if (name == "Amess, David"){
    name <- "Amess, Sir David"
  }
  else if (name == "Bayley, Hugh"){
    name <- "Bayley, Sir Hugh"
  }
  else if (name == "Blackman-Woods, Roberta"){
    name <- "Blackman-Woods, Dr Roberta"
  }
  else if (name == "Bois, Nick de"){
    name <- "de Bois, Nick"
  }
  else if (name == "Burns, Simon"){
    name <- "Burns, Sir Simon"
  }
  else if (name == "Crausby, David"){
    name <- "Crausby, Sir David"
  }
  else if (name == "Jones, Graham P"){
    name <- "Jones, Graham"
  }
  else if (name == "Lucas, Ian C."){
    name <- "Lucas, Ian"
  }
  else if (name == "Morris, Grahame M."){
    name <- "Morris, Grahame"
  }
  else if (name == "Piero, Gloria De"){
    name <- "De Piero, Gloria"
  }
  else if (name == "Poulter, Dr"){
    name <- "Poulter, Daniel"
  }
  else if (name == "Roberts, Liz Saville"){
    name <- "Saville Roberts, Liz"
  }
  else if (name == "Soames, Nicholas"){
    name <- "Soames, Sir Nicholas"
  }
  name
}


#Functions for shinyapp
#note shinyapp also uses cleanPQ function from above

queryVec <- function(query, vocab){
  query <- query %>%
    cleanPQ() %>%
    stemDocument() %>%
    strsplit(" ") %>%
    unlist() %>%
    (function(vec){
      return(vec[sapply(vec, function(x) x %in% vocab)])
    })
  return(which(vocab %in% query))
}

familyName <- function(name){
  commaPosn <- regexpr(",", name) %>% as.vector()
  substr(name, 1, commaPosn-1)
}

firstName <- function(name){
  commaPosn <- regexpr(",", name) %>% as.vector()
  substr(name, commaPosn+2, nchar(name))
}

urlName <- function(name){
  #first take out peers
  if (
    !grepl(
      ",",
      name
    )){
    urlName <- name %>%
      gsub("The ", "", .) %>%
      gsub("Lord Bishop", "Bishop", .) %>%
      gsub(" ", "_", .)
  } #now deal with MPs
  else {
    urlName <- paste0(firstName(name), "_", familyName(name), sep="") %>%
      gsub("Dr |Sir ", "", .) %>%
      gsub("de ", "de_", .) %>%
      gsub("De ", "De_", .) %>%
      gsub(" ", "-", .)
  }
  #special cleaning
  if (name == "Ashworth, Jonathan"){
    urlName <- "Jon_Ashworth"
  }
  else if (name == "Baker, Steve"){
    urlName <- "Steven_Baker"
  }
  else if (name == "Brown, Nicholas"){
    urlName <- "Nick_Brown"
  }
  else if (familyName(name) == "Coffey"){
    urlName <- "Therese_Coffey"
  }
  else if (name == "Dakin, Nic"){
    urlName <- "Nicholas_Dakin"
  }
  else if (name == "Davies, David T.C."){
    urlName <- "David_Davies/Monmouth"
  }
  else if (name == "Docherty-Hughes, Martin"){
    urlName <- "Martin_Docherty"
  }
  else if (name == "Donaldson, Stuart Blair"){
    urlName <- "Stuart_Donaldson"
  }
  else if (name == "Flello, Robert"){
    urlName <- "Rob_Flello"
  }
  else if (name == "Johnson, Diana"){
    urlName <- "11647" #using her number seems easiest here
  }
  else if (name == "Jones, Susan Elan"){
    urlName <- "Susan_Elan_Jones"
  }
  else if (name == "Lady Hermon"){
    urlName <- "Sylvia_Hermon"
  }
  else if (name == "Leslie, Chris"){
    urlName <- "10354" #using his number seems easiest here
  }
  else if (name == "Matheson, Christian"){
    urlName <- "Chris_Matheson"
  }
  else if (name == "McDonnell, John"){
    urlName <- "John_Martin_McDonnell"
  }
  else if (name == "Pound, Stephen"){
    urlName <- "Steve_Pound"
  }
  else if (name == "Shah, Naseem"){
    urlName <- "Naz_Shah"
  }
  else if (name == "Slaughter, Andy"){
    urlName <- "Andrew_Slaughter"
  }
  urlName
}


