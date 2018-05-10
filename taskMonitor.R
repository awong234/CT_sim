# Install shiny and run this locally to monitor tasks.

# You can view the task list, and other computation performance metrics, as well as anticipated end of analyses.

for(i in 1:2){
  if(!require(shiny)){install.packages("shiny")}
  if(!require(DBI)){install.packages("DBI")}
  if(!require(dplyr)){install.packages("dplyr")}
  if(!require(ggplot2)){install.packages("ggplot2")}
  if(!require(viridis)){install.packages("viridis")}
  if(!require(reshape2)){install.packages("reshape2")}
  if(!require(mgcv)){install.packages("mgcv")}
  if(!require(plotly)){install.packages("plotly")}
  if(!require(DT)){install.packages("DT")}
}

printDBsafe = function(con, name){ # perform a simple read on the server database
  test = NULL
  
  while(is.null(test)){
    
    test = tryCatch(expr = {taskList = dbReadTable(conn = con, name = name)},
                    error = function(e){
                      # message(e)
                      Sys.sleep(5)
                    }
    )
  }
  return(test)
  
  dbDisconnect(con)
  
  return(taskList)
}

regressions = function(taskTable, k, maxTasks, dataFrac){
  
  taskTableFull = taskTable %>% mutate(timeStarted = ifelse(test = timeStarted > 0, yes = timeStarted, no = NA), 
                                   timeEnded = ifelse(test = timeEnded > 0, yes = timeEnded, no = NA)
  )
  
  taskTableShort = taskTableFull %>% filter(complete.cases(.)) %>% sample_frac(size = dataFrac, weight = timeEnded %>% as.numeric)
  
  endTimes = taskTableShort %>% filter(completed == 1) %>% mutate(timeStarted = as.POSIXct(timeStarted, origin = origin), timeEnded = as.POSIXct(timeEnded, origin = origin)) %>% select(newTaskID, timeStarted, timeEnded, owner) %>% melt(id.vars = c('newTaskID', 'owner')) %>% rename("StartEnd" = variable, "Time" = value) %>% filter(StartEnd == "timeEnded")
  
  # Linear formula
  lm1 = lm(formula = Time %>% as.numeric() ~ newTaskID, data = endTimes)
  
  # Predict out new data 1000 tasks into the future
  newdata = data.frame('newTaskID' = c(seq(1, nrow(taskTableFull) + 1000), maxTasks), 'predDate' = NA)
  
  # Predict linear
  predictedDates = newdata
  predictedDates$Time = predict(lm1, newdata = newdata) %>% as.numeric() %>% as.POSIXct(origin = origin)
  
  # Fit GAM to existing tasks
  m = gam(formula = Time %>% as.numeric ~ s(newTaskID, k = k), data = endTimes %>% filter(StartEnd == "timeEnded"))
  
  # Predict GAM to existing tasks
  hires = seq(1, nrow(taskTableFull) + 1000)
  newdata = data.frame('newTaskID' = hires, 'Time' = NA)
  newdata$Time = predict.gam(object = m, newdata = newdata) %>% as.numeric() %>% as.POSIXct(origin = origin)
  se = predict.gam(object = m, newdata = data.frame('newTaskID' = hires), se.fit = T)[[2]] %>% as.numeric()
  seData = data.frame('newTaskID' = hires, 'SE' = se)
  
  # Predict GAM to future tasks with low resolution
  lores = seq(1,maxTasks,length.out = 10000)
  finalDate = data.frame('newTaskID' = lores, 'Time' = NA)
  finalDate$Time = predict.gam(object = m, newdata = finalDate) %>% as.numeric() %>% as.POSIXct(origin = origin)
  
  se.f = predict.gam(object = m, newdata = data.frame("newTaskID" = lores), se.fit = T)[[2]] %>% as.numeric()
  seData.f = data.frame('newTaskID' = lores, 'SE' = se.f)
  
  return(list("lm" = predictedDates, "gam" = newdata, "gamModel" = m, "se" = seData, 'finalDate' = finalDate, 'se.f' = seData.f))
  
}

origin = '1970-01-01'


# UI --------------------------------

