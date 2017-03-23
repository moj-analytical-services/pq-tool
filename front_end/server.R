source(file = 'global.R')

############### Server

function(input, output) {
  
  #the following is a similarity query function
  simQuery <- reactive({
    qtext.stems <- tm_map(cleanCorpus(Corpus(VectorSource(input$question))),stemDocument)
    stemqText<-data.frame(text=unlist(sapply(qtext.stems, '[', 'content')), stringsAsFactors=F)
    SOTCorp <- tm_map(cleanCorpus(Corpus(VectorSource(d$Question_Text))),stemDocument)
    stemSOT <- data.frame(text=unlist(sapply(SOTCorp, '[', 'content')), stringsAsFactors=F)
    sapply(X=stemSOT$text,function(x){ 
      costring(stemqText$text,x, tvectors=data.frame(lsaOut$tk)) },USE.NAMES = F)
  })
  
  dat = reactive({
    d$Sim_Score = simQuery()
    return(d)
  })
  
  #df = function(){
  #  dplyr::filter(dat, (dat()$Date >= input$q_date_range[1] &
  #                      dat()$Date <= input$q_date_range[2] &
  #                      dat()$Date >= input$a_date_range[1] &
  #                      dat()$Date <= input$a_date_range[2] ))
  #}

  output$x1 <- renderDataTable({
#### Progress Bar goes here    
    datatable(data = dat()[,c('Date', 'Answer_Date', 'Cluster','Sim_Score')], 
              colnames = c("Document #", "Question Date","Answer Date", "Cluster","Similarity Score"),
              class = 'display',
              width = 25,
              caption = "Questions ranked by similarity to search text:",
              options = list(deferRender = TRUE,
                             scrollY = 400,
                             scroller = TRUE,
                             searching = FALSE,
                             paging = FALSE)
    )
  })
  output$please_work <- renderPrint(names(dat()))
  output$please_please_work <- renderPrint(dat())
  output$please_please_please_work <- renderPrint(class(simQuery()))
  
  output$x2 <- renderPlot({
    s = input$x1_rows_selected
    par(mar=c(4,4,1,.1))
    p = ggplot(data = dat(), aes(x=Date, y=Sim_Score, color=Cluster))+geom_point(shape = 1)
    p + labs(title = "Questions arranged by date and similarity to search text",
             x = "Question Date",
             y = "Similarity Score") + 
      theme(plot.title = element_text(size=17, face = "bold")) + 
      scale_fill_gradient2("Cluster")
    #if (length(s)) points(Plot[s, , drop = FALSE], pch = 19, cex = 10)
      })
  
  dfClus = function(){
    df = 
    dplyr::filter(d, (d$Cluster == input$x3))
  }
  
  output$x3 <- renderPlot({
    p = ggplot(data=NULL, aes(x=dfClus()$Date, y=))+geom_bar(color= 'red',fill = 'red', width = .5)
    p + xlim(min(d$Date)-1,max(d$Date)+1) +
      labs(title = 'When the questions were asked:',
           x = "Question Date",
           y = "Count") +
      theme(plot.title = element_text(size=17, face = "bold"))
  })
  
  output$x4 <- renderDataTable({
    datatable(data = dfClus()[,c('Question_ID','Question_Text')],
              caption = "Documents contained within the cluster:",
              options = list(scroller = TRUE,
                             searching = FALSE,
                             paging = FALSE))
  }) 
  
  output$x5 <- renderPlot({
    p = ggplot(data = d, aes(x = date, y = date)+geom_line())
    p
  })
  
  output$x6 <- renderDataTable({
    datatable(data=d[,c('Question_ID','Question_Text','Answer_Text','Question_MP','MP_Constituency','Answer_MP',
                        'Date', 'Answer_Date','Cluster')],
              colnames = c("Document #", 'Question ID','Question Text','Answer Text','Question MP','MP Constituency',
                           'Answer MP', "Question Date","Answer Date", "Cluster"),
              filter = 'top',
              options = list(scroller = TRUE,
                             paging = FALSE
                             #autoWidth = TRUE,
                             #columnDefs = list(list(width = '30%', targets = list(2,3)))
                             ))
  })
   
  
   
   
}
