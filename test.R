library(ggplot2)
library(dplyr)
library(DBI)

source('functions.R')

# Testing task list functions -------------------------------------------------------------------------

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




# Generate test task list

testTaskList = data.frame("taskID" = seq(from = 1, to = 100), "inProgress" = 0, "completed" = 0, "owner" = NA)
testTaskList = rbind.data.frame(testTaskList, data.frame("taskID" = c(101,102, 103), 
                                                         "inProgress" = c(1,1,0), "completed" = c(0,0,1), "owner" = c(Sys.info()['nodename'], "other", "other")))
row.names(testTaskList) = NULL
write.csv(testTaskList, file = '../CT_sim_tasks/taskList.csv', row.names = F)
rm(testTaskList)

# Connect to online database

con <- dbConnect(odbc::odbc(), .connection_string = "Driver={SQL Server};Server=den1.mssql6.gear.host;Database=tasklistntres;Uid=tasklistntres;Pwd=Gy435_eN5-Ry;")

# Read table 

(taskList = dbReadTable(conn = con, name = 'tasklistntres'))

# Load test table into db

taskList = read.csv(file = "../CT_sim_tasks/taskList.csv")

dbWriteTable(conn = con, name = 'tasklistntres', value = taskList, overwrite = TRUE)

dbDisconnect(con)

# update table to reserve tasks

reservedTasks = seq(1:8)

dbExecute(conn = con, statement = paste0("UPDATE tasklistntres SET inProgress = 1, owner = \'",Sys.info()['nodename'],"\' WHERE taskID IN (", toString(reservedTasks), ");"))

# Did it work? It DID!

dbReadTable(conn = con, name = 'tasklistntres')



# Testing getDesign --------------------------------------------------------

xlim = c(0,100)
ylim = c(0,100)

getDesign(noTraps = 100, noClust = 50)


# Deprecated ------------------------------------------------------------------------------------


# Testing taskIn
reservedTasks = taskIn(debug = F)

while(length(reservedTasks > 0)){
  doNothing(reservedTasks = reservedTasks)
  reservedTasks = taskIn(debug = F)
}


# Testing make Vogelcluster

points = makeVogelCluster(noPoints = 20)

points = data.frame(points)
names(points) = c('x', 'y')

ggplot(data = points) + 
  geom_point(aes(x = x, y = y)) + 
  coord_equal()

summary(as.numeric(fields::rdist(points)))

