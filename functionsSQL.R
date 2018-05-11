# Host for functions used in camera trapping simulation.

# Main script will have a `while` function looping until there are no more tasks to be completed. 

# Remote task read/write section ---------------------------------------------------------------------------------------------------------------------------------------------

# Trying new version with `DBI` and a custom SQL server. Git was too slow, data
# needs to be able to be edited in place, instead of by replacing files.

for(i in 1:2){
  if(!require(DBI)){install.packages('DBI')}
  if(!require(odbc)){install.packages('odbc')}
}


reserveTasks = function(numTasks = NULL){
  
  # if (!file.exists("reservedTasks.csv")) {
  #   file.create("reservedTasks.csv")
  # }
  
  # Open database connection # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
  
  con <- dbConnect(odbc::odbc(), .connection_string = "Driver={SQL Server};Server=den1.mssql6.gear.host;Database=tasklistntres;Uid=tasklistntres;Pwd=Gy435_eN5-Ry;")
  
  # # # # Check to see if tasks taken by computer are not done yet - in event of unexpected shutdowns. # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
  
  # Is your computer 'working on' an event at the time of this check? If so, it never finished from the previous startup.
  
  # So, just take those tasks again
  test = NULL
  statement = paste0("SELECT * FROM tasklistntres WHERE owner = ", "\'", Sys.info()['nodename'], "\'", " AND inProgress = 1 AND completed = 0")
  while(is.null(test)){

    # evaluates to a table upon success. Will evaluate to NULL upon failure.
    test = tryCatch(expr = {dbGetQuery(con, 
                                       statement = statement)},
                    error = function(e){
                      # message(e)
                      # Wait a few seconds to retry...
                      Sys.sleep(rpois(n = 1, lambda = 5))
                    }
    )
  }

  # If some left over from before, set those as reserved tasks to be completed.
  if(nrow(test) > 0){ 
    reservedTasks = test$taskID

    statement = paste0("UPDATE tasklistntres SET timeStarted = ", as.integer(Sys.time()), " WHERE taskID IN (", toString(reservedTasks), ")")
    
    executeWithRestart(SQL_statement = statement, con = con)
    
    return(reservedTasks)}
  
  
  # # # # Query free tasks and reserve a number of them # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
  
  if(is.null(numTasks)){numTasks = parallel::detectCores()-1} # Default numTasks to number of cores.
  
  statement = paste0("WITH q AS (SELECT TOP ", numTasks, " * FROM tasklistntres WHERE inProgress = 0 AND completed = 0 ORDER BY taskID) UPDATE q SET inProgress = 1, owner = \'", Sys.info()['nodename'], "\', timeStarted = ", as.integer(Sys.time()))
  
  # Old version. Not ordered.
  # statement = paste0("UPDATE TOP (", numTasks, ") tasklistntres SET inProgress = 1, owner = \'", Sys.info()['nodename'], "\', timeStarted = ", as.integer(Sys.time()), " WHERE inProgress = 0 AND completed = 0")
  
  executeWithRestart(SQL_statement = statement, con = con)
  
  test = NULL
  while(is.null(test)){
    test = tryCatch(
      expr = {reservedTasks = dbGetQuery(con, statement = paste0("SELECT * FROM tasklistntres WHERE inProgress = 1 AND owner = ", "\'", Sys.info()['nodename'], "\'"))[,1]},
      error = function(e){
        # message(e)
        # Wait a few seconds to retry...
        Sys.sleep(rpois(n = 1, lambda = 5))
      }
    )
  }
  
  dbDisconnect(con)
  
  # # # # Shut down connection # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
  
  # Append local record of tasks reserved
  # write.table(x = reservedTasks, file = 'reservedTasks.csv', row.names = F, append = T, sep = ',', col.names = F)
  
  return(reservedTasks)
  
}

