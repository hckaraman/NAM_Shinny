library(shiny)
library(ggplot2)
library(DT)
library(tidyverse)
library(reticulate)
library(plotly)
library(openxlsx)
library(vroom)
library(shinycssloaders)



use_python(python = "/mnt/s/Hypnotise/Scripts/venv/bin/python", required = TRUE)

# py_config()
setwd('./Nam')
source_python("./nam_pso.py")
# print(getwd())

shinyServer(function(input, output, session) {
  data <- reactive({
    req(input$file1) ## ?req #  require that the input is available
    f <-
      list.files(
        './Data/',
        include.dirs = F,
        full.names = T,
        recursive = T
      )
    file.remove(f)
    inFile <- input$file1
    
    # tested with a following dataset: write.csv(mtcars, "mtcars.csv")
    # and                              write.csv(iris, "iris.csv")
    # df <- read.csv(inFile$datapath)
    df <- vroom(inFile$datapath)
    
    # Check NA values in the data
    
    na_values <- colSums(is.na(df))
    na_names <- names(df)
    dialog_text <- ""
    
    # temp <- data.frame(nam_)
    
    for (i in 1:length(na_values)) {
      if (na_values[i][[1]] != 0) {
        dialog_text <-
          paste(dialog_text,
                "<br>",
                paste(
                  names(na_values[i][1]) ,
                  " data has " ,
                  na_values[i][[1]] ,
                  " NA values"
                ),
                sep = "")
      }
    }
    
    # if (nchar(dialog_text) != 0) {
    #   dialog_text <-
    #     paste(dialog_text, "<br>", "No data values has been set to zero!")
    #   temp <-  df$Q
    #   df[is.na(df)] <- 0 # set no data values to zero
    #   df$Q <- temp
    #   showModal(modalDialog(HTML(dialog_text),
    #                         easyClose = TRUE))
    # } else {
    #   showModal(modalDialog(HTML("Data is free of NA values, yay!"),
    #                         easyClose = TRUE))
    # }
    
    results <- list()
    results$df <- df
    
    x <- c('./Data/', input$file1$name)
    file <- paste(x, collapse = '')
    write.csv(df, file, row.names = FALSE)
    
    results$path <- input$file1$name
    
    return(results)
  })
  
  
  newData <- reactive({
    tt <- data()
    filename <- tt[[2]]
    df <- tt[[1]]
    
    params <- c(
      input$umax,
      input$lmax,
      input$cqof,
      input$ckif
      ,
      input$ck12,
      input$tof,
      input$tif,
      input$tg
      ,
      input$ckbf,
      input$csnow,
      input$csnow_melt
    )
    # print(input$objective)
    
    ## Results
    temp <-
      run(
        input$area,
        params,
        getwd(),
        filename,
        input$cal,
        input$method,
        input$objective,
        input$maxiter,
        input$spinoff
      )
    temp[[1]]$date <- as.Date(row.names(temp[[1]]), "%Y-%m-%d")
    
    
    ### parameters
    par <-
      c(
        "Umax",
        "Lmax",
        "CQOF",
        "CKIF",
        "CK12",
        "TOF",
        "TIF",
        "TG",
        "CKBF",
        "Csnow",
        "Snowtemp"
      )
    par_v <-
      c(
        "Max W.C in the surface storage",
        "Max W.C in root zone storage",
        "Overland flow runoff coefficient",
        "Time Constant for Interflow",
        "Time constant for routing overland flow",
        "Root zone treshold value for overland flow",
        "Root zone treshold value for inter flow",
        "Root zone treshold value for groundwater recharge",
        "Time constant for routing base flow",
        "Degree day coefficient",
        "Snow melt temp"
      )
    df <- data.frame(par, par_v, temp[[2]])
    names(df) <- c("Parameter", "Description", "Value")
    
    
    
    ### Stats
    tt <- temp[[3]]
    metric <- c()
    value <- c()
    for (i in 1:length(temp[[3]])) {
      metric <- c(metric, tt[[i]][[1]])
      value <- c(value, tt[[i]][[2]])
      
    }
    
    par <-
      c(
        "Agreement Index (d) developed by Willmott (1981)",
        "BIAS",
        "Correlation Coefficient",
        "Covariance ",
        "Decomposed MSE developed by Kobayashi and Salam (2000",
        "Kling-Gupta Efficiency",
        "Logarithmic probability distribution",
        "Log Nash-Sutcliffe model efficiency",
        "Mean Absolute Error",
        "Mean Squared Error",
        "Nash-Sutcliffe model efficinecy",
        "Procentual Bias",
        "Root Mean Squared Error",
        "Relative Root Mean Squared Error",
        "Coefficient of Determination",
        "RMSE-observations standard deviation ratio",
        "Volume Error (Ve)"
      )
    df_stat <- data.frame(par, value)
    names(df_stat) <- c("Metric", "Value")
    
    ## Flow duration
    
    df_flow <- temp[[4]]
    
    
    ### States
    
    df_states <- temp[[5]]
    df_states$Date <- as.Date(df_states$Date, "%Y-%m-%d")
    
    list_of_datasets <-
      list(
        "NAM_Results" = temp[[1]],
        "NAM_Parameters" = df,
        "Model_Performance" = df_stat,
        "Flow_Duration" = df_flow,
        "States" = df_states
      )
    write.xlsx(list_of_datasets, file = './Data/Results.xlsx')
    
    temp
    
    
    
  })
  
  
  output$input_plot <- renderPlotly({
    df <- data()[[1]]
    # df$Date <- as.Date(df$Date, "%m/%d/%Y")
    df$Date <- as.Date(df$Date, "%d/%m/%Y")
    
    
    
    

    
    q1 <- ggplot(df)  +
      geom_bar(
        aes(x = Date, y = P),
        stat = "identity",
        fill = "tan1",
        colour = "#009E73"
      ) +
      ylab("Precipitation (mm)")
    
    q2 <- ggplot(df)  +
      geom_line(
        aes(x = Date, y = Q),
        stat = "identity",
        fill = "tan1",
        colour = "#56B4E9"
      ) +
      scale_y_continuous("Discharge (3/s)")
    
    q3 <- ggplot(df)  +
      geom_line(
        aes(x = Date, y = Temp),
        stat = "identity",
        fill = "tan1" ,
        colour = "#D55E00"
      ) +
      scale_y_continuous("Mean Temperature (°C)")
    
    q4 <- ggplot(df)  +
      geom_line(
        aes(x = Date, y = E),
        stat = "identity",
        fill = "tan1",
        colour = '#69b3a2'
      ) +
      scale_y_continuous("Pot. Evapotranspration (mm)")
    
    
    ply1 <- ggplotly(q1)
    ply2 <- ggplotly(q2)
    ply3 <- ggplotly(q3)
    ply4 <- ggplotly(q4)
    
    subplot(
      ply1,
      ply2,
      ply3,
      ply4,
      nrows = 4,
      shareX = T,
      titleY = TRUE,
      margin = 0.02
    )
    
  })
  
  output$data_plot <- renderPlotly({
    df <- newData()[[1]]
    
    df_par <- newData()[[2]]
    
    # Update input parameters
    pars <- c("umax","lmax","cqof","ckif","ck12","tof","tif","tg","ckbf","csnow","csnow_melt")
    
    for (i in 1:length(pars)) {
      updateNumericInput(session, pars[i], value = round(df_par[[i]],2))
    }
    
    # Update switch
    updateMaterialSwitch(session, 'cal', value = F)
    
    pt <- ggplot(df, aes(x = date)) +
      geom_line(aes(y = Q), color = "darkred") +
      geom_line(aes(y = Qsim), color = "steelblue", linetype = "twodash") +
      xlab("Date") + ylab("Discharge , m3/s")
    
    fig <- ggplotly(pt)
    fig
    
  })
  
  output$ysummary = DT::renderDataTable({
    df <- newData()[[1]]
    rownames(df) <- df$date
    df
  }, options = list(pageLength = 25))
  
  output$parameters = DT::renderDataTable({
    df <- newData()[[2]]
    par <-
      c(
        "Umax",
        "Lmax",
        "CQOF",
        "CKIF",
        "CK12",
        "TOF",
        "TIF",
        "TG",
        "CKBF",
        "Csnow",
        "Snowtemp"
      )
    par_v <-
      c(
        "Max W.C in the surface storage",
        "Max W.C in root zone storage",
        "Overland flow runoff coefficient",
        "Time Constant for Interflow",
        "Time constant for routing overland flow",
        "Root zone treshold value for overland flow",
        "Root zone treshold value for inter flow",
        "Root zone treshold value for groundwater recharge",
        "Time constant for routing base flow",
        "Degree day coefficient",
        "Snow melt temp"
      )
    df <- data.frame(par, par_v, df)
    names(df) <- c("Parameter", "Description", "Value")
    df
  }, options = list(pageLength = 25))
  
  output$stats = DT::renderDataTable({
    df <- newData()[[3]]
    metric <- c()
    value <- c()
    for (i in 1:length(df)) {
      metric <- c(metric, df[[i]][[1]])
      value <- c(value, df[[i]][[2]])
      
    }
    
    par <-
      c(
        "Agreement Index (d) developed by Willmott (1981)",
        "BIAS",
        "Correlation Coefficient",
        "Covariance ",
        "Decomposed MSE developed by Kobayashi and Salam (2000",
        "Kling-Gupta Efficiency",
        "Logarithmic probability distribution",
        "Log Nash-Sutcliffe model efficiency",
        "Mean Absolute Error",
        "Mean Squared Error",
        "Nash-Sutcliffe model efficinecy",
        "Procentual Bias",
        "Root Mean Squared Error",
        "Relative Root Mean Squared Error",
        "Coefficient of Determination",
        "RMSE-observations standard deviation ratio",
        "Volume Error (Ve)"
      )
    df_stat <- data.frame(par, value)
    names(df_stat) <- c("Metric", "Value")
    
    df_stat
  }, options = list(pageLength = 25))
  
  output$flowdur <- renderPlotly({
    df <- newData()[[4]]
    
    pt <- ggplot(df) +
      geom_line(aes(x = Qsim_x, y = Qsim_y), color = "darkred") +
      geom_line(aes(x = Qobs_x, y = Qobs_y),
                color = "steelblue",
                linetype = "twodash") +
      xlab("Percentage Exceedence (%)") + ylab("Discharge m$^3$/s")
    
    fig <- ggplotly(pt)
    fig
    
  })
  
  output$states <- renderPlotly({
    df <- newData()[[5]]
    df$Date <- as.Date(df$Date, "%Y-%m-%d")
    
    fig1 <- plot_ly(df, x = ~ Date, y = ~ u)
    fig1 <- fig1 %>% add_lines(name = ~ "u") %>% layout(xaxis = list(title = "Date"),
                                                        yaxis = list(title = "U"))
    fig2 <- plot_ly(df, x = ~ Date, y = ~ l)
    fig2 <- fig2 %>% add_lines(name = ~ "l") %>% layout(xaxis = list(title = "Date"),
                                                        yaxis = list(title = "L"))
    fig3 <- plot_ly(df, x = ~ Date, y = ~ bf)
    fig3 <- fig3 %>% add_lines(name = ~ "bf") %>% layout(xaxis = list(title = "Date"),
                                                         yaxis = list(title = "BF"))
    fig4 <- plot_ly(df, x = ~ Date, y = ~ if1)
    fig4 <- fig4 %>% add_lines(name = ~ "if1") %>% layout(xaxis = list(title = "Date"),
                                                          yaxis = list(title = "IF1"))
    fig <- subplot(fig1, fig2, fig3, fig4)
    fig1 <- plot_ly(df, x = ~ Date, y = ~ if2)
    fig1 <- fig1 %>% add_lines(name = ~ "if2")
    fig2 <- plot_ly(df, x = ~ Date, y = ~ of1)
    fig2 <- fig2 %>% add_lines(name = ~ "of1")
    fig3 <- plot_ly(df, x = ~ Date, y = ~ of2)
    fig3 <- fig3 %>% add_lines(name = ~ "of2")
    fig4 <- plot_ly(df, x = ~ Date, y = ~ snow)
    fig4 <- fig4 %>% add_lines(name = ~ "csnow")
    fig1 <- subplot(fig1, fig2, fig3, fig4)
    figg <- subplot(fig, fig1, nrows = 2)
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
  
  
  output$downloadData <- downloadHandler(
    filename = function() {
      paste("Results.xlsx", sep = '')
    },
    content = function(file) {
      myfile <- srcpath <- './Data/Results.xlsx'
      file.copy(myfile, file)
    }
  )
  
  
  output$routing <- renderPlotly({
    df <- newData()[[1]]
    inflow <- df$Qsim
    routingMethod <- c("muskingumcunge")
    routingParams <-
      list(
        k = input$kval,
        x = input$xval,
        bedWith = input$bedwith,
        sideSlope = input$sslope,
        channelSlope = input$cslope,
        manningRoughness = input$manning,
        riverLength = input$rlength
      )
    routingParams1 <-
      list(
        k = 3,
        x = 1,
        bedWith = 50,
        sideSlope = 2,
        channelSlope = 0.0001,
        manningRoughness = 0.01,
        riverLength = 100
      )
    rr <- cbind(routingParams, routingParams1)
    print(rr)
    
    simulation <-
      list(
        start = paste(df$date[[1]]),
        end = paste(df$date[[length(df$date)]]),
        by = 86400
      )
    routed <-
      RHMS::reachRouting(inflow, routingMethod[1], routingParams, simulation)
    
    # inflow <- routed$operation[[1]]
    outflow <- routed$operation[[2]]
    # date <- df$date
    df <- cbind(df, outflow)
    
    pt <- ggplot(df, aes(x = date)) +
      geom_line(aes(y = Qsim), color = "darkred") +
      geom_line(aes(y = outflow), color = "steelblue", linetype = "twodash") +
      xlab("Date") + ylab("Discharge , m3/s")
    
    fig <- ggplotly(pt)
    fig
    
  })
  
})