ui = fluidPage(
  
  titlePanel("Task Monitor"),
  
  hr(),
  
  navbarPage("Pages"
             ,tabPanel("Full Table",
                       fluidRow(
                         column(12
                                ,htmlOutput("user")
                                ,plotOutput("progressBar", height = '100px')
                                ,htmlOutput("tasksCompleted")
                                ,shiny::hr()
                                ,h4("Search a date, or search your user name to see your tasks! (shown up above in the greeting).")
                                ,h4("If the username above is incorrect, please use registerUser(update = T) to fix.")
                                ,DT::dataTableOutput("table")
                                )
                       )
                       )
             ,tabPanel("Compute Statistics",
                       fluidRow(
                         column(4
                                ,h3("Registered Participants")
                                ,h5("and Efficiency")
                                ,tableOutput("userTable"))
                         ,column(8
                                ,plotOutput("userTasks"))
                       )
                       )
             ,tabPanel("Compute Time Estimate",
                       fluidRow(
                         column(12
                                ,h4("Chart of Task Completion")
                         ),
                         column(3
                                ,sliderInput("k", label = "Select smooth parameter", min = 2, max = 10, value = 2, step = 1)
                         ),
                         column(3
                                ,shiny::numericInput('days', label = 'Show how many days before now? Default is 1.', min = 1, max = 10, step = 1, value = 1)
                         ),
                         column(3
                                ,shiny::sliderInput('frac', label = 'Select fraction of data to view (for efficiency)', min = 0.01, max = 1, value = 0.1, step = 0.01)
                         ),
                         column(3
                                ,shiny::sliderInput('fracRegression', label = "Fraction of data to perform regression upon (weighted by date)?", 
                                                    min = 0.01, max = 1, value = 0.1, step = 0.01)
                         )
                         
                       )
                       ,fluidRow(
                         column(12
                                # ,plotOutput("timeChart", height = '500px'
                                ,plotlyOutput("timeChart2", height = '500px')
                                )
                       )
                       
                       ,fluidRow(
                         column(12
                                 ,h4("Estimate of remaining time")
                                 ,htmlOutput("timeEstimate"))
                       )
                         
                       )
    
    )
  
)


# Server ----------------------------

