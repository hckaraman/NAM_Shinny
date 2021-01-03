library(shiny)
library(plotly)
library(shinyWidgets)
options(
  spinner.color = "#0dc5c1",
  spinner.size = 2,
  spinner.type = 1
)

shinyUI(pageWithSidebar(
  headerPanel("NAM Lumped Model"),
  sidebarPanel(
    h3("Upload Data"),
    fluid = TRUE,
    fluidRow(fileInput(
      'file1',
      'Choose CSV File',
      accept = c('text/csv',
                 'text/comma-separated-values,text/plain',
                 '.csv')
    )),
    
    h3("Parameters"),
    tabsetPanel(
      tabPanel(
        "Parameters",
        h5("NAM Parameters"),
        fluidRow(
          column(4, numericInput(
            "area", "Area:", 100, min = 10, max = 1000
          ), ),
          column(
            4,
            numericInput(
              "spinoff",
              "Spinoff:",
              0,
              min = 0,
              max = 1000,
              step = 1
            )
          ),
          # column(6,selectInput("basin", "Select Basin", c("Alihoca","Cakit","Darbogaz"), selected = "Alihoca", multiple = FALSE)),
          column(
            12,
            materialSwitch(
              inputId = "cal",
              label = "Calibration",
              inline = T,
              right = FALSE,
              status = "danger"
            )
          ),
          column(
            4,
            selectInput(
              "method",
              "Method:",
              c("SLSQP", "PSO"),
              selected = "SLSP",
              multiple = FALSE
            )
          ),
          column(
            4,
            selectInput(
              "objective",
              "Objective Function:",
              c("NSE", "KGE", "RMSE", "MAE", "Volume Error", "RMPW", "NSLF"),
              selected = "NSE",
              multiple = FALSE
            )
          ),
          column(4, numericInput(
            "maxiter", "Max iteration:", 3, min = 1, max = 20
          )),
          column(6, numericInput(
            "umax",
            "Umax:",
            min = 0,
            max = 50,
            value = 25
          )),
          column(6, numericInput(
            "lmax",
            "Lmax:",
            min = 0,
            max = 1000,
            value = 500
          )),
          column(6, numericInput(
            "cqof",
            "Cqof:",
            min = 0,
            max = 1,
            value = 0.5
          )),
          column(6, numericInput(
            "ckif",
            "Ckif:",
            min = 200,
            max = 1000,
            value = 600
          )),
          column(6, numericInput(
            "ck12",
            "Ck12:",
            min = 10,
            max = 50,
            value = 30
          )),
          column(6, numericInput(
            "tof",
            "Tof:",
            min = 0,
            max = 1,
            value = 0.5
          )),
          column(6, numericInput(
            "tif",
            "Tif:",
            min = 0,
            max = 1,
            value = 0.5
          )),
          column(6, numericInput(
            "tg",
            "Tg:",
            min = 0,
            max = 1,
            value = 0.5
          )),
          
          column(6, numericInput(
            "ckbf",
            "Ckbf:",
            min = 500,
            max = 5000,
            value = 2500
          )),
          column(
            6,
            numericInput(
              "csnow",
              "Csnow:",
              min = 0,
              max = 4,
              value = 2,
              step = 0.1
            )
          ),
          column(
            6,
            offset = 0,
            numericInput(
              "csnow_melt",
              "Csnowtemp:",
              min = 0,
              max = 4,
              value = 2,
              step = 0.1
            )
          ),
          column(12, downloadButton("downloadData", "Download Results"))
        )
      ),
      tabPanel(
        "Routing",
        h5("Muskingum Cunge Parameters"),
        fluidRow(
          column(4, numericInput(
            "kval", "K:", 3.0, min = 1., max = 1000.
          ), ),
          column(4, numericInput(
            "xval", "X:", 0.5, min = 0.01, max = 50.
          )),
          column(4, numericInput(
            "bedwith", "Bed With:", 5., min = 0.1, max = 1000.
          )),
          column(4, numericInput(
            "sslope", "Side Slope:", 2., min = 0.1, max = 10.
          )),
          column(
            4,
            numericInput(
              "cslope",
              "Channel Slope:",
              0.01,
              min = 0.000001,
              max = 0.5
            )
          ),
          column(
            4,
            numericInput("manning", "Roughness :", 0.04, min = 0.00001, max = 1.)
          ),
          column(
            4,
            numericInput("rlength", "River Length :", 20., min = 0.1, max = 1000.)
          )
          
        )
      )
    )
    
    
    
    
  ),
  mainPanel(
    tabsetPanel(
      type = "tabs",
      tabPanel("Plot Data", shinycssloaders::withSpinner(
        plotlyOutput(outputId = "input_plot", height = "1000px")
      )),
      tabPanel("NAM Results", shinycssloaders::withSpinner(
        plotlyOutput(outputId = "data_plot", height = "800px")
      )),
      tabPanel("Data", shinycssloaders::withSpinner(DT::dataTableOutput("ysummary"))),
      tabPanel(
        "Model Performance",
        shinycssloaders::withSpinner(DT::dataTableOutput("stats", width = "75%"))
      ),
      tabPanel(
        "Model Parameters",
        shinycssloaders::withSpinner(DT::dataTableOutput("parameters", width = "75%"))
      ),
      tabPanel(
        "Flow Duration",
        shinycssloaders::withSpinner(plotlyOutput(outputId = "flowdur", height = "500px"))
      ),
      tabPanel("State Variables", shinycssloaders::withSpinner(plotlyOutput("states", height = "800px"))),
      tabPanel("Routing", shinycssloaders::withSpinner(plotlyOutput("routing", height = "800px")))
      
      
      #plotOutput("main_plot", height = "800px")
      
    )
  )
))
