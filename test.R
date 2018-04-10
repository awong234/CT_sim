library(ggplot2)
library(dplyr)
library(DBI)

source('functionsSQL.R')

# Testing task list functions -------------------------------------------------------------------------

# Show table

printDB() %>% filter(owner == Sys.info()['nodename'])

# Full test

reservedTasks = reserveTasks()
printDB()
while(length(reservedTasks) > 0){
  updateTaskCompleted(reservedTasks = reservedTasks)
  printDB()
  reservedTasks = reserveTasks()
  printDB()
  Sys.sleep(2)
}



# WARNING: RESETS STATE OF TASK LIST COMPLETELY
# Generate test task list

file.remove('reservedTasks.csv')

testTaskList = data.frame("taskID" = seq(from = 1, to = 500), "inProgress" = 0, "completed" = 0, "owner" = "NONE")
row.names(testTaskList) = NULL

# Connect to online database

con <- dbConnect(odbc::odbc(), .connection_string = "Driver={SQL Server};Server=den1.mssql6.gear.host;Database=tasklistntres;Uid=tasklistntres;Pwd=Gy435_eN5-Ry;")

# Load test table into db

dbWriteTable(conn = con, name = 'tasklistntres', value = testTaskList, overwrite = TRUE)

dbDisconnect(con)

head(printDB())
