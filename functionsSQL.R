# Host for functions used in camera trapping simulation.

# Main script will have a `while` function looping until there are no more tasks to be completed. 

# Remote task read/write section ---------------------------------------------------------------------------------------------------------------------------------------------

# Trying new version with `DBI` and a custom SQL server. Git was too slow, data
# needs to be able to be edited in place, instead of by replacing files.

require(DBI)

reserveTasks = function(nName = Sys.info()['nodename'], numTasks = NULL){
  
  # Open database connection # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
  
  con <- dbConnect(odbc::odbc(), .connection_string = "Driver={SQL Server};Server=den1.mssql6.gear.host;Database=tasklistntres;Uid=tasklistntres;Pwd=Gy435_eN5-Ry;")
  
  # # # # Check to see if tasks taken by computer are not done yet - in event of unexpected shutdowns. # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
  
  # Is your computer 'working on' an event at the time of this check? If so, it never finished from the previous startup.
  
  # So, set inProgress to 0, and owner to NA, freeing up the task. 
  test = NULL
  while(is.null(test)){
    
    test = tryCatch(expr = {dbExecute(con, statement = paste0("UPDATE tasklistntres SET owner = 'NONE', inProgress = 0 WHERE inProgress = 1 AND completed = 0 AND owner = \'", nName, "\'"))},
                    error = function(e){},
                    warning = function(e){}
    )
    
  }
  
  
  
  # # # # Query free tasks and reserve a number of them # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
  
  if(is.null(numTasks)){numTasks = parallel::detectCores()-1} # Default numTasks to number of cores.
  
  test = NULL
  while(is.null(test)){
    
    test = tryCatch(expr = {dbExecute(con, statement = paste0("UPDATE TOP (", numTasks, ") tasklistntres SET inProgress = 1, owner = \'", nName, "\' WHERE inProgress = 0 AND completed = 0"))},
                    error = function(e){},
                    warning = function(e){}
    )
  }
  
  taskList = dbReadTable(con, 'tasklistntres')
  reservedTasksIndex = taskList$inProgress == 1 & taskList$owner == nName
  reservedTasks = taskList$taskID[reservedTasksIndex]
  
  
  # # # # Shut down connection # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
  
  dbDisconnect(con)
  
  return(reservedTasks)
  
}

updateTaskCompleted = function(nName = Sys.info()['nodename'], reservedTasks = NULL){
  
  if(is.null(reservedTasks)){stop("You have not reserved any tasks yet, or have lost the reservation. Re-run function to reserve tasks.")}
  
  # Open database connection # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
  
  con <- dbConnect(odbc::odbc(), .connection_string = "Driver={SQL Server};Server=den1.mssql6.gear.host;Database=tasklistntres;Uid=tasklistntres;Pwd=Gy435_eN5-Ry;")
  
  # # # # Which ones were we working on? # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
  
  # Must have saved these values from reserveTasks()
  
  # # # # Change values in connected table # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
  test = NULL
  while(is.null(test)){
    
    test = tryCatch(expr = {dbExecute(conn = con, statement = paste0("UPDATE tasklistntres SET inProgress = 0, completed = 1 WHERE taskID IN (", toString(reservedTasks), ");"))},
                    error = function(e){},
                    warning = function(e){}
    )
  }
  
  taskList = dbReadTable(conn = con, name = 'tasklistntres')
  
  # # # # Shut down connection # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
  
  dbDisconnect(con)
  
}

printDB = function(){ # perform a simple read on the server database
  
  con <- dbConnect(odbc::odbc(), .connection_string = "Driver={SQL Server};Server=den1.mssql6.gear.host;Database=tasklistntres;Uid=tasklistntres;Pwd=Gy435_eN5-Ry;")
  
  taskList = dbReadTable(conn = con, name = 'tasklistntres')
  
  dbDisconnect(con)
  
  return(taskList)
}

testSQL = function(reservedTasks = integer(0)){
  
  # In parallel, reserve and 'analyze' tasks, updating completed tasks
  # concurrently.
  
  reservedTasksFull = reservedTasks
  
  registerDoParallel(cores = detectCores()-1) # Leave one free core.
  
  while(length(reservedTasks) > 0){
    
    # For each task, write done when completed.
    foreach(i = reservedTasks, .export = c('updateTaskCompleted'), .packages = c("DBI")) %dopar%{
      Sys.sleep(10) # "Analysis"
      updateTaskCompleted(reservedTasks = i)
    }
    
    # Reserve another batch of tasks
    reservedTasks = reserveTasks()
    
    # Append local record of tasks reserved
    reservedTasksFull = c(reservedTasksFull, reservedTasks)
    
  }
  
  write.csv(reservedTasksFull, file = 'reservedTasks.csv', row.names = F)
  
}

