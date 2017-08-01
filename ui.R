source(file = "global.R")
############# UI

navbarPage("PQ Text Analysis",
           theme = shinytheme("spacelab"),
           footer = column(12, helpText(
               "We would love your feedback on our tool! To complete a quick survey please click",
               a(href="https://www.surveymonkey.co.uk/r/FV9PCT2", target="_blank", "here")
             )
             ),
  tabPanel("Search",
           tags$head(
            includeScript("google-analytics.js"),
            tags$link(rel = "stylesheet", type = "text/css", href = "pq.css")
           ),
           tags$body(onmousemove = "get_point_locations(event)"),
           tags$head(includeScript("pq.js")),
   fluidRow(
     column(8,
              strong("Welcome to the PQ Tool!"),
                p("You can use this tool to search through our database of written PQs. Try typing a couple of keywords 
                  (e.g. Prison Officers) or a new PQ into the search box below and you will get a ranked list of the most 
                  similar past question")
            )),
    fluidRow(
      column(4,
        textInput(inputId = "question",
                  label = "Search Text",
                  width = "100%",
                  value = "",
                  placeholder = "Enter search text here"
                  ),
        bsTooltip("question", "Enter a keyword/phrase to search our PQ database.",
                  "auto", options = list(container = "body"))
            ),

      column(2,
             conditionalPanel(
               condition = "input.question.length > 0",

               dateRangeInput("q_date_range", 
                              label = "Question Date Range",
                              format = "dd-mm-yyyy",
                              min = min(data$Date),
                              max = max(data$Date),
                              start = min(data$Date),
                              end = max(data$Date)
               ),
               bsTooltip("q_date_range", "Choose the time period you wish to search.",
                         "auto", options = list(container = "body"))
             )
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
             )
      )
    ),
  tabPanel("Topic Analysis",
           fluidRow(column(3,
             selectizeInput(inputId = "topic_choice",
             label = "Choose Topic Number:",
             choices = unique(data$Topic)),
             bsTooltip("topic_choice", "Enter a topic number from the previous page. You can do this by selecting a number from the dropdown or simply type it in.",
                       "right", options = list(container = "body"))
             ),
             column(6),
             column(3,actionButton("explanation_button", "What do these topics mean?", class="btn btn-primary"))
             ),
           fluidRow(
             conditionalPanel(
               condition = "input.topic_choice.length > 0",
               column(4,
                      conditionalPanel(
                        condition = "input.topic_choice.length > 0",
                        plotOutput("wordcloud")
                      )),
               column(8,
                      plotOutput("topic_plot")
                      )
               )
             ),
             fluidRow(
               conditionalPanel(
                 condition = "input.topic_choice.length > 0",
                 dataTableOutput("topic_documents")
                 )
               )
           ),

  tabPanel("Member Analysis",
           fluidRow(
             column(2,
            radioButtons(inputId = "member_analysis",
                                    label = "Choose a House:",
                                    choices = c("Lords", "Commons"),
                                    inline = TRUE)
             ),
            column(3,
               uiOutput("member_ui"),
             bsTooltip("person_choice", "Now you have chosen a house, choose an MP/Peer. You can do 
                      this by selecting one from the dropdown or simply typing their name into the box.",
                      "right", options = list(container = "body")))#,
           #column(3, textOutput("member_test"))
           ),
           fluidRow(
             column(4,
                    plotOutput("member_wordcloud")),
             column(8,
             plotOutput("member_plot"))),
           fluidRow(
             dataTableOutput("member_table")
           )
  ))
