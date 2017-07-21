?source(file = "global.R")

############### Server

function(input, output, session) {
### Similarity Pane

  returnNearestMatches <- reactive({
    space <- search.space
    foundWords <- which(space$i %in% queryVec(input$question))
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
    df()[1:100,]
  })
  
  min_date <- reactive({
    min(plot_points()$Date)
  })
  
  max_date <-reactive({
    max(plot_points()$Date)
  })
  
  line_points <- reactive({
    df <- data.frame(0,0)
    
    for (i in 0:10) {
      points_in_range <- reactive({
        subset(df(), Date >= min_date() + (i-1)*90  &
                 Date <= min_date()+(i+1)*90)
      })
      score <- reactive({
        sum(points_in_range()$Similarity_score)/100 + mean(plot_points()$Similarity_score)
      })
      #df$Date[i] <- as.Date.character(as.Date(as.numeric(min_date())+(i*90), origin = "1970-01-01"))
      df[i,1] <- (min_date()+(i*90))
      df[i,2] <- score()
      df$X0 <- as.Date(df$X0, format="%Y%m%d", origin = "1970-01-01")    }
    return(df)
  })

  output$similarity_table <- renderDataTable({
    datatable(
      cbind(' ' = '&oplus;', plot_points()), escape = -2,
      #colnames = c("Similarity Rank","Question MP","Question Date", "Answer Date", "Topic Number", "Topic Keywords"),
      options = list(
        columnDefs = list(
          list(visible = FALSE, targets = c(0, 2:7, 9:10,13)),
          list(orderable = FALSE, className = 'details-control', targets = 1)
        ),
        deferRender = TRUE,
        #scrollY = 400,
        scroller = TRUE,
        searching = FALSE,
        paging = TRUE,
        lengthChange = FALSE,
        pageLength = 8,
        server = FALSE
      ),
      callback = JS("
                table.column(1).nodes().to$().css({cursor: 'pointer'});
                var format = function(d) {
                return '<div style=\"background-color:#eee; padding: .5em;word-wrap:break-word;width: 600px; \"> Question Text: ' +
                d[6] + '</br>' + '</br>' +
                'Answer Text: ' + d[7] +  '</div>';
                };
                table.on('click', 'tr', function() {
                var row = this.closest('tr');
                var showHideIcon = $(row.firstChild);
                var shinyRow = table.row(row);
                if (shinyRow.child.isShown()) {
                shinyRow.child.hide();
                showHideIcon.html('&oplus;');
                } else {
                shinyRow.child(format(shinyRow.data())).show();
                showHideIcon.html('&ominus;');
                }
                });"
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
                  name = 'Top 100 Qs',
                  text = ~paste("Rank:", plot_points()$Rank,
                                "<br> Member HoC/HoL:", plot_points()$Question_MP,
                                "<br> Date:", plot_points()$Date ),
                  hoverinfo = "text"
      )%>%
      layout(yaxis = y_axis,
             title = "Top 100 questions most similar to your search",
             titlefont=list(
               family='Arial',
               size=14,
               color='#696969')) %>%
      add_trace(x = plot_points()$Date[input$similarity_table_rows_current], 
                y = plot_points()$Similarity_score[input$similarity_table_rows_current],
                name = "Current Table Page",
                type = "scatter", mode = 'markers', # marker = list(size = 12),
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
      add_trace(x = line_points()$X0,
                y = line_points()$X0.1,
                name = "Trendline",
                type = 'scatter',
                mode = 'lines',
                line = list(                                       # line is a named list, valid keys: /r/reference/#scatter-line
                  color = "green"),
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

  dfClus <- function(){
    df <- subset(tables_data, (tables_data$Topic == input$topic_choice))
  }

  wordcloud_df <- function(){

    df <- subset(topic_data,
                        (topic_data$topic == input$topic_choice))
  }

  observeEvent(input$explanation_button, {
    showModal(modalDialog(
      title = "What do the topics mean?", 
      paste0("We have taken all of the questions in our database and fed them into an algorithm which has ",
      "split them into different groups, or 'topics', with each group containing questions related to ", 
      "similar issues. For each topic there are a set of three 'Topic Keywords' to give an idea of what ",
      "the topic is at a glance.<br />", 
      "Each of these topics have also been assigned a number as a unique identifier, so the best way to find ", 
      "out about your chosen topic is to go to the \'Search\' tab and, once you have entered your search ",
      "terms, take one of the topic numbers listed in the table and put it into the dropdown box on this ",
      "tab."),
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
      scale_y_continuous(breaks = pretty_breaks()) +
      labs(title = "When the questions were asked:",
           x = "Question Date",
           y = "Count") +
      theme(plot.title = element_text(size = 17, face = "bold"))
  })
  
  addPopover(session, "topic_plot", "Questions plotted over time",
             content = paste0("This plot shows when the questions in the topic were asked. <br> The x axis shows the date when questions were asked and the y axis shows the count of questions asked on that date."),
             trigger = 'hover', placement = 'top', options = list(container = "body"))

  output$topic_documents <- renderDataTable({
    datatable(data = dfClus(), #[, c("Question_Text", "Answer_Text")],
              #colnames = c("Question Text", "Answer Text"),
              caption = "Documents contained within the topic:",
              extensions = 'Buttons',
              rownames = FALSE,
              options = list(dom = 'Bfrtip', 
                             buttons = I('colvis'),
                             scroller = TRUE,
                             searching = FALSE,
                             paging = TRUE,
                             lengthChange = FALSE,
                             pageLength = 5))
  })
  
  addPopover(session, "topic_documents", "Questions in the topic",
             content = paste0("This table contains all of the information on the questions asked on this topic.<br>",
                              "You can choose which columns to show/hide by clicking on the \"Column Visibility\" button."),
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
  }
  
  output$member_wordcloud <- renderPlot({
    wordcloud_input <- reactive({
      getElement(allMPs, input$person_choice)
    })
    plotWordcloud(wordcloud_input())
  })
  
  output$member_plot <- renderPlot({
    p <- ggplot(data = NULL, aes(x = dfMP()$Date, y = )) +
      geom_bar(color = "red", fill = "red", width = .5)
    p + xlim(min(data$Date) - 1, max(data$Date) + 1) +
      scale_y_continuous(breaks = pretty_breaks()) +
      labs(title = "When the member asked questions:",
           x = "Question Date",
           y = "Count") +
      theme(plot.title = element_text(size = 17, face = "bold"))
  })
  
  addPopover(session, "member_plot", "Questions plotted over time",
             content = paste0("This plot shows when questions were asked by the selected member. <br> The x axis shows the date when questions were asked and the y axis shows the count of questions asked on that date."),
             trigger = 'hover', placement = 'top', options = list(container = "body"))

  output$member_table <- renderDataTable({
    datatable(dfMP(),
              extensions = 'Buttons',
              rownames = FALSE,
              options = list(dom = 'Bfrtip', 
                             buttons = I('colvis'),
                             searching = FALSE,
                             paging = TRUE,
                             lengthChange = FALSE,
                             pageLength = 5))
  })
  
  addPopover(session, "member_table", "Questions asked by the member",
             content = paste0("This table contains all of the information on the questions asked by this member.<br>",
                              "You can choose which columns to show/hide by clicking on the \"Column Visibility\" button."),
             trigger = 'hover', placement = 'top', options = list(container = "body"))
  

}
