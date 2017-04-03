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
                  ),
        actionButton("goButton", "Search")
            ),
                   
      column(3,
        sliderInput(inputId = "q_date_range", 
                    label = "Question Date Range", 
                    min = min(rawData$Date), 
                    max = max(rawData$Date),
                    value = c(min(rawData$Date),max(rawData$Date)),
                    step = NULL
                    )
            ),
                     
      column(3,
            sliderInput(inputId = "a_date_range",   
                        label = "Answer Date Range", 
                        min = min(rawData$Date), 
                        max = max(rawData$Date),
                        value = c(min(rawData$Date),max(rawData$Date)),
                        step = NULL
                        )
            )
      ),
    fluidRow(
      column(6,
             dataTableOutput('x1')
             ),
      column(6,
             plotlyOutput("x2", height = 500)
            )
    )),
  tabPanel("Cluster",
           fluidRow(column(3,
             selectizeInput(inputId = "x3",
             label = "Choose Cluster:",
             choices = unique(d$Cluster)
             )),
             column(9,
               plotOutput('wordcloud')
               )),
           fluidRow(
               plotOutput('x3')
               ),
             fluidRow(
               dataTableOutput("x4")
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
           dataTableOutput('x6')
  ))
