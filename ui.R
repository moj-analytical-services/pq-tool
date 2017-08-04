source(file = "global.R")
############# UI

## Conditions
searchTextEntered = "input.question.length > 0"
tableHasRows      = "document.getElementsByClassName('dataTables_empty').length < 1"
topicChosen       = "input.topic_choice.length > 0"

navbarPage("PQ Text Analysis",
           theme = shinytheme("spacelab"),
           footer = column(12, helpText(
             "Love the tool? Hate it? Got a suggestion to improve it? Found a bug? We'd love to hear from you",
             a(href="https://www.surveymonkey.co.uk/r/FV9PCT2", target="_blank", "here")
           )
           ),
           
           ########################### Search Tab
           tabPanel("Search",
                    introjsUI(),
                    tags$head(
                      includeScript("google-analytics.js"),
                      tags$link(rel = "stylesheet", type = "text/css", href = "pq.css")
                    ),
                    tags$body(onmousemove = "get_point_locations(event)"),
                    tags$head(includeScript("pq.js")),
                    fluidRow(
                      column(8,
                             strong("Welcome to the PQ Tool!"),
                             p("You can use this tool to search through our database of written PQs. Try 
                               typing some keywords (e.g. Prison Officers) or a new PQ into the search box 
                               below. You will get a ranked list of the 100 most similar past questions, and 
                               a visualisation showing when they were asked.")
                      )),
                    
                    fluidRow(
                      column(4,
                             introBox(
                             textInput(
                               inputId = "question",
                               label = "Search Text",
                               width = "100%",
                               value = "",
                               placeholder = "Enter search text here"
                             ),
                             data.step = 1,
                             data.intro = "Type some keywords (e.g. Prison Officers) or a new PQ into this box."
                             ),
                             bsTooltip("question",
                                       "Enter a keyword/phrase to search our PQ database.",
                                       "auto",
                                       options = list(container = "body")
                             )
                      ),
                      
                      column(2,
                             conditionalPanel(
                               condition = searchTextEntered,
                               introBox(
                               dateRangeInput(
                                 "q_date_range", 
                                 label = "Question Date Range",
                                 format = "dd-mm-yyyy",
                                 min = min(data$Date),
                                 max = max(data$Date),
                                 start = min(data$Date),
                                 end = max(data$Date)
                               ),
                               data.step = 2,
                               data.position = "right",
                               data.intro = "Pick a range of dates you want to consider (leave this the way it is to search all the questions we have)"
                               ),
                               bsTooltip("q_date_range",
                                         "Choose the time period you wish to search.",
                                         "auto",
                                         options = list(container = "body")
                               )
                             )
                      )
                    ),
                    
                    fluidRow(
                      column(6,
                             conditionalPanel(
                               condition = searchTextEntered,
                               
                               introBox(
                               introBox(
                               dataTableOutput("similarity_table"),
                               data.step = 3,
                               data.position = "right",
                               data.intro = "This table shows the top 100 PQs that are most similar to your search terms. <br> <br>
                               Click on one of the rows to see the question and answer text."),
                               data.step = 6,
                               data.position = "right",
                               data.intro = "The new question you have selected on the graph has been opened in the table.")
                             )
                      ),
                      column(6,
                             conditionalPanel(
                               condition = paste0(tableHasRows, '&&', searchTextEntered),
                               #introBox(
                               introBox(
                               introBox(
                               plotlyOutput("similarity_plot", height = 500),
                               data.step = 4,
                               data.position = "left",
                               data.intro = "This graph plots the PQs from the table and when they were asked. <br> <br> Each point represents a PQ, with the height showing how similar the question is to your search terms (higher = more similar)"),
                               data.step = 5,
                               data.position = "left",
                               data.intro = "The grey line shows an average of parliamentary interest in the search terms. <br> <br>
                               The red point is highlighting the question you previously chose from the table. <br> Try clicking another point to highlight instead.")#,
                               # data.step = 6,
                               # data.position = "left",
                               # data.intro = "")
                      )
                      )
                    )
           ),
           
           ########################### Topic Tab
           tabPanel("Topic Analysis",
                    fluidRow(
                      column(3,
                             selectizeInput(inputId = "topic_choice",
                                            label = "Choose Topic Number:",
                                            choices = unique(data$Topic)),
                             bsTooltip(
                               "topic_choice",
                               "Enter a topic number from the previous page.
              You can do this by selecting a number from
              the dropdown or simply type it ins.",
                               "right",
                               options = list(container = "body")
                             )
                      ),
                      column(1,
                             offset = 7,
                             actionButton(
                               "explanation_button",
                               "What do these topics mean?",
                               class="btn btn-primary"
                             )
                      )
                    ),
                    
                    conditionalPanel(
                      condition = topicChosen,
                      fluidRow(
                        column(6, plotOutput("wordcloud")),
                        column(6, plotOutput("topic_plot"))
                      ),
                      fluidRow(
                        dataTableOutput("topic_documents")
                      )
                    )
           ),
           
           ########################### Member tab
           tabPanel("Member Analysis",
                    fluidRow(
                      column(2,
                             radioButtons(
                               inputId = "member_analysis",
                               label = "Choose a House:",
                               choices = c("Lords", "Commons"),
                               inline = TRUE
                             )
                      ),
                      column(3,
                             uiOutput("member_ui"),
                             bsTooltip(
                               "person_choice",
                               "Now you have chosen a house, choose an MP/Peer. You can do this by
          selecting one from the dropdown or simply typing their name into the box.",
                               "right",
                               options = list(container = "body")
                             )
                      )
                    ),
                    
                    fluidRow(
                      column(4, plotOutput("member_wordcloud")),
                      column(8, plotOutput("member_plot"))
                    ),
                    
                    fluidRow(dataTableOutput("member_table"))
           ))
