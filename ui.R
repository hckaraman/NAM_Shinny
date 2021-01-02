library(shiny)
library(plotly)
library(shinyWidgets)
options(spinner.color="#0dc5c1",spinner.size=2,spinner.type = 1)

shinyUI(pageWithSidebar(
  headerPanel("NAM Lumped Model"),
  sidebarPanel(h3("Upload Data"),fluidRow(fileInput('file1', 'Choose CSV File',
                                                    accept=c('text/csv', 
                                                             'text/comma-separated-values,text/plain', 
                                                             '.csv'))),
    
               h3("NAM Parameters"),fluidRow(
    column(4,numericInput("area", "Area:", 100, min = 10, max = 1000),),
    # column(6,selectInput("basin", "Select Basin", c("Alihoca","Cakit","Darbogaz"), selected = "Alihoca", multiple = FALSE)),
    column(12,materialSwitch(inputId = "cal", label = "Calibration", inline = T,right = FALSE,status = "danger")),
    column(4,selectInput("method", "Method:",
                         c("SLSQP","PSO"), selected = "SLSP", multiple = FALSE)),
    column(4,selectInput("objective", "Objective Function:",
                         c("NSE","KGE","RMSE","MAE","Volume Error","RMPW","NSLF"), selected = "NSE", multiple = FALSE)),
    column(4,numericInput("maxiter", "Max iteration:", 3, min = 1, max = 20)),
    column(6,sliderInput("umax", "Umax:",
                         min = 0, max = 50, value = 25)),
    column(6,sliderInput("lmax", "Lmax:",
                         min = 0, max = 1000, value = 500)),
    column(6,sliderInput("cqof", "Cqof:",
                           min = 0, max = 1, value = 0.5)),
    column(6,sliderInput("ckif", "Ckif:",
                           min = 200, max = 1000, value = 600)),
    column(6,sliderInput("ck12", "Ck12:",
                           min = 10, max = 50, value = 30)),
    column(6,sliderInput("tof", "Tof:",
                           min = 0, max = 1, value = 0.5
               )),
    column(6,sliderInput("tif", "Tif:",
                           min = 0, max = 1, value = 0.5
               )),
    column(6,sliderInput("tg", "Tg:",
                           min = 0, max = 1, value = 0.5
               )),
               
    column(6,sliderInput("ckbf", "Ckbf:",
                           min = 500, max =5000, value = 2500
               )),
    column(6,sliderInput("csnow", "Csnow:",
                           min = 0, max = 4, value = 2,step = 0.25
               )),
    column(6,downloadButton("downloadData", "Download Results"))
    )),
  mainPanel(
    tabsetPanel(type = "tabs",
                tabPanel("Plot Data", shinycssloaders::withSpinner(plotlyOutput(outputId ="input_plot", height = "1000px"))),
                tabPanel("NAM Results", shinycssloaders::withSpinner(plotlyOutput(outputId ="data_plot", height = "800px"))),
                tabPanel("Data", DT::dataTableOutput("ysummary")),
                tabPanel("Model Performance", DT::dataTableOutput("stats",width = "75%")),
                tabPanel("Model Parameters", DT::dataTableOutput("parameters",width = "75%")),
                tabPanel("Flow Duration", plotlyOutput(outputId ="flowdur", height = "500px")),
                tabPanel("State Variables", plotlyOutput("states",height = "800px"))
                
                
                #plotOutput("main_plot", height = "800px")
                
    )
  )))