
shinyUI(fluidPage(

  # Application title
  titlePanel(div("Presentation of error", align = "center"), windowTitle = "Presentation of error"),
  # Show a plot of the generated distribution
  mainPanel(width = 12,
            column(4,

                   DT::dataTableOutput("tableauError"),

                   hr(),
                   fluidRow(
                     column(6, div(h4(textOutput("mean_inf_error")), align = "center")),
                     column(6, div(h4(textOutput("mean_sup_error")), align = "center"))
                   ),

                   hr(),
                   div(downloadButton('downloadData', 'Download data'), align = "center"),

                   hr(),
                   fluidRow(
                     column(6,
                            selectInput("Reports", "Reports to export : ",unique(dtaUseByShiny$dayType), multiple = TRUE)),
                     column(6, br(), downloadButton("downloadReport", "Export"))
                   )
            ),
            column(8,uiOutput("plots"))
  )
))
