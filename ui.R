source(file = "global.R")
############# UI

navbarPage("PQ Text Analysis",
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
                  )
            ),

      column(3,
             conditionalPanel(
               condition = "input.question.length > 0",

               # sliderInput(inputId = "q_date_range", 
               #             label = "Question Date Range",
               #             min = min(rawData$Date)-1,
               #             max = max(rawData$Date)+1,
               #             value = c(min(rawData$Date),max(rawData$Date)),
               #             step = 1
               #             )
               dateRangeInput("q_date_range", 
                              label = "Question Date Range",
                              min = min(rawData$Date),
                              max = max(rawData$Date),
                              start = min(rawData$Date),
                              end = max(rawData$Date)
               )
             )

      ),
      
      column(3,
             radioButtons("points", label = 'Number of questions to show',
                          choices = list("10"=10,"25" = 25, "50" = 50, "100" = 100),
                          selected = 10, inline = TRUE)
             #textOutput("test")
      )
    ),
    fluidRow(
      column(6,
             conditionalPanel(
               condition = "input.question.length > 0",
               dataTableOutput("similarity_table")
               )
             ),
      column(6,
             conditionalPanel(
               condition = "input.question.length > 0",
               plotlyOutput("similarity_plot", height = 500)
               )
             )#,
    #fluidRow(
    #  column(12,
    #  conditionalPanel(
    #  condition =
    #    "typeof(input.similarity_table_rows_selected) != 'undefined' && input.similarity_table_rows_selected.length > 0",
    #  dataTableOutput("q_text_table")
    #  ))
    #)
          )),
  tabPanel("Topic Analysis",
           fluidRow(column(3,
             selectizeInput(inputId = "cluster_choice",
             label = "Choose Topic Number:",
             choices = unique(data$Cluster)
             )),
             column(9,
                    conditionalPanel(
                      condition = "input.cluster_choice.length > 0",
                      plotOutput("wordcloud")
                      ))
             ),
           fluidRow(
             conditionalPanel(
               condition = "input.cluster_choice.length > 0",
               plotOutput("cluster_choice")
               )
             ),
             fluidRow(
               conditionalPanel(
                 condition = "input.cluster_choice.length > 0",
                 dataTableOutput("cluster_documents")
                 )
               )
           ),
  tabPanel("Q&A Analysis",
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
  ),
  tabPanel("Data",
           dataTableOutput("data_pane")
  ))
