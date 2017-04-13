source(file = 'global.R')

############### Server

function(input, output) {
### Similarity Pane

  #returnNearestMatches(input$question)
  returnNearestMatches<-reactive({
      space = search.space
      foundWords<-which(space$i %in% queryVec(input$question))
      Document<-space$j[foundWords]
      vees <-space$v[foundWords]
      JayVees <- data.table(Document = Document, vees = vees)
      outGroup <- JayVees[, .("Similarity_score" = sum(vees)), by = Document ][order(-Similarity_score)]
      table_output = outGroup[1:30]
      #e = d[d["Document_Number"] %in% table_output["Document"]]
      data = merge.data.frame(table_output, d, by.x = "Document", by.y = "Document_Number")
      return(data)
  })
  
  df = function(){
    subset(returnNearestMatches(), returnNearestMatches()$Date >= input$q_date_range[1] &
             returnNearestMatches()$Date <= input$q_date_range[2])# &
            # returnNearestMatches()$Answer_Date >= input$a_date_range[1] &
            # returnNearestMatches()$Answer_Date <= input$a_date_range[2] )
    }
  
  output$x1 <- renderDataTable({
#### Progress Bar goes here    
    datatable(data = df()[,c('Document','Date', 'Answer_Date', 'Cluster','Similarity_score')], 
              colnames = c("Rank","Document #", "Question Date","Answer Date", "Cluster","Similarity Score"),
              class = 'display',
              width = 25,
              caption = "Questions ranked by similarity to search text:",
              options = list(deferRender = TRUE,
                             scrollY = 400,
                             scroller = TRUE,
                             searching = FALSE,
                             paging = FALSE, #,deferRender = TRUE,
                             server = FALSE
                             )
    )
  })
  
  output$x2 <- renderPlotly({
    gg=plot_ly(x = df()$Date, y = df()$Similarity_score,
            type = 'scatter', mode = 'markers') %>%
        add_trace(x = input$x1_rows_selected["Date"], y = input$x1_rows_selected["Similarity_score"], type = "scatter", mode = 'markers', name = "Density") 
           
     #text = ~paste("Q:", df()$Question_Text,
            #              "<br> Date:", df()$Date,
            #              "<br> Cluster:", df()$Cluster,
            #              "<br> Similarity Score:", df()$Score)) 
    
    #s = input$x1_rows_selected
    #par(mar=c(4,4,1,.1))
    #plot_ly(dat())
  #  if (length(s)) points(dat()[s, , drop = FALSE], pch = 19, cex = 2)
    #p = ggplot(data = dat(), aes(x=Date, y=Score, color=Cluster))+geom_point(shape = 1)
    #p = p + labs(title = "Questions arranged by date and similarity to search text",
    #         x = "Question Date",
    #         y = "Similarity Score") + 
    #  theme(plot.title = element_text(size=10, face = "bold")) + 
    #  scale_fill_gradient2("Cluster")
    #p
  })
  
  observeEvent(input$x1_rows_selected, {
    renderDataTable({
      data = input$x1_rows_selected
    })
    insertUI(
      selector = '#add',
      where = "beforeEnd",
      ui = dataTableOutput(
        "x1_rows_selected"
      )
      )
  })
  
### Cluster Pane  
  
  #input$x3 = input$x1_rows_selected
  # how to get datatable on 1st tab to link in?
  
  dfClus = function(){
    df = subset(d, (d$Cluster == input$x3))
  }
  
  wordcloud_df = function(){
    df = dplyr::filter(cluster_data, (cluster_data$cluster == input$x3))
  }
  
  output$wordcloud <- renderPlot(
    wordcloud(words = wordcloud_df()$word, freq = wordcloud_df()$freq,
              scale = c(1,4), random.order = TRUE, ordered.colors = TRUE)
  )
  
  output$x3 <- renderPlot({
    p = ggplot(data=NULL, aes(x = dfClus()$Date, y = )) +
      geom_bar(color= 'red',fill = 'red', width = .5)
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
  
### Q&A Analysis Pane  
  output$q_analysis_ui <- renderUI({
    switch(input$q_analysis, 
           "Lords" = selectInput(inputId = "person_choice",
                                 label = "Choose a Member:",
                                 choices = sort(unique(d$Question_MP[grepl("HL", d$Question_ID) == TRUE]))
                                 ),
           "Commons" = selectInput(inputId = "person_choice", 
                                   label = "Choose an MP:",
                                   choices = sort(unique(d$Question_MP[grepl("HL", d$Question_ID) == FALSE]))
                                   )
    )
  })
  
  dfMP = function(){
    df = subset(d, (d$Question_MP == input$person_choice))
  }
  
  output$q_analysis_plot <- renderPlot({
    p = ggplot(data=NULL, aes(x = dfMP()$Date, y = )) +
      geom_bar(color= 'red',fill = 'red', width = .5)
    p + xlim(min(d$Date)-1,max(d$Date)+1) +
      labs(title = 'When the questions were asked:',
           x = "Question Date",
           y = "Count") +
      theme(plot.title = element_text(size=17, face = "bold"))
  })
  
  output$q_analysis_table <- renderDataTable({
    datatable(dfMP()[,c('Date','Question_ID','Question_Text','Cluster')]
              #options = c(
              #  searching = FALSE#,
                #colnames = c("Question Date","Question ID", "Question Text", "Cluster")
              #)
    )
  })

### Data Pane 
    
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
