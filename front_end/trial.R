library(shiny)

runApp(shinyApp(
  
  ui = shinyUI(
    fluidPage(
      numericInput("number", label = NULL, value = 1, step = 1, min = 1),
      uiOutput("plots")
    )
  ),
  
  server = function(input, output) {
    
    ### This is the function to break the whole data into different blocks for each page
    plotInput <- reactive({
      n_plot <- input$number
      total_data <- lapply(1:n_plot, function(i){rnorm(500)})
      return (list("n_plot"=n_plot, "total_data"=total_data))
    })
    
    ##### Create divs######
    output$plots <- renderUI({
      plot_output_list <- lapply(1:plotInput()$n_plot, function(i) {
        plotname <- paste("plot", i, sep="")
        plotOutput(plotname, height = 280, width = 250)
      })   
      do.call(tagList, plot_output_list)
    })
    
    observe({
      lapply(1:plotInput()$n_plot, function(i){
        output[[paste("plot", i, sep="") ]] <- renderPlot({
          hist(plotInput()$total_data[[i]], main = paste("Histogram Nr", i))
        })
      })
    })
  }
  
))