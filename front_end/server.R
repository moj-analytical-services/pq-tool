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
  sq  = reactive({
    SQ
    })
  
  add_to_df = function(){
    d$Sim_Score = sq()  ####### CHANGE LATER
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
    
    datatable(data = add_to_df()[,c('Date', 'Answer_Date', 'Cluster', 'Sim_Score')], #[c("Date", "Answer_Date","Cluster","Similarity Score")],
              #colnames = c("Document #", "Question Date","Answer Date", "Cluster","Similarity Score"),
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
