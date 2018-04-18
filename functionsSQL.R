# Host for functions used in camera trapping simulation.

# Main script will have a `while` function looping until there are no more tasks to be completed. 

# Remote task read/write section ---------------------------------------------------------------------------------------------------------------------------------------------

# Trying new version with `DBI` and a custom SQL server. Git was too slow, data
# needs to be able to be edited in place, instead of by replacing files.

require(DBI)

reserveTasks = function(numTasks = NULL){
  
  if (!file.exists("reservedTasks.csv")) {
    file.create("reservedTasks.csv")
  }
  
  # Open database connection # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
  
  con <- dbConnect(odbc::odbc(), .connection_string = "Driver={SQL Server};Server=den1.mssql6.gear.host;Database=tasklistntres;Uid=tasklistntres;Pwd=Gy435_eN5-Ry;")
  
  # # # # Check to see if tasks taken by computer are not done yet - in event of unexpected shutdowns. # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
  
  # Is your computer 'working on' an event at the time of this check? If so, it never finished from the previous startup.
  
  # So, just take those tasks again
  
  test = NULL
  while(is.null(test)){
    
    # evaluates to a table upon success. Will evaluate to NULL upon failure.
    test = tryCatch(expr = {dbGetQuery(con, statement = paste0("SELECT * FROM tasklistntres WHERE owner = ", "\'", Sys.info()['nodename'], "\'", " AND inProgress = 1 AND completed = 0"))},
                    error = function(e){
                      message("Another user has a lock on the server; waiting two seconds to retry . . .")
                      # Wait a few seconds to retry...
                      Sys.sleep(2)
                    }
    )
  }
  
  # If some left over from before, set those as reserved tasks to be completed.
  if(nrow(test) > 0){ 
    reservedTasks = test$taskID
    # Writing to local copy not necessary, since they should have been registered before.
    # write.table(x = reservedTasks, file = 'reservedTasks.csv', row.names = F, append = T, sep = ',', col.names = F) 
    return(reservedTasks)}
  
  
  
  # # # # Query free tasks and reserve a number of them # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
  
  if(is.null(numTasks)){numTasks = parallel::detectCores()-1} # Default numTasks to number of cores.
  
  test = NULL
  while(is.null(test)){
    
    test = tryCatch(expr = {dbExecute(con, statement = paste0("UPDATE TOP (", numTasks, ") tasklistntres SET inProgress = 1, owner = \'", Sys.info()['nodename'], "\' WHERE inProgress = 0 AND completed = 0"))},
                    error = function(e){    
                      message("Another user has a lock on the server; waiting two seconds to retry . . .")
                      # Wait a few seconds to retry...
                      Sys.sleep(2)
                    }
    )
  }
  
  reservedTasks = dbGetQuery(con, statement = paste0("SELECT * FROM tasklistntres WHERE inProgress = 1 AND owner = ", "\'", Sys.info()['nodename'], "\'"))[,1]
  
  dbDisconnect(con)
  
  # # # # Shut down connection # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
  
  # Append local record of tasks reserved
  write.table(x = reservedTasks, file = 'reservedTasks.csv', row.names = F, append = T, sep = ',', col.names = F)
  
  return(reservedTasks)
  
}

updateTaskCompleted = function(reservedTasks = NULL){
  
  if(is.null(reservedTasks)){stop("You have not reserved any tasks yet, or have lost the reservation. Re-run reserveTasks().")}
  
  # Open database connection # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
  
  con <- dbConnect(odbc::odbc(), .connection_string = "Driver={SQL Server};Server=den1.mssql6.gear.host;Database=tasklistntres;Uid=tasklistntres;Pwd=Gy435_eN5-Ry;")
  
  # # # # Which ones were we working on? # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
  
  # Must have saved these values from reserveTasks()
  
  # # # # Change values in connected table # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
  
  test = NULL
  while(is.null(test)){
    
    test = tryCatch(expr = {dbExecute(conn = con, statement = paste0("UPDATE tasklistntres SET inProgress = 0, completed = 1 WHERE taskID IN (", toString(reservedTasks), ");"))},
                    error = function(e){
                      message("Another user has a lock on the server; waiting two seconds to retry . . .")
                      Sys.sleep(2)
                    }
    )
  }
  
  
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
  
  registerDoParallel(cores = detectCores()-1) # Leave one free core.
  
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
  
  name = readline("Please enter your netID: ")
  
  userName = tolower(name)
  
  if(update){ # If mistake in user name
    con = dbConnect(odbc::odbc(), .connection_string = "Driver={SQL Server};Server=den1.mssql4.gear.host;Database=registerusers;Uid=registerusers;Pwd=Zh4p92?frN2_")
    
    test = NULL
    while(is.null(test)){
      
      test = tryCatch(expr = {
        dbExecute(conn = con, statement = paste0("UPDATE registerusers SET userName = \'", userName, "\'", " WHERE machineName = ", "\'", Sys.info()['nodename']))},
        error = function(e){
          message("Another user has a lock on the server; waiting two seconds to retry . . .")
          Sys.sleep(2)
        }
      )
    }
    
    message("You have updated your user name.")
    
    dbDisconnect()
  }
  
  con = dbConnect(odbc::odbc(), .connection_string = "Driver={SQL Server};Server=den1.mssql4.gear.host;Database=registerusers;Uid=registerusers;Pwd=Zh4p92?frN2_")
  
  # deletes records with null values for user name
  # dbExecute(conn = con, statement = "DELETE FROM registerusers WHERE userName = \'\'")
  
  table = dbReadTable(conn = con, name = 'registerusers')
  
  if( # Basically test if Sys.info()['nodename'] and userName combination in table already.
    any(
      apply(X = table, MARGIN = 1, FUN = function(x){all((c(Sys.info()['nodename'], userName) == x))})
    )
  ){
    message("You have already registered this computer!")
    dbDisconnect(conn = con)
    return(userName)}else{
      
      SQL_statement = paste0("INSERT INTO registerusers (machineName, userName) VALUES (", "\'", Sys.info()['nodename'], "\', ", "\'", userName, "\')")
      
      test = NULL
      while(is.null(test)){
        test = tryCatch(expr = {dbExecute(conn = con, statement = SQL_statement)},
          error = function(e){
            message("Another user has a lock on the server; waiting two seconds to retry . . .")
            Sys.sleep(2)
          }
        )
      }
      
      dbDisconnect(conn = con)
      
      message("Thank you for registering!")
      
      return(userName)
    }
  
}
