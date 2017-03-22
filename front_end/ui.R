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
      column(6,plotOutput("x2", height = 500)
            )
    )),
  tabPanel("Cluster",
           fluidRow(
             column(12,
             selectInput("x3", "Choose Cluster:",
                         choices = unique(d$Cluster))
             )
           ),
           fluidRow(
             column(12,
             plotOutput('x4')
             )
           ),
           fluidRow(
             column(12,
             dataTableOutput("x3")
             )
           )
           ),
  
  tabPanel("Q&A Analysis",
           sidebarPanel(
             selectInput(inputId ="x6",
                         "Choose a Constituency:",
                         choices = unique(d$MP_Constituency))#,
             #selectInput("x7", "Choose an MP:",
             #            choices = unique(MPChoice()))
           ),
           mainPanel(
             plotOutput("x8")
           )
  ),
  tabPanel("Data",
           dataTableOutput('x5')
           )
)
