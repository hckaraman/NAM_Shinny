library(vroom)

file <- './Data (copy)/Sukesen (copy).csv'

df <- vroom(file)

# Check NA values in the data

na_values <- colSums(is.na(df))
na_names <- names(df)
dialog_text <- ""

# temp <- data.frame(nam_)

for (i in 1:length(na_values)) {
  if ( na_values[i][[1]] != 0) {
    # dialog_text <- append(dialog_text,paste(names(na_values[i][1]) ," data has " ,na_values[i][[1]] ," na values" ))
    dialog_text <- paste(dialog_text, "<br>", paste(names(na_values[i][1]) ," data has " ,na_values[i][[1]] ," na values" ),sep="")
  }
}

dialog_text <- paste(dialog_text, "<br>", "No data values has been set to zero!")

shinyApp(
  ui = basicPage(
    actionButton("show", "Show modal dialog")
  ),
  server = function(input, output) {
    observeEvent(input$show, {
      showModal(modalDialog(
        HTML(dialog_text)
      ))
    })
  }
)




