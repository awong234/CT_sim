# Install shiny and run this locally to monitor tasks.

# You can view the task list, and other computation performance metrics, as well as anticipated end of analyses.

if(!require(shiny)){install.packages("shiny")}
if(!require(DBI)){install.packages("DBI")}
if(!require(dplyr)){install.packages("dplyr")}
if(!require(ggplot2)){install.packages("ggplot2")}
if(!require(viridis)){install.packages("viridis")}
if(!require(reshape2)){install.packages("reshape2")}

printDBsafe = function(con, name){ # perform a simple read on the server database
  test = NULL
  
  while(is.null(test)){
    
    test = tryCatch(expr = {taskList = dbReadTable(conn = con, name = name)},
                    error = function(e){
                      message(e)
                      Sys.sleep(5)
                    }
    )
  }
  return(test)
  
  dbDisconnect(con)
  
  return(taskList)
}

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

taskTable = printDBsafe(con = con, name = 'tasklistntres')

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
                                ,plotOutput("timeChart", height = '500px')
                                ))
                       ,fluidRow(
                         column(12
                                 ,h4("Estimate of remaining time")
                                 ,textOutput("timeEstimate"))
                       )
                         
                       )
    
    )
  
)


# Server ----------------------------

server = function(input, output, session){
  
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
      geom_col(aes(x = userName, y = n)) + 
      scale_fill_viridis(option = "D") + 
      xlab("User Name") + ylab("Tasks Taken") + theme_bw() + 
      ggtitle("Tasks by User")
    
  })
  
  output$tasksCompleted = renderUI(expr = {
    
    taskTable = formatTable()
    
    text1 = paste0("<h3>",sum(taskTable$completed), " of ", nrow(taskTable), " tasks completed.</h3>")
    text2 = paste0("<h4>", round(100*sum(taskTable$completed) / nrow(taskTable), 2), "% complete.</h4>")
    
    HTML(paste(text1, text2, sep = "<br/>"))
    
  })
  
  output$timeChart = renderPlot(expr = {
    
    taskTable = taskTable %>% mutate(timeStarted = ifelse(test = timeStarted > 0, yes = timeStarted, no = NA), 
                                                                           timeEnded = ifelse(test = timeEnded > 0, yes = timeEnded, no = NA), 
                                                                           Duration = ifelse(timeStarted > 0 & timeEnded > 0, (timeEnded - timeStarted)/60, 0))
    
    startEnd = taskTable %>% filter(completed == 1 | inProgress == 1) %>% mutate(timeStarted = as.POSIXct(timeStarted, origin = origin), timeEnded = as.POSIXct(timeEnded, origin = origin)) %>% 
      select(taskID, timeStarted, timeEnded, owner) %>% melt(id.vars = c('taskID', 'owner')) %>% rename("StartEnd" = variable, "Time" = value)
    
    ggplot() + 
      geom_line(data = startEnd, aes(x = factor(taskID), y = Time, group = taskID, color = owner), size = 3) +
      theme_bw() + xlab("Task ID") + 
      geom_smooth(data = startEnd %>% filter(StartEnd == "timeEnded"), aes(x = (taskID), y = Time), method = "lm", color = 'black', linetype = 'dotted')
  })
  
  output$timeEstimate = renderText(expr = {
    
    taskTable = taskTable %>% mutate(timeStarted = ifelse(test = timeStarted > 0, yes = timeStarted, no = NA), 
                                                                           timeEnded = ifelse(test = timeEnded > 0, yes = timeEnded, no = NA)
                                                                          ) %>% arrange(timeStarted)
    
    maxTasks = nrow(taskTable)
    
    taskTable = taskTable %>% filter(completed == 1 | inProgress == 1) %>% mutate(timeStarted = as.POSIXct(timeStarted, origin = origin), timeEnded = as.POSIXct(timeEnded, origin = origin), timeIndex = seq(1,nrow(.))) %>% select(timeStarted, timeEnded, owner, timeIndex) %>% melt(id.vars = c('timeIndex', 'owner')) %>% rename("StartEnd" = variable, "Time" = value)
    
    lm1 = lm(formula = Time ~ timeIndex, data = taskTable)
    
    newdata = data.frame('timeIndex' = seq(1, maxTasks), 'predDate' = NA)
    
    predictedDates = predict(lm1, newdata = newdata)
    
    finalDate = predictedDates[maxTasks] %>% as.POSIXct(origin = origin) %>% format("%m/%d/%Y")
    
    paste0("Date of completion anticipated to be ", finalDate, ". Ordinary linear regression on end times predicting end time of task number ", maxTasks, ".")
    
    
  })
  
  output$progressBar = renderPlot(expr = {
    
    taskTable = formatTable()
    
    taskTable %>% select(taskID, inProgress, completed) %>% group_by(taskID) %>% summarize(status = ifelse(inProgress == 0 & completed == 0, "Not Started", ifelse(inProgress == 1, "In Progress", "Complete"))) %>% 
    
    ggplot() + 
      geom_col(aes(x = "Tasks", y = taskID, fill = factor(status, levels = c("Not Started", "In Progress", "Complete")))) + coord_flip() +
      theme_bw() + scale_fill_manual(values = c('gray50', 'forestgreen', 'orange'), name = 'status') + theme(
        axis.title = element_blank(),
        axis.text = element_blank()
      )
  }, height = 100)
  
}


shinyApp(ui = ui, server = server)