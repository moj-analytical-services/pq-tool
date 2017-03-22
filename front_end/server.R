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

  output$x1 <- renderDataTable({
#### Progress Bar goes here    
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
  
  
  
  output$x2 <- renderPlot({
    #s = input$x1_rows_selected
    #ar(mar=c(4,4,1,.1))
    plot(df()$Date,df()$Sim_Score,
         xlab = 'Question Date', ylab = 'Similarity Score')
    #if (length(s)) points(Plot[s, , drop = FALSE], pch = 19, cex = 10)
      })
  
  dfClus = function(){
    dplyr::filter(d, (d$Cluster == input$x3))
  }
  
  output$x3 <- renderDataTable({
    datatable(data = dfClus()[,c('Question_ID','Question_Text')],
              options = list(scroller = TRUE,
                             searching = FALSE,
                             paging = FALSE))
  }) 
   output$x4 <- renderPlot({
     p = ggplot(data=dfClus, aes(x=dfClus()$Date, y=dfClus()$Date))+geom_bar(stat = 'identity')
     p
   })
   output$x5 <- renderDataTable({
     datatable(data=d,
               filter = 'top',
               options = list(scroller = TRUE,
                              paging = FALSE))
   })
   
  output$x8 <- renderPlot({
    p = ggplot(data = d, aes(x = d$date, y = count(d$date == x))+geom_line())
    p
  })
   
   
}