updateTaskCompleted = function(reservedTasks = NULL){
  
  if(is.null(reservedTasks)){stop("You have not reserved any tasks yet, or have lost the reservation. Re-run reserveTasks().")}
  
  # Open database connection # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
  
  con <- dbConnect(odbc::odbc(), .connection_string = "Driver={SQL Server};Server=den1.mssql6.gear.host;Database=tasklistntres;Uid=tasklistntres;Pwd=Gy435_eN5-Ry;")
  
  # # # # Which ones were we working on? # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
  
  # Must have saved these values from reserveTasks()
  
  # # # # Change values in connected table # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
  
  statement = paste0("UPDATE tasklistntres SET inProgress = 0, completed = 1, timeEnded = ", as.integer(Sys.time()), " WHERE taskID IN (", toString(reservedTasks), ");")

  test = NULL
  
  while(is.null(test)){
    
    test = tryCatch(expr = {dbExecute(conn = con, statement = statement)},
                    error = function(e){
                      # message(e)
                      Sys.sleep(rpois(n = 1, lambda = 5))
                    }
    )
  }
  return(test)
  
  # # # # Shut down connection # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
  
  dbDisconnect(con)
  
}

printDB = function(){ # perform a simple read on the server database
  
  con <- dbConnect(odbc::odbc(), .connection_string = "Driver={SQL Server};Server=den1.mssql6.gear.host;Database=tasklistntres;Uid=tasklistntres;Pwd=Gy435_eN5-Ry;")
  
  taskList = dbGetQuery(conn = con, statement = "SELECT TOP 100 * FROM tasklistntres ORDER BY timeStarted DESC")
  
  dbDisconnect(con)
  
  return(taskList)
}

testSQL = function(reservedTasks = integer(0)){
  
  # Deprecated - tests fulfilled conditions
  
  # In parallel, reserve and 'analyze' tasks, updating completed tasks
  # concurrently.
  
  cores = detectCores() - 1
  
  registerDoParallel(cores = cores) # Leave one free core.
  
  reservedTasks = reserveTasks(numTasks = cores)
  
  while(length(reservedTasks) > 0){
    
    # For each task, write done when completed.
    foreach(i = reservedTasks, .export = c('updateTaskCompleted'), .packages = c("DBI")) %dopar%{
      Sys.sleep(1) # "Analysis"
      updateTaskCompleted(reservedTasks = i)
    }
    
    # Reserve another batch of tasks
    reservedTasks = reserveTasks()
  }
  
}

registerUser = function(update = F){
  
  if(update){ # If mistake in user name
    
    name = readline("Please enter your netID or initials: ")
    
    userName = tolower(name)
    
    con = dbConnect(odbc::odbc(), .connection_string = "Driver={SQL Server};Server=den1.mssql4.gear.host;Database=registerusers;Uid=registerusers;Pwd=Zh4p92?frN2_")
    
    statement = paste0("UPDATE registerusers SET userName = \'", userName, "\'", " WHERE machineName = ", "\'", Sys.info()['nodename'], "\'")
    
    executeWithRestart(SQL_statement = statement, con = con)
    
    message(paste0("You have updated your user name to ", userName))
    
    dbDisconnect(conn = con)
    
    return(name)
  }
  
  con = dbConnect(odbc::odbc(), .connection_string = "Driver={SQL Server};Server=den1.mssql4.gear.host;Database=registerusers;Uid=registerusers;Pwd=Zh4p92?frN2_")
  
  table = dbReadTable(conn = con, name = 'registerusers')
  
  if(Sys.info()['nodename'] %in% table$machineName){  # Basically test if Sys.info()['nodename'] in table already.
    
    name = table$userName[table$machineName == Sys.info()['nodename']]
    
    message(paste0("You have registered this computer under the following user name(s) : ", toString(name)))
    
    message("Please run registerUser(update = T) if there are errors in the user name.")
    
    dbDisconnect(conn = con)
    
    return(name)}else{ # Fresh entry
      
      name = readline("Please enter your netID or initials: ")
      
      userName = tolower(name)
      
      SQL_statement = paste0("INSERT INTO registerusers (machineName, userName) VALUES (", "\'", Sys.info()['nodename'], "\', ", "\'", userName, "\')")
      
      executeWithRestart(SQL_statement = SQL_statement, con = con)
      
      dbDisconnect(conn = con)
      
      message(paste0("Thank you for registering, ", userName, "!"))
      
      message("Please run registerUser(update = T) if there are errors in the user name.")
      
      return(userName)
    }
  
}

executeWithRestart = function(SQL_statement, con){
  
  test = NULL
  
  while(is.null(test)){
  
      test = tryCatch(expr = {dbExecute(conn = con, statement = SQL_statement)},
                    error = function(e){
                      # message(e)
                      Sys.sleep(rpois(n = 1, lambda = 5))
                    }
    )
  }
  return(test)
}

# Register user names with computer names
registerUser(update = F)
