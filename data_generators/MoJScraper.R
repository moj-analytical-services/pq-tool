#A script to scrape the written questions that the MoJ has had since 4th June 2014 until the latest date.
#All data is scraped from the parliament website, http://www.parliament.uk.
#(4th June 2014 is the date which the parliament website goes easily back to)

#The data this scrapes is as follows:
#Question ID: the parliament website identifier for a question
#Question Text: self-explanatory
#Answer Text: where it exists
#Question MP: (or Lord/Lady where it's a House of Lords question)
#MP constituency: where the question is asked in the Commons, the constituency of the MP
#Answer MP: the minister answering the question
#Date: the date the question was asked
#Answer date: the date the question was originally answered
#Corrected date: the date the answer was corrected, if it was

#To use this, you'll need to use your web browser to go to the parliament website and find the page that gives
#the written questions and answers, which at the time of writing this is
#http://www.parliament.uk/business/publications/written-questions-answers-statements/written-questions-answers/
#Then you'll need to make changes so that it searches Ministry of Justice questions, and amend the date range
#appropriately. A good tip is to also change it so it's showing 100 questions per page.
#Then click 'go', and then copy and paste the resulting URL into the parameter below called 'link'.

#You need to also write where you want the results saved. 

#Once you've done this you should be able to now just run everything below here
#and it will spit out the results into the file you've specified above.

#I've had to clear up some rogue results semi-manually: for some reason (I think because of web connections)
#it occasionally throws up NAs for all of the data for some parliamentary questions.
#I'm afraid I've just cleaned up those by scraping those questions using the Qscrape function and inserting
#the answers in the right place.


library(rvest)
library(tm)

#### PARAMETERS ####

#paste the url for your search set of questions here within the quotation marks
link = "http://www.parliament.uk/business/publications/written-questions-answers-statements/written-questions-answers/?answered-from=2014-06-04&answered-to=2017-05-05&dept=54&house=commons%2clords&max=1000&page=1&questiontype=AllQuestions&use-dates=True"

#write the file name - it will save to whatever folder R is standardly writing out to
saveFile = 'MoJPQsNew.csv'


#You should be able to now just run everything below here and it will spit out the results into
#the file you've specified above.

#### FUNCTIONS ####

#function to scrape the information we want for the ith question on a given page
Qscrape <- function(i,htmlSession){
  #this qTag business seems like a long way round, but it's to avoid running into trouble when
  #question IDs have the same string of digits as other links on the page, at which point a
  #simple 'follow_link("questionID")' approach just follows the first link containing the string
  #of digits in question, with often the wrong result. Whereas this way, though fiddly, gets results.
  qTag <- 2*i-1
  qTag <- if(qTag<10){paste("0",as.String(qTag),sep="")}else{as.String(qTag)}
  
  qLink<-paste("#ctl00_ctl00_FormContent_SiteSpecificPlaceholder_PageContent_ctrlQnAList_rptQuestions_ctl",qTag,"_ctrlQuestionItem_hypQuestionUIN",sep="")
  QSesh <- htmlSession %>% follow_link(css = qLink)
  Qhtml <- read_html(QSesh)
  
  correctedDate <- "N/A"
  
  question <-  Qhtml %>% html_nodes(".qna-result-question-text") %>% html_text()
  if(length(question)==0){question <- "N/A"}
  
  date <- Qhtml %>% html_nodes(".qna-result-question-date span") %>% html_text()
  if(length(date)==0){date <- "N/A"}
  
  answerDate <- Qhtml %>% html_nodes(".qna-result-answer-date") %>% html_text()
  if(length(answerDate)==0){answerDate <- "N/A"}
  if(length(answerDate)>1){ #if the answer takes up several paragraphs we want to squeeze it all into one entry
    answerDate <- Qhtml %>% html_nodes("#ctl00_ctl00_FormContent_SiteSpecificPlaceholder_PageContent_ctrlAnswerItem_divAnswer .qna-result-answer-date") %>% html_text()
    correctedDate <- Qhtml %>% html_nodes("#ctl00_ctl00_FormContent_SiteSpecificPlaceholder_PageContent_ctrlAnswerItemMinisterialCorrection_divAnswer .qna-result-answer-date") %>% html_text()}
  
  questionID <- Qhtml %>% html_nodes("#ctl00_ctl00_FormContent_SiteSpecificPlaceholder_PageContent_ctrlQuestionItem_hypQuestionUIN") %>% html_text()
  if(length(questionID)==0){questionID <- "N/A"}
  
  answer <- Qhtml %>% html_nodes("#ctl00_ctl00_FormContent_SiteSpecificPlaceholder_PageContent_ctrlAnswerItemMinisterialCorrection_divAnswer p") %>% html_text()
  if(length(answer)==0){ #sometimes the answers are under a different CSS tag
    answer <- Qhtml %>% html_nodes(".qna-result-answer-content") %>% html_text()}
  if(length(answer)==0){ #sometimes the answers are under a different CSS tag
    answer <- Qhtml %>% html_nodes("#ctl00_ctl00_FormContent_SiteSpecificPlaceholder_PageContent_ctrlAnswerItem_divAnswer p") %>% html_text()}
  if(length(answer)==0){
    answer <- "N/A"}
  if(length(answer)>1){ #if the answer takes up several paragraphs we want to squeeze it all into one entry
    answer <- paste(answer,collapse = "; ")}
  
  QMP <- Qhtml %>% html_nodes("#ctl00_ctl00_FormContent_SiteSpecificPlaceholder_PageContent_ctrlQuestionItem_ctlMemberHypLink") %>% html_text()
  if(length(QMP)==0){QMP <- "N/A"}
  
  Qconst <- Qhtml %>% html_nodes("#divConstituency") %>% html_text()
  if(length(Qconst)==0){Qconst <- "N/A"}
  
  AMP <- Qhtml %>% html_nodes("#ctl00_ctl00_FormContent_SiteSpecificPlaceholder_PageContent_ctrlAnswerItem_ctlMemberHypLink") %>% html_text()
  if(length(AMP)==0){AMP <- "N/A"}
  
  return(list(question = question, date = date, answerDate = answerDate, correctedDate = correctedDate, questionID = questionID, answer = answer, QMP = QMP, Qconst = Qconst, AMP = AMP))
}


