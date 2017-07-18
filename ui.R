source(file = "global.R")
############# UI

navbarPage("PQ Text Analysis",
           theme = shinytheme("spacelab"),
           footer = column(12, helpText(
               "We would love your feedback on our tool! To complete a quick survey please click",
               a(href="https://www.surveymonkey.co.uk/r/FV9PCT2", target="_blank", "here")
             )
             ),
  tabPanel("Similarity",
           tags$head(includeScript("google-analytics.js")),
    fluidRow(
      column(6,
        textInput(inputId = "question",
                  label = "Search Text",
                  width = "100%",
                  value = "Enter search text here"
                  ),
        bsTooltip("question", "Enter a keyword/phrase to search our PQ database.",
                  "auto", options = list(container = "body"))
            ),

      column(3,
             conditionalPanel(
               condition = "input.question.length > 0",

               dateRangeInput("q_date_range", 
                              label = "Question Date Range",
                              format = "dd-mm-yyyy",
                              min = min(rawData$Date),
                              max = max(rawData$Date),
                              start = min(rawData$Date),
                              end = max(rawData$Date)
               ),
               bsTooltip("q_date_range", "Choose the time period you wish to search.",
                         "auto", options = list(container = "body"))
             )

      # ),
      # 
      # column(3,
      #        conditionalPanel(
      #          condition = "input.question.length > 0",
      #          radioButtons("points", label = 'Number of questions to show',
      #                       choices = list("10"=10,"25" = 25, "50" = 50, "100" = 100),
      #                       selected = 10, inline = TRUE
      #          ),
      #          bsTooltip("points", "Choose the number of results to show.", placement = "top", options = list(container = "body"))
      #          #textOutput("test")
      #        )
      )
    ),
    fluidRow(
      column(6,
             conditionalPanel(
               condition = "input.question.length > 0",
               dataTableOutput("similarity_table")#,
               # bsTooltip("similarity_table", "This table shows the past PQs that are most similar to your search (with the most similar questions are at the top). </br> </br> You can click any row to see the question text, or reorder the results by clicking on the column headings. </br> </br> All the questions in our database have been grouped into topics by an algorithm and given Topic numbers. Try entering one of the topic numbers you see here into the box at the top of the \\'Topic Analysis\\' page.",
               #           "right", options = list(container = "body"))
               )
             ),
      column(6,
             conditionalPanel(
               condition = "input.question.length > 0",
               plotlyOutput("similarity_plot", height = 500)
               )
             )
      )
    ),
  tabPanel("Topic Analysis",
           fluidRow(column(3,
             selectizeInput(inputId = "topic_choice",
             label = "Choose Topic Number:",
             choices = unique(data$Topic)
             )),
             column(9,
                    conditionalPanel(
                      condition = "input.topic_choice.length > 0",
                      plotOutput("wordcloud")
                      ))
             ),
           fluidRow(
             conditionalPanel(
               condition = "input.topic_choice.length > 0",
               plotOutput("topic_choice")
               )
             ),
             fluidRow(
               conditionalPanel(
                 condition = "input.topic_choice.length > 0",
                 dataTableOutput("topic_documents")
                 )
               )
           ),
  tabPanel("MP Analysis",
           sidebarPanel(
             wellPanel(radioButtons(inputId = "q_analysis",
                                    label = "Choose a House",
                                    choices = c("Lords", "Commons"),
                                    inline = TRUE)
             ),
             wellPanel(
               uiOutput("q_analysis_ui")
             )
           ),
           mainPanel(
             plotOutput("q_analysis_plot"),
             dataTableOutput("q_analysis_table")
           )
  ))
