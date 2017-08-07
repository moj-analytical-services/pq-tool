?source(file = "global.R")
############### Server

function(input, output, session) {
  ### Similarity Pane
  returnNearestMatches <- reactive({
    space <- search.space
    foundWords <- which(space$i %in% queryVec(input$question))
    if(length(foundWords)==0){
      return("Unable to determine similarity to query")
    }
    Document <- space$j[foundWords]
    vees <- space$v[foundWords]
    JayVees <- data.table(Document = Document, vees = vees)
    
    outGroup <- JayVees[,
                        .("Similarity_score" = sum(vees)),
                        by = Document ][order(-Similarity_score)]
    table_output <- outGroup #[1:30]
    data <- merge.data.frame(table_output,
                             data,
                             by.x = "Document",
                             by.y = "Document_Number")
    
    data["Similarity_score"] <- round(data["Similarity_score"], digits = 2)
    data <- data[with(data, order(-data["Similarity_score"])), ]
    rownames(data) <- 1:nrow(data)
    data["Rank"] <- as.numeric(rownames(data))
    return(data)
  })
  
  df <- reactive({
    subset(returnNearestMatches(),
           returnNearestMatches()$Date >= input$q_date_range[1] &
             returnNearestMatches()$Date <= input$q_date_range[2])
  })
  
  plot_points <- reactive({
    cols <- c(
      'Question_Text',
      'Answer_Text',
      'Similarity_score',
      'Rank',
      'Question_MP',
      'Date',
      'Answer_Date',
      'Topic',
      'Topic_Keywords'
    )
    tryCatch({
      df()[1:100, cols]
    }, warning = function(war){
      print("warning")
    }, error = function(err){
      print("Unable to complete query.  Try resolving typos or including more search terms.")
    }, finally = {
      
    })
  })
  
  min_date <- reactive({
    min(plot_points()$Date)
  })
  
  max_date <-reactive({
    max(plot_points()$Date)
  })
  
  
  #using LOESS smoothing we plot a non-parametric curve of best fit for the plotted scatter points, which should
  #give an indication of how interest has risen and fallen over time.
  line_points <- reactive({
    tryCatch({
      test <- plot_points()$Similarity_score
    }, warning = function(war){
      print("warning")
    }, error = function(err){
      print("error")
    },  finally = {
      loessThing <- loess(plot_points()$Similarity_score ~ as.numeric(plot_points()$Date), span = 1/exp(1), degree = 2)
      Dates <- as.Date(loessThing$x[order(loessThing$x)][-length(loessThing$x)][-1], format="%Y-%m-%d", origin = "1970-01-01")
      Scores <- loessThing$fitted[order(loessThing$x)][-length(loessThing$x)][-1]
      Scores[Scores < 0] <- 0
      return(data.frame(Dates = Dates, 
                        Scores = Scores))
    })
  })
  
  output$similarity_table <- renderDataTable({
    datatable(
      cbind(' ' = '&oplus;', plot_points()), escape = -2,
      options = list(
        columnDefs = list(
          list(visible = FALSE, targets = c(0, 2, 3, 4)),
          list(orderable = FALSE, className = 'details-control', targets = 1)
        ),
        deferRender = TRUE,
        #scrollY = 400,
        scroller = TRUE,
        searching = FALSE,
        paging = TRUE,
        lengthChange = FALSE,
        pageLength = 10,
        server = FALSE
      ),
      callback = JS("
                search_table = table;
                table.column(1).nodes().to$().css({cursor: 'pointer'});
                table.on('click', 'tr', rowActivate);"
      ),
      caption = "Questions ranked by similarity to search text. Select a row to see the corresponding question text:"
    )
  })
  
  addPopover(session, "similarity_table", "What does this table show?",
             content = paste0("<p> This table shows the past PQs that are most similar to your search (with the most",
                              " similar questions are at the top). </p><p> You can click any row to see the question text,",
                              " or reorder the results by clicking on the column headings. </br> </br> All the questions in",
                              " our database have been grouped into topics by an algorithm and given Topic numbers. Try",
                              " entering one of the topic numbers you see here into the box at the top of the \'Topic ",
                              "Analysis\' page.</p>"), trigger = 'hover', placement = 'right', options = list(container = "body"))
  
  
  y_axis <- list(
    title = "Similarity",
    autotick = TRUE,
    ticks = "",
    showticklabels = FALSE,
    rangemode = "tozero"
  )
  
  output$similarity_plot <- renderPlotly({
    gg=plot_ly(x = plot_points()$Date) %>%
      add_markers(y = plot_points()$Similarity_score,
                  name = "Top 100 Qs",
                  text = ~paste("Rank:", plot_points()$Rank,
                                "<br> Member HoC/HoL:", plot_points()$Question_MP,
                                "<br> Date:", plot_points()$Date ),
                  hoverinfo = "text",  marker = list(color = "#67a9cf")
      )%>%
      #add trend line first so it's the bottom layer
      add_trace(x = line_points()$Dates,
                y = line_points()$Scores,
                name = "Avg. parliamentary interest in search phrase",
                type = 'scatter',
                mode = 'lines',
                line = list(                                       # line is a named list, valid keys: /r/reference/#scatter-line
                  color = "gray"),
                text = NULL,
                hoverinfo = "text"
      ) %>%
      layout(yaxis = y_axis,
             title = "Top 100 questions most similar to your search",
             titlefont=list(
               family='Arial',
               size=14,
               color='#696969')
      ) %>%
      add_trace(x = plot_points()$Date[input$similarity_table_rows_current], 
                y = plot_points()$Similarity_score[input$similarity_table_rows_current],
                name = "Current Table Page",
                type = "scatter", mode = 'markers',  marker = list(color = "#ef8a62"),
                text = ~paste("Rank:", plot_points()$Rank[input$similarity_table_rows_current],
                              "<br> Member HoC/HoL:", plot_points()$Question_MP[input$similarity_table_rows_current],
                              "<br> Date:", plot_points()$Date[input$similarity_table_rows_current] ),
                hoverinfo = "text" 
      ) %>%
      add_trace(x = plot_points()$Date[input$similarity_table_rows_selected], 
                y = plot_points()$Similarity_score[input$similarity_table_rows_selected], 
                name = 'Qs selected',
                type = "scatter", mode = 'markers', marker = list(size = 12, color = "red"),
                text = NULL,
                hoverinfo = "text"
      ) %>%
      
      config(displayModeBar = F) %>%
      layout(legend = list(orientation = 'h'))
  })
  
  addPopover(session, "similarity_plot", "What does this plot show?",
             content = paste0("<p>This graph plots Similarity on the y axis against Time on the x axis.</p><p>",
                              "Each point represents a past PQ from our database with the height showing ",
                              "how similar the PQ is to the search terms (higher = more similar). ",
                              " </p>"), trigger = 'hover', placement = 'left')
  
  
  # q_text <- reactive({
  #   df()[input$similarity_table_rows_selected, ]
  # })
  # 
  # output$q_text_table <- renderDataTable({
  #   datatable(data = q_text()[, c("Question_Text", "Answer_Text")],
  #             colnames = c("Question Text", "Answer Text"),
  #             caption = "Question Text:",
  #             options = list(scroller = TRUE,
  #                            searching = FALSE,
  #                            paging = FALSE
  #             ))
  # })
  
  ### Cluster Pane
  
  #input$x3 = input$x1_rows_selected
  # how to get datatable on 1st tab to link in?
  
  # cols <- c(
  #     'Question_Text',
  #     'Answer_Text',
  #     'Similarity_score',
  #     'Rank',
  #     'Question_MP',
  #     'Date',
  #     'Answer_Date',
  #     'Topic',
  #     'Topic_Keywords'
  #   )
  
  dfClus <- function(){
    cols <- c(
      'Question_Text',
      'Answer_Text',
      'Question_MP',
      'MP_Constituency',
      'Date',
      'Answer_MP',
      'Answer_Date'
    )
    df <- subset(tables_data, (tables_data$Topic == input$topic_choice))
    df[cols]
  }
  
  wordcloud_df <- function(){
    
    df <- subset(topic_data,
                 (topic_data$topic == input$topic_choice))
  }
  
  observeEvent(input$explanation_button, {
    showModal(modalDialog(
      title = "What do the topics mean?", 
      HTML("We have taken all of the questions in our database and fed them into an algorithm which has
      split them into different groups, or 'topics', with each group containing questions related to  
      similar issues. For each topic there are a set of three 'Topic Keywords' to give an idea of what 
      the topic is at a glance. <br><br>
      Each of these topics have also been assigned a number as a unique identifier, so the best way to find  
      out about your chosen topic is to go to the \'Search\' tab and, once you have entered your search 
      terms, take one of the topic numbers listed in the table and put it into the dropdown box on this 
      tab."),
      easyClose = TRUE,
      footer = NULL
    ))
  })
  
  output$wordcloud <- renderPlot(
    wordcloud(words = wordcloud_df()$word, freq = wordcloud_df()$freq,
              scale = c(4, 1), random.order = TRUE, ordered.colors = TRUE,
              min.freq = 0.1)
  )
  
  addPopover(session, "wordcloud", "Wordcloud",
             content = paste0("This wordcloud shows the words that are most important to the topic.<br> The bigger the word, the more important it is."),
             trigger = 'hover', placement = 'top', options = list(container = "body"))
  
  
  output$topic_plot <- renderPlot({
    p <- ggplot(data = NULL, aes(x = dfClus()$Date, y = )) +
      geom_bar(color = "red", fill = "red", width = .5)
    p + xlim(min(data$Date) - 1, max(data$Date) + 1) +
      scale_y_continuous(breaks = pretty_breaks(),limits = c(0, 5)) +
      labs(title = "When this topic was asked about:",
           x = "Question Date",
           y = "Count") +
      theme(plot.title = element_text(size = 17, face = "bold"))
  })
  
  addPopover(session, "topic_plot", "Questions plotted over time",
             content = paste0("This plot shows when the questions in the topic were asked. <br> The x axis shows the date when questions were asked and the y axis shows the count of questions asked on that date."),
             trigger = 'hover', placement = 'top', options = list(container = "body"))
  
  output$topic_documents <- renderDataTable({
    datatable(
      cbind(' ' = '&oplus;', dfClus()), escape = -2,
      options = list(
        columnDefs = list(
          list(visible = FALSE, targets = c(0, 2, 3)),
          list(orderable = FALSE, className = 'details-control', targets = 1)
        ),
        caption = "Documents contained within the topic:",
        deferRender = TRUE,
        scroller = TRUE,
        searching = FALSE,
        paging = TRUE,
        lengthChange = FALSE,
        pageLength = 8,
        server = FALSE
      ),
      callback = JS("
                topic_table = table;
                table.column(1).nodes().to$().css({cursor: 'pointer'});
                table.on('click', 'tr', rowActivate);"
      )
    )
    # datatable(data = dfClus(), #[, c("Question_Text", "Answer_Text")],
    #           #colnames = c("Question Text", "Answer Text"),
    #           caption = "Documents contained within the topic:",
    #           extensions = 'Buttons',
    #           rownames = FALSE,
    #           options = list(dom = 'Bfrtip', 
    #                          buttons = I('colvis'),
    #                          scroller = TRUE,
    #                          searching = FALSE,
    #                          paging = TRUE,
    #                          lengthChange = FALSE,
    #                          pageLength = 5))
  })
  
  addPopover(session, "topic_documents", "Questions in the topic",
             content = paste0("This table contains all of the information on the questions asked on this topic.<br>",
                              "Click on a row to see the corresponding question and answer text."),
             trigger = 'hover', placement = 'top', options = list(container = "body"))
  
  ### Q&A Analysis Pane
  output$member_ui <- renderUI({
    switch(input$member_analysis,
           "Lords" = selectInput(inputId = "person_choice",
                                 label = "Choose a Peer:",
                                 choices = sort(unique(data$Question_MP[grepl("HL", data$Question_ID) == TRUE]))
           ),
           "Commons" = selectInput(inputId = "person_choice",
                                   label = "Choose an MP:",
                                   choices = sort(unique(data$Question_MP[grepl("HL", data$Question_ID) == FALSE]))
           )
    )
  })
  
  dfMP <- function(){
    df <- subset(tables_data, (tables_data$Question_MP == input$person_choice))
    df <- df[order(-as.numeric(df$Date)),]
    cols <- c(
      'Question_Text',
      'Answer_Text',
      'Question_MP',
      'MP_Constituency',
      'Date',
      'Answer_MP',
      'Answer_Date',
      'Topic',
      'Topic_Keywords'
    )
    df[cols]
  }
  
  output$member_wordcloud <- renderPlot({
    wordcloud_input <- reactive({
      getElement(allMPs, input$person_choice)
    })
    plotWordcloud(wordcloud_input())
  })
  
  addPopover(session, "member_wordcloud", "Wordcloud",
             content = paste0("This wordcloud shows the words that are most important in the questions asked by this member.<br> The bigger the word, the more important it is."),
             trigger = 'hover', placement = 'top', options = list(container = "body"))
  
  output$member_plot <- renderPlot({
    p <- ggplot(data = NULL, aes(x = dfMP()$Date, y = )) +
      geom_bar(color = "red", fill = "red", width = .5)
    p + xlim(min(data$Date) - 1, max(data$Date) + 1) +
      scale_y_continuous(breaks = pretty_breaks(),limits = c(0, 8)) +
      labs(title = "When the member asked questions:",
           x = "Question Date",
           y = "Count") +
      theme(plot.title = element_text(size = 17, face = "bold"))
  })
  
  addPopover(session, "member_plot", "Questions plotted over time",
             content = paste0("This plot shows when questions were asked by the selected member. <br> The x axis shows the date when questions were asked and the y axis shows the count of questions asked on that date."),
             trigger = 'hover', placement = 'top', options = list(container = "body"))
  
  output$member_table <- renderDataTable({
    datatable(
      cbind(' ' = '&oplus;', dfMP()), escape = -2,
      options = list(
        columnDefs = list(
          list(visible = FALSE, targets = c(0, 2, 3)),
          list(orderable = FALSE, className = 'details-control', targets = 1)
        ),
        caption = "Documents contained within the topic:",
        deferRender = TRUE,
        scroller = TRUE,
        searching = FALSE,
        paging = TRUE,
        lengthChange = FALSE,
        pageLength = 8,
        server = FALSE
      ),
      callback = JS("
                member_table = table;
                table.column(1).nodes().to$().css({cursor: 'pointer'});
                table.on('click', 'tr', rowActivate);"
      )
    )
    
  })
  
  addPopover(session, "member_table", "Questions asked by the member",
             content = paste0("This table contains all of the information on the questions asked by this member.<br>",
                              "Click on a row to see the corresponding question and answer text."),
             trigger = 'hover', placement = 'top', options = list(container = "body"))
  
  
}
