?source(file = "global.R")
############### Server

function(input, output, session) {

  
  ### Similarity Pane
  returnNearestMatches <- reactive({
    space <- search.space
    foundWords <- which(space$i %in% queryVec(input$question, vocab))
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
      'MP_Party',
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
          list(visible = FALSE, targets = c(0, 2, 3, 4, 9, 10)),
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
             content = paste0("<p> This table shows the past written PQs that are most similar to your search (the most",
                              " similar questions are at the top). </p><p> You can click any row to see the question text,",
                              " or reorder the results by clicking on the column headings. </br> </br> All the questions in",
                              " our database have been grouped into topics by an algorithm and given Topic numbers. Try",
                              " clicking on the 'View Topic' button to see all the questions . ",
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
      add_markers(y = plot_points()$Similarity_score,
                  name = "Top 100 Qs",
                  text = ~paste("Rank:", plot_points()$Rank,
                                "<br> Member HoC/HoL:", plot_points()$Question_MP,
                                "<br> Date:", plot_points()$Date ),
                  hoverinfo = "text",  marker = list(color = "#67a9cf")
      )%>%
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

  observeEvent(
    input$tutorial_button, {
      introjs(session,
              events = list(
                "onchange" = I("console.log(this._currentStep)
                              if (this._currentStep==6) { 
                               $('.btn-info')[0].addEventListener('mouseup', function(){
                               setTimeout(function(){
                               $('.introjs-nextbutton').click()
                               }, 1000)
                               })
                               } else if (this._currentStep==10) {
                               $('.btn-info')[2].addEventListener('mouseup', function(){
                               setTimeout(function(){
                               $('.introjs-nextbutton').click()
                               }, 1000)
                               })
                               } else if (this._currentStep==11) {
                               $('.btn-info')[1].addEventListener('mouseup', function(){
                               console.log('btn info clicked')
                               setTimeout(function(){
                               $('.introjs-nextbutton').click()
                               }, 1000)
                               })
                               }"),
              "onbeforechange" = I("if (this._currentStep == 1) {
                                   question = $('#question');
                                   if(question.val() == '') {
                                    question.val('Prison officers');
                                    Shiny.onInputChange('question', 'Prison officers');
                                    this._currentStep = 0;
                                    $('.introjs-tooltiptext').text(\"We've added some search terms for you, but you can change them if you like.\");
                                    introJs().previousStep();
                                   }
                                 } else if (this._currentStep == 3) {
                                   selected_rows = $('.selected')
                                   if ( selected_rows.length == 0 ) {
                                    this._currentStep = 2;
                                    $('.introjs-tooltiptext').text('Please select a row before continuing.');
                                    introJs().previousStep();
                                   }
                                 } else if (this._currentStep == 5 ) {
                                   new_selection = $('.selected')
                                   prev_selection = selected_rows
                                   if(noChange(new_selection, prev_selection)) {
                                    this._currentStep = 4;
                                    $('.introjs-tooltiptext').text('Please select another point on the graph before continuing.');
                                    introJs().previousStep();
                                   }
                                 }")
              ),
              options = list("nextLabel" = "Next",
                             "scrollToElement" = FALSE,
                             "showProgress" = TRUE,
                             "showBullets" = FALSE,
                             "keyboardNavigation" = TRUE))
  })
  
#   observeEvent(input$startButton, {
#     introjs(
#       session,
#       events = list(
#         "onchange" = I("debugger;
#                     if (this._currentStep==7) {
#                        $('a[data-value=\"Second tab\"]').removeClass('active');
#                        $('a[data-value=\"First tab\"]').addClass('active');
#                        $('a[data-value=\"First tab\"]').trigger('click');
#   }
#                        if (this._currentStep==1) {
#                        $('a[data-value=\"First tab\"]').removeClass('active');
#                        $('a[data-value=\"Second tab\"]').addClass('active');
#                        $('a[data-value=\"Second tab\"]').trigger('click');
#                        }")
#       )
#         )
#     
# })
  
  
  ### Cluster Pane
  
  dfClus <- function(){
    cols <- c(
      'Question_Text',
      'Answer_Text',
      'Question_MP',
      'MP_Constituency',
      'MP_Party',
      'Date',
      'Answer_MP',
      'Answer_Date'
    )
    df <- subset(tables_data, (tables_data$Topic == input$topic_choice))
    df <- df[order(-as.numeric(df$Date)),]
    df[cols]
  }
  
  keyword <- reactive({
    subset(tables_data, (tables_data$Topic == input$topic_choice))$Topic_Keywords[1]
    })
  
  minDate <- min(tables_data$Date)
  maxDate <- max(tables_data$Date + 14)
  
  wordcloud_df <- function(){
    df <- subset(topic_data,
                 (topic_data$topic == input$topic_choice))
  }
  
  observeEvent(input$explanation_button, {
    showModal(modalDialog(
      title = "What do the topics mean?", 
      HTML("We have taken all of the questions in our database and fed them into an algorithm which has
      split them into different groups, or 'topics', with each group containing questions related to  
      similar issues. For each topic there is a set of three 'Topic Keywords' to give an idea of what 
      the topic is about. <br><br>
      Each of these topics have also been assigned a number as a unique identifier. To find  
      out about your chosen topic, go to the 'Search' tab and, once you have entered your search 
      terms, take one of the topic numbers listed in the table and put it into the dropdown box on this 
      tab. Or if that sounds like too much work, just click the question you are focusing on followed by
      the 'View Topic' button."),
      easyClose = TRUE,
      footer = NULL
    ))
  })
  
  output$wordcloud <- renderPlot(
    wordcloud(words = wordcloud_df()$word, freq = wordcloud_df()$freq,
              scale = c(4, 1), random.order = TRUE,
              min.freq = 0.1)
  )
  
  addPopover(session, "wordcloud", "Wordcloud",
             content = paste0("This wordcloud shows the words that are most important to the topic.<br><br> The bigger the word, the more important it is."),
             trigger = 'hover', placement = 'top', options = list(container = "body"))
  
  
  output$topic_plot <- renderPlot({
    p <- ggplot(data = NULL, aes(x = dfClus()$Date, y = )) +
      geom_histogram(binwidth = 14, fill = "#67a9cf")
    maxCount <- ggplot_build(p)$data[[1]]$count %>% max() #this is a hack from stackoverflow to get us the max value of the histogram
    yBreaks <- if(maxCount < 11){
      1} else if(maxCount < 21){
        2} else{
          5}
    yMax <- (floor(maxCount / yBreaks) + 1) * yBreaks
    p + 
      xlim(min(data$Date) - 1, max(data$Date) + 1) +
      scale_x_date(limits = c(minDate, maxDate),
                   labels = date_format("%b %y"),
                   date_breaks = "6 months",
                   date_minor_breaks = "1 month") +
      scale_y_continuous(
        breaks = seq(0, yMax, yBreaks),
        expand = c(0,0),
        limits = c(0, yMax)) +
      labs(title = paste0("Topic ", input$topic_choice, ": ", keyword()),
           subtitle = paste0("Each bar shows the number of questions for topic ", input$topic_choice, " in a particular fortnight"),
           x = "Question Date",
           y = "Count"
      ) + 
      theme(panel.background = element_rect(fill = "white", colour = "grey"),
            panel.grid.minor = element_line(colour = "#efefef"),
            panel.grid.major = element_line(colour = "#efefef"),
            axis.title = element_text(family = "Arial", size = 14, colour = "#4f4f4f"),
            axis.text = element_text(family = "Arial", size = 14),
            axis.line = element_line(colour = "grey"),
            plot.title = element_text(size = 17, face = "bold", family = "Arial", colour = "#4f4f4f"),
            plot.subtitle = element_text(size = 12, family = "Arial", colour = "#4f4f4f")
            #axis.ticks.x = element_line(size = 0)
      )
  })
  

  
  addPopover(session, "topic_plot", "Questions plotted over time",
             content = paste0("This plot shows when questions in the topic were asked. <br><br> Each bar shows the number of questions asked in a particular fortnight - the higher the bar, the more questions from that topic."),
             trigger = 'hover', placement = 'left', options = list(container = "body"))
  
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
        pageLength = 10,
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
             content = paste0("This table contains all of the information on the questions asked on this topic.<br><br>",
                              "Click on a row to see the corresponding question and answer text."),
             trigger = 'hover', placement = 'top', options = list(container = "body"))
  
  ### Q&A Analysis Pane

  # Each item in hoc_members must be a list to achieve the desired effect in the hoc members dropdown
  list_if_one <- function(members) {
    if(length(members) == 1) {
      return(list(members))
    } else {
      return(members)
    }
  }

  # Merge labur and labour (co-op) members for the sake of the drop down list (only)
  merge_labour_and_co_op <- function(members) {
    members$Labour <- append(members$Labour, members$'Labour (Co-op)') %>% sort()
    members$'Labour (Co-op)' <- NULL
    members
  }

  hoc_members <- function(data) {
    parties <- data$MP_Party[ data$MP_Party != 'Not found' ] %>%
                 unique() %>%
                 sort()

    members <- lapply(parties, function(party) {
                 data$Question_MP[ data$MP_Party == party ] %>%
                 unique() %>%
                 sort() %>%
                 list_if_one()
               })
    
    names(members) <- parties
    merge_labour_and_co_op(members)
  }

  output$member_ui <- renderUI({
    switch(input$member_analysis,
           "Lords" = selectInput(inputId = "person_choice",
                                 label = "Choose a Peer:",
                                 choices = sort(unique(data$Question_MP[ grepl("HL", data$Question_ID) ]))
           ),
           "Commons" = selectInput(inputId = "person_choice",
                                   label = "Choose an MP:",
                                   choices = hoc_members(data)
           )
    )
  })

  grouped_hoc_members <- function(hoc_data) {

  }

  dfMP <- function(){
    df <- subset(tables_data, (tables_data$Question_MP == input$person_choice))
    df <- df[order(-as.numeric(df$Date)),]
    cols <- c(
      'Question_Text',
      'Answer_Text',
      'Question_MP',
      'MP_Constituency',
      'MP_Party',
      'Date',
      'Answer_MP',
      'Answer_Date',
      'Topic',
      'Topic_Keywords'
    )
    df[cols]
  }
  
  minDate <- min(tables_data$Date)
  maxDate <- max(tables_data$Date + 14)
  
  member_wordcloud_df <- function(){
    df <- subset(member_data,
                 (member_data$member == input$person_choice))
  }
  
  output$member_wordcloud <- renderPlot(
    wordcloud(words = member_wordcloud_df()$word, freq = member_wordcloud_df()$freq,
              scale = c(4, 1), random.order = TRUE,
              min.freq = 0.1)
  )
  
  
  
  linkText <- reactive({
    paste0("TheyWorkForYouPage for ",
           input$person_choice)
  })
  
  linkURL <- reactive({
    paste0("https://www.theyworkforyou.com/",
           if(input$member_analysis=="Commons"){
             "mp/"
           } else {
             "peer/"
           },
           urlName(input$person_choice)
           )
  })
  
  output$memberlink <- renderUI({
    tags$a(href = linkURL(), target="_blank", linkText())
  })
  
  addPopover(session, "member_wordcloud", "Wordcloud",
             content = paste0("This wordcloud shows the words that are most important in the questions asked by this
                              member.<br><br> The bigger the word, the more important it is."),
             trigger = 'hover', placement = 'top', options = list(container = "body"))
  
  output$member_plot <- renderPlot({
    p <- ggplot(data = NULL, aes(x = dfMP()$Date, y = )) + geom_histogram(binwidth = 14, fill = "#67a9cf")
    maxCount <- ggplot_build(p)$data[[1]]$count %>% max() #max value of the histogram
    yBreaks <- if(maxCount < 11) {
      1 
    } else if(maxCount < 21){
      2
    } else {
      5
    }
    yMax <- (floor(maxCount / yBreaks) + 1) * yBreaks
    p +
      xlim(min(data$Date) - 1, max(data$Date) + 1) +
      scale_x_date(limits = c(minDate, maxDate),
                   labels = date_format("%b %y"),
                   date_breaks = "6 months",
                   date_minor_breaks = "1 month") +
      scale_y_continuous(
        breaks = seq(0, yMax, yBreaks),
        expand = c(0,0),
        limits = c(0, yMax)) +
      labs(title = member_plot_title(input$person_choice, data),
           subtitle = paste0("Each bar shows the number of questions from ", input$person_choice,  " in a particular fortnight"),
           x = "Question Date",
           y = "Count"
      ) + 
      theme(panel.background = element_rect(fill = "white", colour = "grey"),
                panel.grid.minor = element_line(colour = "#efefef"),
                panel.grid.major = element_line(colour = "#efefef"),
                axis.title = element_text(family = "Arial", size = 14, colour = "#4f4f4f"),
                axis.text = element_text(family = "Arial", size = 14),
                axis.line = element_line(colour = "grey"),
                plot.title = element_text(size = 17, face = "bold", family = "Arial", colour = "#4f4f4f"),
                plot.subtitle = element_text(size = 12, family = "Arial", colour = "#4f4f4f")
                #axis.ticks.x = element_line(size = 0)
      )
  })

  member_plot_title <- function(selected_member, data) {
    party        = data$MP_Party[ data$Question_MP == selected_member ]
    constituency = data$MP_Constituency[ data$Question_MP == selected_member ]
    if(party == 'Not found') {
      selected_member
    } else {
      paste0(selected_member, ' - ', party, ' - ', constituency)
    }
  }
  
  addPopover(session, "member_plot", "Questions plotted over time",
             content = paste0("This plot shows when the selected MP/peer tabled written questions <br><br> Each bar shows the number of questions tabled by the MP/peer in a particular fortnight - the higher the bar, the more questions."),
             trigger = 'hover', placement = 'left', options = list(container = "body"))
  
  output$member_table <- renderDataTable({
    datatable(
      cbind(' ' = '&oplus;', dfMP()), escape = -2,
      options = list(
        columnDefs = list(
          list(visible = FALSE, targets = c(0, 2, 3, 4, 5, 6)),
          list(orderable = FALSE, className = 'details-control', targets = 1)
        ),
        caption = "Documents contained within the topic:",
        deferRender = TRUE,
        scroller = TRUE,
        searching = FALSE,
        paging = TRUE,
        lengthChange = FALSE,
        pageLength = 10,
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
             content = paste0("This table contains all of the information on the questions asked by this member.<br><br>",
                              "Click on a row to see the corresponding question and answer text."),
             trigger = 'hover', placement = 'top', options = list(container = "body"))
  
  
}
