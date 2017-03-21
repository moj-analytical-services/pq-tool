source(file = 'global.R')

############### Server

function(input, output) {
  
  #the following is a similarity query function
  #simQuery <- reactive({
  #  qtext.stems <- tm_map(cleanCorpus(Corpus(VectorSource(input$question))),stemDocument)
  #  stemqText<-data.frame(text=unlist(sapply(qtext.stems, '[', 'content')), stringsAsFactors=F)
  #  SOTCorp <- tm_map(cleanCorpus(Corpus(VectorSource(d$Question_Text))),stemDocument)
  #  stemSOT <- data.frame(text=unlist(sapply(SOTCorp, '[', 'content')), stringsAsFactors=F)
  #  sapply(X=stemSOT$text,function(x){ 
  #    costring(stemqText$text,x, tvectors=data.frame(lsaOut$tk)) },USE.NAMES = F)
  #})
  sq  = SQ
  
  d$Sim_Score = sq ####### CHANGE LATER
  
  df = function(){
    dplyr::filter(d, (d$Date >= input$q_date_range[1] &
                        d$Date <= input$q_date_range[2] &
                        d$Date >= input$a_date_range[1] &
                        d$Date <= input$a_date_range[2] ))
  }

  output$dt <- renderDataTable({
    
    datatable(data = df()[,c('Date', 'Answer_Date', 'Cluster','Sim_Score')], #[c("Date", "Answer_Date","Cluster","Similarity Score")],
              colnames = c("Document #", "Question Date","Answer Date", "Cluster","Similarity Score"),
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
  output$plot <- renderPlot({
    plot(df()$Date,df()$Sim_Score,
         xlab = 'Question Date', ylab = 'Similarity Score')
      })
}