server = function(input, output, session){
  
  con <- DBI::dbConnect(drv = odbc::odbc(),
                        driver = "SQL Server",
                        database = 'registerusers',
                        server = 'den1.mssql4.gear.host',
                        uid = 'registerusers',
                        pwd = 'Zh4p92?frN2_')
  
  userTable = printDBsafe(con = con, name = 'registerusers')
  
  con <- DBI::dbConnect(drv = odbc::odbc(),
                        driver = "SQL Server",
                        database = 'tasklistntres',
                        server = 'den1.mssql6.gear.host',
                        uid = 'tasklistntres',
                        pwd = 'Gy435_eN5-Ry')
  
  taskTable = dbGetQuery(conn = con, statement = "SELECT * FROM tasklistntres WHERE owner <> 'NONE'")
  
  if(nrow(taskTable) == 0){
    taskTable = dbGetQuery(conn = con, statement = "SELECT TOP 1000 * FROM tasklistntres ORDER BY taskID")
  }
  
  maxTasks = dbGetQuery(conn = con, statement = "SELECT COUNT(*) FROM tasklistntres") %>% as.integer()
  
  output$user = renderText(expr = {
    
    thisSys = Sys.info()['nodename']
    
    paste0("<h1>Hello ", userTable[which(userTable$machineName == thisSys),'userName'],"!</h1>")
  })
  
  formatTable = reactive({
    
    table = taskTable %>% 
      mutate(inProgress = as.integer(inProgress), 
             completed = as.integer(completed), 
             `Duration in Minutes` = ifelse(timeStarted > 0 & timeEnded > 0, round((timeEnded - timeStarted)/60, 2), 0),
             timeStarted = ifelse(test = timeStarted > 0, yes = as.POSIXct(timeStarted, origin = "1970-01-01") %>% format("%b %d %Y %H:%M") %>% as.character(), no = NA),
             timeEnded = ifelse(test = timeEnded > 0, yes = as.POSIXct(timeEnded, origin = "1970-01-01") %>% format("%b %d %Y %H:%M") %>% as.character(), no = NA)
    ) %>% left_join(userTable, by = c("owner" = "machineName"))
    
    return(table)
    
  })
  
  output$table = DT::renderDataTable(formatTable())
  
  output$userTable = renderTable(expr = {
    
    taskTable = formatTable()
    
    timeTable = taskTable %>% group_by(owner) %>% summarize(AvgTime = mean(`Duration in Minutes`)) %>% filter(owner != "NONE")
    
    endTable = left_join(x = userTable, y = timeTable, by = c("machineName" = "owner"))
  
  })
  
  output$userTasks = renderPlot(expr = {
    
    endTable = taskTable %>% left_join(userTable, by = c("owner" = "machineName")) %>% group_by(userName) %>% tally() %>% filter(!is.na(userName))
    
    endTable %>% ggplot() +
      geom_col(aes(x = userName, y = n, fill = userName, alpha = 0.7), width = 0.7) + 
      scale_fill_viridis(option = "D", discrete = T) + 
      xlab("User Name") + ylab("Tasks Taken") + theme_bw() + 
      ggtitle("Tasks by User")
    
  })
  
  output$tasksCompleted = renderUI(expr = {
    
    taskTable = formatTable()
    
    text1 = paste0("<h3>",sum(taskTable$completed) %>% format(big.mark = ','), " of ", maxTasks %>% format(big.mark = ','), " tasks completed.</h3>")
    text2 = paste0("<h4>", round(100*sum(taskTable$completed) / maxTasks, 2), "% complete.</h4>")
    
    HTML(paste(text1, text2, sep = "<br/>"))
    
  })
 
  output$timeChart2 = renderPlotly(expr = {
    
    taskTable_formatted = taskTable %>% arrange(timeStarted,timeEnded) %>% mutate(timeStarted = ifelse(test = timeStarted > 0, yes = timeStarted, no = NA), 
                                     timeEnded = ifelse(test = timeEnded > 0, yes = timeEnded, no = NA), 
                                     Duration = ifelse(timeStarted > 0 & timeEnded > 0, (timeEnded - timeStarted)/60, 0),
                                     newTaskID = 1:nrow(.))
    
    startEnd = taskTable_formatted %>% filter(completed == 1 | inProgress == 1, complete.cases(.)) %>% 
      sample_frac(size = input$frac, weight = timeEnded %>% as.numeric()) %>% arrange(timeStarted, timeEnded) %>% 
      mutate(timeStarted = as.POSIXct(timeStarted, origin = origin), timeEnded = as.POSIXct(timeEnded, origin = origin)) %>% 
      select(newTaskID, timeStarted, timeEnded, owner)  %>% melt(id.vars = c('newTaskID', 'owner')) %>% rename("StartEnd" = variable, "Time" = value) %>% 
      filter((Sys.time() - Time) < input$days*24*60*60)
    
    minTime = min(startEnd$Time, na.rm = T)
    maxTime = max(startEnd$Time, na.rm = T)
    
    buff = (maxTime - minTime)*0.1
    
    out = regressions(taskTable = taskTable_formatted, k = input$k, maxTasks = maxTasks, dataFrac = input$fracRegression)
    
    newdata = out$gam
    newdata = newdata %>% mutate(Upper = Time + out$se$SE, Lower = Time - out$se$SE)
    
    finalDate = out$finalDate
    finalDate = finalDate %>% mutate(Upper = Time + out$se.f$SE, Lower = Time - out$se.f$SE)
    
    linear = out$lm
    
    small = plot_ly(data = startEnd) %>% 
      add_markers(x = ~newTaskID, y = ~Time, color = ~owner) %>% 
      add_lines(data = newdata, x = ~newTaskID, y = ~Time, name = 'GAM Predict') %>% 
      add_ribbons(data = newdata, x = ~newTaskID, ymax = ~Upper, ymin = ~Lower, fillcolor = 'rgba(255, 156, 0, 0.2)', line = list(color = 'rgba(255, 156, 0, 0.05'), showlegend = F) %>% 
      layout(
        xaxis = list(range = c(1,max(startEnd$newTaskID) + 0.1*(max(startEnd$newTaskID)))),
        yaxis = list(range = c(min(startEnd$Time, na.rm = T) - buff, max(startEnd$Time, na.rm = T) + buff))
      )
    
    full = plot_ly() %>% 
      add_lines(data = finalDate, x = ~newTaskID, y = ~Time, name = "GAM Predict (to end)") %>% 
      add_lines(data = linear, x = ~newTaskID, y = ~Time, name = "LM Predict (to end)") %>% 
      add_ribbons(data = finalDate, x = ~newTaskID, ymax = ~Upper, ymin = ~Lower, fillcolor = 'rgba(255, 156, 0, 0.2)', line = list(color = 'rgba(255, 156, 0, 0.05'), showlegend = F)
    
      
    
    subplot(small, full, widths = c(0.8, 0.2), titleX = T, titleY = T)
    
  })
  
  
  
  output$timeEstimate = renderText(expr = {

    out = regressions(taskTable = taskTable_formatted, k = input$k, maxTasks = maxTasks, dataFrac = input$fracRegression)
    
    predictedDates = out$lm
    
    newdata = out$finalDate
    
    finalDate = predictedDates[which(predictedDates$newTaskID == maxTasks),'Time'] %>% as.POSIXct(origin = origin) %>% format("%m/%d/%Y")
    
    finalDateGAM = newdata[which(newdata$newTaskID == maxTasks),'Time'] %>% as.POSIXct(origin = origin) %>% format("%m/%d/%Y")
    
    paste0("Date of completion anticipated to be: <br> LM =   <b>", finalDate, "</b>. Ordinary linear regression on end times predicting end time of task number ", maxTasks %>% format(big.mark = ','), "<br>GAM = <b>", finalDateGAM, "</b>. GAM is a generalized additive model regression on end time using a spline smoothing function with ", input$k, " degrees of freedom")
    
    
  })
  
  # output$progressBar = renderPlot(expr = {
  #   
  #   taskTable = formatTable()
  #   
  #   taskTable %>% select(taskID, inProgress, completed) %>% group_by(taskID) %>% summarize(status = ifelse(inProgress == 0 & completed == 0, "Not Started", ifelse(inProgress == 1, "In Progress", "Complete"))) %>% 
  #   
  #   ggplot() + 
  #     geom_col(aes(x = "Tasks", y = taskID, fill = factor(status, levels = c("Not Started", "In Progress", "Complete")))) + coord_flip() +
  #     theme_bw() + scale_fill_manual(values = c('gray50', 'orange', 'forestgreen'), name = 'status') + theme(
  #       axis.title = element_blank(),
  #       axis.text = element_blank()
  #     )
  # }, height = 100)
  
}


shinyApp(ui = ui, server = server)