#### CODE ####

#this defines your html session
MoJPQSesh <- html_session(link)

#total number of questions in our selection
totalQs <- read_html(MoJPQSesh) %>% html_nodes(".record-count-highlight") %>% html_text()
totalQs <- as.numeric(totalQs[1])

#Now some empty holders for the eventual results
questionsVec <- rep("unused",totalQs)
datesVec <- rep("unused",totalQs)
answerDatesVec <- rep("unused",totalQs)
correctedDatesVec <- rep("unused",totalQs)
questionIDsVec <- rep("unused",totalQs)
answersVec <- rep("unused",totalQs)
QMPsVec <- rep("unused",totalQs)
QconstsVec <- rep("unused",totalQs)
AMPsVec <- rep("unused",totalQs)

#A placeholder for whether or not we've finished the scrape, and an index for what question we're on
finished <-0
j <- 1

#Now the bit that does the actual scraping:
#we loop through each page and add the scrapings to each result holder
#once we hit a page that lacks a 'Next' link we assume that we've finished
while(finished == 0){
  #get the number of questions on the page by counting them
  qNums <- MoJPQSesh %>% html_nodes(".qna-result-question-uin a") %>% html_text()
  for(i in 1:length(qNums)){
    #for each question, run the Question Scraper function
    Qresults <- Qscrape(i,MoJPQSesh)
    #then add the results to the appropriate slot in our results vectors
    questionsVec[j] <- Qresults$question
    datesVec[j] <- Qresults$date
    answerDatesVec[j] <- Qresults$answerDate
    correctedDatesVec[j] <- Qresults$correctedDate
    questionIDsVec[j] <- Qresults$questionID
    answersVec[j] <- Qresults$answer
    QMPsVec[j] <- Qresults$QMP
    QconstsVec[j] <- Qresults$Qconst
    AMPsVec[j] <- Qresults$AMP
    #now click the index on to the next question and loop round again
    j <- j+1
  }
  #define the link we're going to next
  nextLink <- read_html(MoJPQSesh) %>% html_nodes("a:nth-child(7)") %>% html_attr("href")
  #if the link exists, follow it and go round the loop again, otherwise we're done
  if(length(nextLink)!=0){
    MoJPQSesh <- MoJPQSesh %>% follow_link("Next")
  } else {finished = 1}
}


