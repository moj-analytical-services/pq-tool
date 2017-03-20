library(tm)
library(lsa)
library(cluster)
library(LSAfun)
library(shiny)
library(DT)

#SCRIPT
#This loads stuff created by the DataCreator.R script

load(file = "lsaOut.rda")
load(file = "tdm.rda")
load(file = "klusters.rda")

# Import similarity score function simQuery()
source("/Users/admin/Documents/PQtools/Front End/lsaPreamble.R")

# Shiny App

# Define R_date date type - to read in Long Date format in csv
setAs("character", "R_date", function(from) as.Date(from, "%d %B %Y"))
setClass('R_date')
myColClasses = c("Date" = "R_date", "Answer_Date" = "R_date")

rawData = read.csv('/Users/admin/Documents/PQtools/Data/MoJallPQsforTableau.csv',colClasses = myColClasses)
d = data.frame(rawData )

############### Server

server <- function(input, output) {
  
  stopwordList <- c(
    stopwords(),'a','b','c','d','i','ii','iii','iv',
    'secretary','state','ministry','majesty',
    'government','many','ask','whether',
    'assessment','further','pursuant','justice',
    'minister','steps','department','question'
  )
  
  cleanCorpus <- function(corp) {
    corp <-tm_map(corp, content_transformer(function(x) iconv(x, to='UTF-8-MAC', sub='byte')))
    toSpace <- content_transformer(function(x, pattern) { return (gsub(pattern, ' ', x))})
    corp <- tm_map(corp, toSpace, '-')
    corp <- tm_map(corp, toSpace, '’')
    corp <- tm_map(corp, toSpace, '‘')
    corp <- tm_map(corp, toSpace, '•')
    corp <- tm_map(corp, toSpace, '”')
    corp <- tm_map(corp, toSpace, '“')
    corp <- tm_map(corp,content_transformer(tolower))
    corp <- tm_map(corp,removePunctuation)
    corp <- tm_map(corp,stripWhitespace)
    corp <- tm_map(corp, function(x) removeWords(x,stopwordList))
  }
  
  #the following is a similarity query function
  simQuery <- reactive({
    qtext.stems <- tm_map(cleanCorpus(Corpus(VectorSource(input$question))),stemDocument)
    stemqText<-data.frame(text=unlist(sapply(qtext.stems, '[', 'content')), stringsAsFactors=F)
    SOTCorp <- tm_map(cleanCorpus(Corpus(VectorSource(d$Question_Text))),stemDocument)
    stemSOT <- data.frame(text=unlist(sapply(SOTCorp, '[', 'content')), stringsAsFactors=F)
    start.time <- Sys.time()
    print(start.time)
    sapply(X=stemSOT$text,function(x){ 
      print(x)
      costring(stemqText$text,x, tvectors=data.frame(lsaOut$tk)) },USE.NAMES = F)
    end.time <- Sys.time()
    print(end.time)
    time.taken <- end.time - start.time
    print(time.taken)
  })
  
  SimilarityScore = reactive({
    data.frame(simQuery())
  })
  
  add_to_df = function(){
    d$Sim_Score = NA
    nRows = nrow(d)
    d()$Sim_Score = simQuery()
    return(d) 
  }
  
  Update_df <- reactive({
    add_to_df() %>%
      filter(
        d$Date >= input$q_date_range[1] &
          d$Date <= input$q_date_range[2] &
          d$Date >= input$a_date_range[1] &
          d$Date <= input$a_date_range[2] )%>%
      as.data.frame()
  })
  
  output$dt <- renderDataTable({
    
    datatable(data = add_to_df(), #[,c("Date", "Answer_Date","Cluster")],
              #colnames = c("Document #", "Question Date","Answer Date", "Cluster"), #,"Similarity Score"),
              class = 'display',
              width = 25,
              #filter = 'top',
              options = list(deferRender = TRUE,
                             scrollY = 400,
                             scroller = TRUE,
                             searching = FALSE,
                             paging = FALSE)
    )
  })
}
