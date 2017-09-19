source(file = "global.R")
############# UI

## Conditions
searchTextEntered = "input.question.length > 0"
tableHasRows      = "document.getElementsByClassName('dataTables_empty').length < 1"
topicChosen       = "input.topic_choice.length > 0"

navbarPage("MoJ Parliamentary Analysis Tool",
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
                             strong("Welcome to the Parliamentary Analysis Tool!"),
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
                      
                      column(3,
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
                               data.intro = "Pick a range of dates you want to consider (leave this alone to search all the questions we have)"
                               ),
                               bsTooltip("q_date_range",
                                         "Choose the time period you wish to search.",
                                         "auto",
                                         options = list(container = "body")
                               )
                             )
                      ),
                      column(2,
                             offset = 3,
                             actionButton(
                               "tutorial_button",
                               "Click here for a quick tour",
                               class="btn btn-primary"
                             ),
                             bsTooltip("tutorial_button",
                                "If this is your first time using the tool, click here to complete a short, interactive tutorial",
                                "auto")
                             )
                    ),
                    
                    fluidRow(
                      column(6,
                             conditionalPanel(
                               condition = searchTextEntered,
                               introBox(
                               introBox(
                               introBox(
                               introBox(
                               dataTableOutput("similarity_table"),
                               data.step = 3,
                               data.position = "right",
                               data.intro = "This table shows the top 100 PQs that are most similar to your search terms. <br> <br>
                               Click on one of the rows to see the question and answer text."),
                               data.step = 6,
                               data.position = "right",
                               data.intro = "The question you selected on the graph has now been opened in the table."),
                               data.step = 7,
                               data.position = "right",
                               data.intro = "You can see all the questions asked by this MP/peer by clicking the 'See all questions asked by' button. 
                               <br> <br> To continue, try it!"),
                               data.step = 12,
                               data.position = "right",
                               data.intro = "All the questions in our database have been grouped into topics by an algorithm. These topics have been given a
                               number and three 'Topic Keywords' to give an idea of what the topic is about.<br> <br> Click the 'View topic' button to look
                               at all the questions in this topic.")
                             )
                      ),
                      column(6,
                             conditionalPanel(
                               condition = paste0(tableHasRows, '&&', searchTextEntered),
                               introBox(
                               introBox(
                               plotlyOutput("similarity_plot", height = 500),
                               data.step = 4,
                               data.position = "left",
                               data.intro = "This graph plots the PQs from the table and when they were asked. <br> <br> Each 
                               point represents a PQ, with the height showing how similar the question is to your search terms (higher = more similar)"),
                               data.step = 5,
                               data.position = "left",
                               data.intro = "The grey line shows an average of parliamentary interest in the search terms. <br> <br>
                               The red point is highlighting the question you previously chose from the table. <br><br> Try 
                               clicking another point to highlight instead.")
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
              the dropdown or simply type it in.",
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
                        column(4, 
                               introBox(
                               plotOutput("wordcloud"),
                               data.step = 13,
                               data.position = "right",
                               data.intro = "This wordcloud shows the words that are most important
                               in this topic.<br><br> The bigger the word, the more important it is.")
                               ),
                        column(8, 
                               introBox(
                                 plotOutput("topic_plot"),
                                 data.step = 14, 
                                 data.position = "left",
                                 data.intro = "This plot shows when questions in the topic were asked. <br> Each bar 
                                 shows the number of questions asked in a particular fortnight - the higher the bar, 
                                 the more questions from that topic.")
                      )),
                      fluidRow(
                        introBox(
                        introBox(
                        dataTableOutput("topic_documents"),
                        data.step = 15,
                        data.position = "right",
                        data.intro = "This table contains all of the information on the questions asked on this topic.<br><br>
                        Click on a row to see the corresponding question and answer text."),
                        data.step = 16,
                        data.position = "top",
                        data.intro = "That's it! You have made it to the end of the tutorial! <br><br> We hope this was useful. If you have any
                        feedback on this tutorial, or the tool in general, please see the link at the bottom of the page.")
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
                      ),
                      column(7,
                             htmlOutput("memberlink")
                      )
                    ),
                    
                    fluidRow(
                      column(4, 
                             introBox(
                             plotOutput("member_wordcloud"),
                             data.step = 8,
                             data.position = "right",
                             data.intro = "This wordcloud shows the words that are most important in the questions
                             asked by this member.<br><br> The bigger the word, the more important it is.")
                              ),
                      column(8,
                             introBox(
                             plotOutput("member_plot"),
                             data.step = 9,
                             data.position = "left",
                             data.intro = "This plot shows when questions were asked by the selected member. <br><br>
                             The x axis shows the date when questions were asked and the y axis shows the count of questions asked on that date.")
                             )
                    ),
                    
                    fluidRow(
                       introBox(
                       introBox(
                        dataTableOutput("member_table"),
                        data.step = 10,
                        data.position = "top",
                        data.intro = "This table contains all of the information on the questions asked by this member.<br><br>
                        Click on a row to see the corresponding question and answer text."),
                      data.step = 11,
                      data.position = "top",
                      data.intro = "You can now navigate back to the first page by clicking on the 'Back to Search' button.")
           )
           )
)
