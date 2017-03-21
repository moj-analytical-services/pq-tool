source(file = "global.R")
############# UI

navbarPage("PQ Text Analysis",
  tabPanel("Similarity",
    fluidRow(
      column(4,
        textInput(inputId = "question", 
                  label = "Search Text",                    
                  value = " To ask Her Majesty's Government whether any complaint has been made to the Judicial Conduct Investigations Office about the conduct of Mrs Justice Hogg in the case of Ellie Butler."
                  )
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
                     
      column(1),
                     
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
             DT::dataTableOutput('dt')
             ),
      column(6,plotOutput("plot")
            )
    )),
  tabPanel("Component 2"),
  tabPanel("Component 3")
)
