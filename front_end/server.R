source(file = 'global.R')

############### Server

function(input, output) {
### Similarity Pane

  cluster_scorer <- reactive({
    qtext.stems <- tm_map(cleanCorpus(Corpus(VectorSource(input$question))),stemDocument)
    stemqText<-data.frame(text=unlist(sapply(qtext.stems, '[', 'content')), stringsAsFactors=F)
    SOTCorp <- tm_map(cleanCorpus(Corpus(VectorSource(merged_clusters$Question_Text))),stemDocument)
    stemSOT <- data.frame(text=unlist(sapply(SOTCorp, '[', 'content')), stringsAsFactors=F)
    sapply(X=stemSOT$text,function(x){ 
      print(Sys.time())
      costring(stemqText$text,x, tvectors=data.frame(lsaOut$tk))
    },USE.NAMES = F)
  })

  merge_clusters = reactive({
    print("mc")
    mc = merged_clusters
    print("mc score")
    mc$Cluster_Score = cluster_scorer()
    print(mc)
    print(Sys.time())
    print(mc)
    print("merge_clusters finished")
    return (mc)
  })
  
  SOT = reactive({
    ordered_merged_clusters = arrange(merge_clusters(), desc(Cluster_Score))
    print("omc")
    top_ordered_merged_clusters = head(ordered_merged_clusters, n=10)
    print('tomc')
    set_of_texts = d[top_ordered_merged_clusters$Cluster %in% d$Cluster]
    set_of_texts$Score = NA
    print("sot")
    return(set_of_texts)
  })
  
  #filter_ordered_merge_clusters = reactive({
  #  fomc = head(ordered_merge_clusters(), n=10)
  #  print('fomc')
  #  return(fomc)
  #})
  
  #SOT = reactive({
  #  sot = d[filter_ordered_merge_clusters()$Cluster %in% d$Cluster]
  #  print("sot")
  #  return(sot)
  #})
  
  #the following is a similarity query function
  simQuery <- reactive({
    qtext.stems <- tm_map(cleanCorpus(Corpus(VectorSource(input$question))),stemDocument)
    stemqText<-data.frame(text=unlist(sapply(qtext.stems, '[', 'content')), stringsAsFactors=F)
    SOTCorp <- tm_map(cleanCorpus(Corpus(VectorSource(SOT()$Question_Text))),stemDocument)
    stemSOT <- data.frame(text=unlist(sapply(SOTCorp, '[', 'content')), stringsAsFactors=F)
    sapply(X=stemSOT$text,function(x){ 
      costring(stemqText$text,x, tvectors=data.frame(lsaOut$tk))
      },USE.NAMES = F)
    })
  
  dat <- reactive({
    ordered_merged_clusters = arrange(merge_clusters(), desc(Cluster_Score))
    #print("omc")
    top_ordered_merged_clusters = head(ordered_merged_clusters, n=10)
    #print('tomc')
    set_of_texts = d[top_ordered_merged_clusters$Cluster %in% d$Cluster]
    set_of_texts$Score = simQuery()
    #print("dat assignment finished")
    return(set_of_texts)
  })
  
  df = function(){
    subset(dat(), dat()$Date >= input$q_date_range[1] &
             dat()$Date <= input$q_date_range[2] &
             dat()$Date >= input$a_date_range[1] &
             dat()$Date <= input$a_date_range[2] )
    }
  
  output$x1 <- renderDataTable({
#### Progress Bar goes here    
    datatable(data = df()[,c('Date', 'Answer_Date', 'Cluster','Score')], 
              colnames = c("Document #", "Question Date","Answer Date", "Cluster","Similarity Score"),
              class = 'display',
              width = 25,
              caption = "Questions ranked by similarity to search text:",
              options = list(deferRender = TRUE,
                             scrollY = 400,
                             scroller = TRUE,
                             searching = FALSE,
                             paging = FALSE, #,deferRender = TRUE,
                             server = TRUE
                             )
    )
  })
  
  output$x2 <- renderPlotly({
    gg=plot_ly(x = df()$Date, y = df()$Score,
            type = 'scatter', mode = 'markers', 
            hoverinfo = 'text',
            text = ~paste("Q:", df()$Question_Text,
                          "<br> Date:", df()$Date,
                          "<br> Cluster:", df()$Cluster,
                          "<br> Similarity Score:", df()$Score)) 
    
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
### Cluster Pane  
  
  dfClus = function(){
    df = subset(dat(), (dat()$Cluster == input$x3))
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
    df = subset(dat(), (dat()$Question_MP == input$person_choice))
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
