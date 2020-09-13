library(shiny)
library(shinyFiles)
library(RSQLite)
library(stringr)
library(ggplot2)
library('zoo')
library(DT)
library(sf)
require("rgdal")
library(tidyverse)
library(raster)
library(reticulate)
library(plotly)
library(vroom)
library(hrbrthemes)

use_python(python = "C:\\Users\\cagri\\AppData\\Local\\Programs\\Python\\Python38\\python.exe", required = TRUE)
# use_python(python = "/usr/bin/python3.8", required = TRUE)

# py_config()
setwd('./Nam')
source_python("./nam_pso.py")
# print(getwd())

shinyServer(function(input, output, session) {
  
  
  data <- reactive({ 
    req(input$file1) ## ?req #  require that the input is available
    
    inFile <- input$file1 
    
    # tested with a following dataset: write.csv(mtcars, "mtcars.csv")
    # and                              write.csv(iris, "iris.csv")
    df <- read.csv(inFile$datapath)

    
    results <- list()
    results$df <- df
    
    x <- c('./Data/',input$file1$name)
    file <- paste(x,collapse = '')
    write.csv(df,file,row.names=FALSE)
    
    results$path <- input$file1$name
    
    return(results)
  })

  
  newData <- reactive({
    tt <- data()
    filename <- tt[[2]]
    df <- tt[[1]]
    
    params <- c(input$umax, input$lmax, input$cqof, input$ckif
                ,input$ck12, input$tof, input$tif, input$tg
                , input$ckbf,input$csnow, 2)
    # print(input$objective)
    temp <- run(input$area,params,getwd(),filename,input$cal,input$method,input$objective,input$maxiter) 
    temp[[1]]$date <- as.Date(row.names(temp[[1]]), "%Y-%m-%d")
    temp
  })
  
  
  output$input_plot <- renderPlotly({
    df <- data()[[1]]
    df$Date <- as.Date(df$Date, "%m/%d/%Y")
    
    
    q1 <- ggplot(df)  + 
      geom_bar(aes(x=Date, y=P),stat="identity", fill="tan1", colour="#009E73")+
     ylab("Precipitation (mm)")

    q2 <- ggplot(df)  + 
      geom_line(aes(x=Date, y=Q),stat="identity", fill="tan1", colour="#56B4E9")+
      scale_y_continuous("Discharge (3/s)") 
    
    q3 <- ggplot(df)  + 
      geom_line(aes(x=Date, y=Temp),stat="identity", fill="tan1" , colour="#D55E00")+
      scale_y_continuous("Mean Temperature (°C)") 
    
    q4 <- ggplot(df)  + 
      geom_line(aes(x=Date, y=E),stat="identity", fill="tan1",colour = '#69b3a2')+
      scale_y_continuous("Pot. Evapotranspration (mm)") 
    
    
    ply1 <- ggplotly(q1)
    ply2 <- ggplotly(q2)
    ply3 <- ggplotly(q3)
    ply4 <- ggplotly(q4)
    
    subplot(ply1, ply2,ply3,ply4, nrows = 4,shareX = T, titleY = TRUE,margin = 0.02)

  })
  
  output$data_plot <- renderPlotly({
    
    df <- newData()[[1]]
    
    pt <- ggplot(df, aes(x=date)) + 
      geom_line(aes(y = Q), color = "darkred") + 
      geom_line(aes(y = Qsim), color="steelblue", linetype="twodash") +
      xlab("Date") + ylab("Discharge , m3/s") 
    
    fig <- ggplotly(pt)
    fig
    
  })
  
  output$ysummary = DT::renderDataTable({
    df <- newData()[[1]]
    rownames(df) <- df$date
    df
  })
  
  output$parameters = DT::renderDataTable({
    df <- newData()[[2]]
    par <- c("Umax","Lmax","CQOF","CKIF","CK12","TOF","TIF","TG","CKBF","Csnow","Snowtemp")
    par_v <- c("Max W.C in the surface storage","Max W.C in root zone storage","Overland flow runoff coefficient","Time Constant for Interflow","Time constant for routing overland flow","Root zone treshold value for overland flow","Root zone treshold value for inter flow","Root zone treshold value for groundwater recharge","Time constant for routing base flow","Degree day coefficient","Snow melt temp")
    df <- data.frame(par,par_v,df)
    names(df) <- c("Parameter","Description","Value")
    df
  })
  
  output$stats = DT::renderDataTable({
    df <- newData()[[3]]
    metric <- c()
    value <- c()
    for(i in 1:length(df)){
      
      metric <- c(metric, df[[i]][[1]])
      value <- c(value, df[[i]][[2]])
      
    }
    
    par <- c("Agreement Index (d) developed by Willmott (1981)","BIAS","Correlation Coefficient","Covariance ","Decomposed MSE developed by Kobayashi and Salam (2000","Kling-Gupta Efficiency","Logarithmic probability distribution","Log Nash-Sutcliffe model efficiency","Mean Absolute Error","Mean Squared Error","Nash-Sutcliffe model efficinecy","Procentual Bias","Root Mean Squared Error","Relative Root Mean Squared Error","Coefficient of Determination","RMSE-observations standard deviation ratio","Volume Error (Ve)")
    df_stat <- data.frame(par, value) 
    names(df_stat) <- c("Metric","Value")
    
    df_stat
  })
  
  output$flowdur <- renderPlotly({
    
    df <- newData()[[4]]
    
    pt <- ggplot(df) + 
      geom_line(aes(x=Qsim_x,y = Qsim_y), color = "darkred") + 
      geom_line(aes(x=Qobs_x,y = Qobs_y), color="steelblue", linetype="twodash") +
      xlab("Percentage Exceedence (%)") + ylab("Discharge m$^3$/s") 
    
    fig <- ggplotly(pt)
    fig
    
  })
  
  output$states <- renderPlotly({
    
    df <- newData()[[5]]
    df$Date <- as.Date(df$Date,"%Y-%m-%d")
    
    fig1 <- plot_ly(df, x = ~Date, y = ~u)
    fig1 <- fig1 %>% add_lines(name = ~"u") %>% layout(
        xaxis = list(title = "Date"),
        yaxis = list(title = "U"))
    fig2 <- plot_ly(df, x = ~Date, y = ~l)
    fig2 <- fig2 %>% add_lines(name = ~"l") %>% layout(
      xaxis = list(title = "Date"),
      yaxis = list(title = "L"))
    fig3 <- plot_ly(df, x = ~Date, y = ~bf)
    fig3 <- fig3 %>% add_lines(name = ~"bf") %>% layout(
      xaxis = list(title = "Date"),
      yaxis = list(title = "BF"))
    fig4 <- plot_ly(df, x = ~Date, y = ~if1)
    fig4 <- fig4 %>% add_lines(name = ~"if1") %>% layout(
      xaxis = list(title = "Date"),
      yaxis = list(title = "IF1"))
    fig <- subplot(fig1, fig2,fig3,fig4)
    fig1 <- plot_ly(df, x = ~Date, y = ~if2)
    fig1 <- fig1 %>% add_lines(name = ~"if2")
    fig2 <- plot_ly(df, x = ~Date, y = ~of1)
    fig2 <- fig2 %>% add_lines(name = ~"of1")
    fig3 <- plot_ly(df, x = ~Date, y = ~of2)
    fig3 <- fig3 %>% add_lines(name = ~"of2")
    fig4 <- plot_ly(df, x = ~Date, y = ~snow)
    fig4 <- fig4 %>% add_lines(name = ~"csnow")
    fig1 <- subplot(fig1, fig2,fig3,fig4)
    figg <- subplot(fig,fig1,nrows=2)
    figg
  })
  
  # observe({
  #   x <- input$cal
  #   if (x == T ){
  #     value <- newData()[[2]]
  #     updateSliderInput(session, "umax",value = value[1])
  #     updateSliderInput(session, "lmax",value = value[2])
  #     updateSliderInput(session, "cqof",value = value[3])
  #     updateSliderInput(session, "ckif",value = value[4])
  #     updateSliderInput(session, "ck12",value = value[5])
  #   }
  # })
  
  
})

plotList <- function(nplots) {
  lapply(seq_len(nplots), function(x) plot_ly())
}
s1 <- subplot(plotList(6), nrows = 2, shareX = TRUE, shareY = TRUE)



