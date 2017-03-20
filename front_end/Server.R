# Define R_date date type - to read in Long Date format in csv
setAs("character", "R_date", function(from) as.Date(from, "%d %B %Y"))
setClass('R_date')
myColClasses = c("Date" = "R_date",
                 "Answer_Date" = "R_date")

# Import similarity score function simQuery()
source("/Users/admin/Documents/PQtools/Front End/lsaPreamble.R")

# Shiny App
library(shiny)
library(DT)

rawData = (read.csv('/Users/admin/Documents/PQtools/Data/MoJallPQsforTableau.csv', colClasses = myColClasses))
d = data.frame(rawData)

############# UI
ui <- fluidPage(
  shinyUI(navbarPage("PQ Text Analysis",
                     tabPanel("Component 1"),
                     tabPanel("Component 2"),
                     tabPanel("Component 3"))),
  #titlePanel("PQ Text Analysis"),
  fluidRow(
    column(4,
      textInput(inputId = "question", 
              label = "Search Text",
              value = "Insert Question Here")
    ),
  
    column(3,
      sliderInput(inputId = "q_date_range", 
              label = "Question Date Range", 
              min = min(rawData$Date), 
              max = max(rawData$Date),
              value = c(min(rawData$Date),max(rawData$Date))
              )
    ),
    
    column(1),
    
    column(3,
       sliderInput(inputId = "a_date_range", 
              label = "Answer Date Range", 
              min = min(rawData$Date), 
              max = max(rawData$Date),
              value = c(min(rawData$Date),max(rawData$Date))
           )
    )
  ),
  fluidRow(
    column(6,DT::dataTableOutput('dt')
    ),
    column(6,plotOutput("plot")),
  
  plotOutput("plt")
  
  )
)

############### Server

server <- function(input, output) {
  
  #Filter() = reactive({
  #tableDF = tableDF[tableDF$d.Date > input$q_date_range[1] & tableDF$d.Date < input$q_date_range[2]]
  #})
  
  

  
  #output$plot <- renderPlot({    
  #  c(tableDF$d.Date, similarityScore())
  #
  #})
  
  filt_data = function(Data, Bound){
  return(reactive({Data >= Bound[1] & Data <= Bound[2]}))
  }
  filt_q_date = filt_data(d$Date, input$q_date_range)
  filt_a_date = filt_data(d$Answer_Date, input$a_date_range)
  
  data_frame = reactive({
    rawData[filt_q_date]
  })
  similarity_score = reactive({
    simQuery(input$question, data_frame$Question_Text)
  })
  data_frame2 = 
    cbind2(data_frame, similarity_score)
  
  
  
  output$dt <- DT::renderDataTable({
    
    DT::datatable(data = data_frame2,
      colnames = c("Document #", "Question Date","Answer Date", "Cluster"),
      class = 'display',
      width = 25,
      #filter = 'top',
      options = list(deferRender = TRUE,
                     scrollY = 400,
                     scroller = TRUE,
                     searching = FALSE,
                     paging = FALSE)
    )
  })
  
}

shinyApp(ui = ui, server = server)