#I've had to clear up some rogue "N/A"s and "unused"s semi-manually, by scraping those question and 
#inserting the answers in the right place. I think it just throws NAs sometimes when the web connection
#fails or whatever. The methodology goes as follows: find the questions that are NAs. Then we can
#find what page number should be in the URL for them, and how far down that page they are. So
#for example the 2352nd question is on page 3 (we have 1000 qs per page in the URL framework we're)
#using, and it's the 352nd question on that page. So we can generate the URL and then grab that
#specific question, take its data, and overwrite it in the relevant data frames. Obviously this
#is frighteningly inelegant.

#find the NA questions (assuming they are uniquely those which have "N/A")
NAs <- which(questionsVec=="N/A")
#find the question numbers within a page
NAqNumVec <- NAs%%1000
#find the page numbers
NApageNumVec <- NAs%/%1000 + 1

for(i in seq_along(NAs)){
  #for each NA question
  #write the URL
  NAlink = paste0("http://www.parliament.uk/business/publications/written-questions-answers-statements/written-questions-answers/?answered-from=2014-06-04&answered-to=2017-05-05&dept=54&house=commons%2clords&max=1000&page=",
                    NApageNumVec[i],"&questiontype=AllQuestions&use-dates=True",sep="")
  
  #start an html session
  NAsesh = html_session(NAlink)
  j <- NAs[i]
  #scrape the NA question
  NAQresults <- Qscrape(NAqNumVec[i],NAsesh)
  #overwrite
  questionsVec[j] <- NAQresults$question
  datesVec[j] <- NAQresults$date
  answerDatesVec[j] <- NAQresults$answerDate
  correctedDatesVec[j] <- NAQresults$correctedDate
  questionIDsVec[j] <- NAQresults$questionID
  answersVec[j] <- NAQresults$answer
  QMPsVec[j] <- NAQresults$QMP
  QconstsVec[j] <- NAQresults$Qconst
  AMPsVec[j] <- NAQresults$AMP
}

#check that we've now got everything
length(which(questionsVec=="N/A"))

#find the NA questions (assuming they are uniquely those which have "N/A")
UUs <- which(questionsVec=="unused")
#find the question numbers within a page
UUqNumVec <- UUs%%1000
#find the page numbers
UUpageNumVec <- UUs%/%1000 + 1

for(i in seq_along(UUs)){
  #for each NA question
  #write the URL
  UUlink = paste0("http://www.parliament.uk/business/publications/written-questions-answers-statements/written-questions-answers/?answered-from=2014-06-04&answered-to=2017-05-05&dept=54&house=commons%2clords&max=1000&page=",
                  UUpageNumVec[i],"&questiontype=AllQuestions&use-dates=True",sep="")
  
  #start an html session
  UUsesh = html_session(UUlink)
  j <- UUs[i]
  #scrape the NA question
  UUQresults <- Qscrape(UUqNumVec[i],UUsesh)
  #overwrite
  questionsVec[j] <- UUQresults$question
  datesVec[j] <- UUQresults$date
  answerDatesVec[j] <- UUQresults$answerDate
  correctedDatesVec[j] <- UUQresults$correctedDate
  questionIDsVec[j] <- UUQresults$questionID
  answersVec[j] <- UUQresults$answer
  QMPsVec[j] <- UUQresults$QMP
  QconstsVec[j] <- UUQresults$Qconst
  AMPsVec[j] <- UUQresults$AMP
}

#check we've got everything
length(which(questionsVec=="unused"))

#### OUTPUT RESULTS ####

#make a data frame to hold all of our result vectors, cleaning where appropriate
savedf <- data.frame(
  Question_ID = questionIDsVec,
  Question_Text = stripWhitespace(gsub(","," ",questionsVec)),
  Answer_Text = stripWhitespace(gsub(","," ",answersVec)),
  Question_MP = stripWhitespace(QMPsVec),
  MP_Constituency = stripWhitespace(gsub('\\(|\\)'," ",QconstsVec)),
  Answer_MP = stripWhitespace(AMPsVec),
  Date = datesVec,
  Answer_Date = stripWhitespace(gsub('Answered on:'," ",answerDatesVec)),
  Corrected_Date = stripWhitespace(gsub('Corrected on:'," ",correctedDatesVec)),
  stringsAsFactors = FALSE)
#save data frame
write.csv(savedf,saveFile)

#### END ####