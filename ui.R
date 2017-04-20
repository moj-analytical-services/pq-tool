source(file = "global.R")
############# UI

navbarPage("PQ Text Analysis",
  tabPanel("Similarity",
    fluidRow(
      column(6,
        textInput(inputId = "question", 
                  label = "Search Text",
                  width = '100%',
                  value = " To ask Her Majesty's Government whether any complaint has been made to the Judicial Conduct Investigations Office about the conduct of Mrs Justice Hogg in the case of Ellie Butler."
                  )#,
        #actionButton("goButton", "Search")
            ),
                   
      column(3,
        sliderInput(inputId = "q_date_range", 
                    label = "Question Date Range", 
                    min = min(rawData$Date)-1, 
                    max = max(rawData$Date)+1,
                    value = c(min(rawData$Date),max(rawData$Date)),
                    step = 1
                    )
            )
                     
      #column(3,
      #      sliderInput(inputId = "a_date_range",   
      #                  label = "Answer Date Range", 
      #                  min = min(rawData$Date)-1, 
      #                  value = c(min(rawData$Date),max(rawData$Date)),
      #                  max = max(rawData$Date)+1,
      #                  step = 1
      #                  )
      #      )
      ),
    fluidRow(
      column(6,
             dataTableOutput('similarity_table')
             ),
      column(6,
             plotlyOutput("similarity_plot", height = 500)
            ),
    fluidRow(conditionalPanel(
      condition = "input.similarity_table_rows_selected.length > 0",
      dataTableOutput('q_text_table')
      )
    ))),
  tabPanel("Cluster",
           fluidRow(column(3,
             selectizeInput(inputId = "cluster_choice",
             label = "Choose Cluster:",
             choices = unique(data$Cluster)
             )),
             column(9,
               plotOutput('wordcloud')
               )),
           fluidRow(
               plotOutput('cluster_choice')
               ),
             fluidRow(
               dataTableOutput("cluster_documents")
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
             dataTableOutput('q_analysis_table')
           )
  ),
  tabPanel("Data",
           dataTableOutput('data_pane')
  ))
