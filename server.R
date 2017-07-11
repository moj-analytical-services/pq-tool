?source(file = "global.R")

############### Server

function(input, output) {
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
    df()[1:input$points,]
  })

  
  
  output$similarity_table <- renderDataTable({
    #event.data <- event_data("plotly_click", source = "select")
    datatable(
      cbind(' ' = '&oplus;', plot_points()), escape = -2,
      #colnames = c("Similarity Rank","Question MP","Question Date", "Answer Date", "Topic Number", "Topic Keywords"),
      options = list(
        columnDefs = list(
          list(visible = FALSE, targets = c(0, 2:7, 9:10, 13)),
          list(orderable = FALSE, className = 'details-control', targets = 1)
        ),
        deferRender = TRUE,
        scrollY = 400,
        scroller = TRUE,
        searching = FALSE,
        paging = FALSE,
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
  
  
   y_axis <- list(
    title = "Similarity",
    autotick = TRUE,
    ticks = "",
    showticklabels = FALSE
  )

  output$similarity_plot <- renderPlotly({
    gg=plot_ly(x = plot_points()$Date , source = 'select') %>%
      add_markers(y = plot_points()$Similarity_score,
                  text = ~paste("Rank:", plot_points()$Rank,
                                "<br> Member HoC/HoL:", plot_points()$Question_MP,
                                "<br> Date:", plot_points()$Date ),
                  hoverinfo = "text"
      )%>%
      layout(yaxis = y_axis,
             title = "How similar question is to search phrase, and when it was asked",
             titlefont=list(
               family='Arial',
               size=14,
               color='#696969')) %>%
      add_trace(x = plot_points()$Date[input$similarity_table_rows_selected], 
                y = plot_points()$Similarity_score[input$similarity_table_rows_selected], 
                type = "scatter", mode = 'markers', marker = list(size = 12),
                text = NULL,
                hoverinfo = "text" 
      ) %>%
      config(displayModeBar = F) %>%
      layout(showlegend = FALSE)
  })
  
  
  
  output$test <- renderPlotly({
    event.data <-
      event_data("plotly_click", source = "select")
  })
  
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
    df <- subset(data, (data$Cluster == input$cluster_choice))
  }

  wordcloud_df <- function(){
    df <- dplyr::filter(cluster_data,
                        (cluster_data$cluster == input$cluster_choice))
  }

  output$wordcloud <- renderPlot(
    wordcloud(words = wordcloud_df()$word, freq = wordcloud_df()$freq,
              scale = c(4, 1), random.order = TRUE, ordered.colors = TRUE,
              min.freq = 0.1)
  )

  output$cluster_choice <- renderPlot({
    p <- ggplot(data = NULL, aes(x = dfClus()$Date, y = )) +
      geom_bar(color = "red", fill = "red", width = .5)
    p + xlim(min(data$Date) - 1, max(data$Date) + 1) +
      labs(title = "When the questions were asked:",
           x = "Question Date",
           y = "Count") +
      theme(plot.title = element_text(size = 17, face = "bold"))
  })

  output$cluster_documents <- renderDataTable({
    datatable(data = dfClus()[, c("Question_Text", "Answer_Text")],
              colnames = c("Question Text", "Answer Text"),
              caption = "Documents contained within the topic:",
              options = list(scroller = TRUE,
                             searching = FALSE,
                             paging = FALSE))
  })

  ### Q&A Analysis Pane
  output$q_analysis_ui <- renderUI({
    switch(input$q_analysis,
           "Lords" = selectInput(inputId = "person_choice",
                                 label = "Choose a Member:",
                                 choices = sort(unique(data$Question_MP[grepl("HL", data$Question_ID) == TRUE]))
           ),
           "Commons" = selectInput(inputId = "person_choice",
                                   label = "Choose an MP:",
                                   choices = sort(unique(data$Question_MP[grepl("HL", data$Question_ID) == FALSE]))
           )
    )
  })

  dfMP <- function(){
    df <- subset(data, (data$Question_MP == input$person_choice))
  }

  output$q_analysis_plot <- renderPlot({
    p <- ggplot(data = NULL, aes(x = dfMP()$Date, y = )) +
      geom_bar(color = "red", fill = "red", width = .5)
    p + xlim(min(data$Date) - 1, max(data$Date) + 1) +
      labs(title = "When the questions were asked:",
           x = "Question Date",
           y = "Count") +
      theme(plot.title = element_text(size = 17, face = "bold"))
  })

  output$q_analysis_table <- renderDataTable({
    datatable(dfMP()[, c("Date", "Question_ID", "Question_Text", "Cluster")]
              #options = c(
              #  searching = FALSE#,
              #colnames = c("Question Date","Question ID", "Question Text", "Cluster")
              #)
    )
  })


### Data Pane

  output$data_pane <- renderDataTable({
    datatable(data = data[, c("Question_ID",
                             "Question_Text",
                             "Answer_Text",
                             "Question_MP",
                             "MP_Constituency",
                             "Answer_MP",
                             "Date",
                             "Answer_Date",
                             "Cluster",
                             "Cluster_Keywords")],
              colnames = c("Document #",
                           "Question ID",
                           "Question Text",
                           "Answer Text",
                           "Question MP",
                           "MP Constituency",
                           "Answer MP",
                           "Question Date",
                           "Answer Date",
                           "Topic Number",
                           "Topic Keywords"),
              filter = "top",
              options = list(scroller = TRUE,
                             paging = FALSE
                             #autoWidth = TRUE,
                             #columnDefs = list(list(width = "30%", targets = list(2,3)))
                             ))
  })
}
