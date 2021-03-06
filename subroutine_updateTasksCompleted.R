source('functionsSQL.R')

subrt_updateComplete = function(){

  message("DON'T CLOSE ME, I AM MONITORING TASKS AND UPDATING THEIR STATUS EVERY 10 MINUTES")
    
  repeat{
    
    # Check localOuput/ folder for tasks that are done
    
    files = dir(path = 'localOutput', pattern = ".Rdata")
    matches = (regmatches(x = files, m = gregexpr(pattern = '\\d+', text = files, perl = T)))
    done = do.call(what = rbind, args = lapply(matches, as.integer))
    
    # Compare against server and find which ones are not done up there
    
    con <- dbConnect(odbc::odbc(), .connection_string = "Driver={SQL Server};Server=den1.mssql6.gear.host;Database=tasklistntres;Uid=tasklistntres;Pwd=Gy435_eN5-Ry;")
    
    statement = paste0("SELECT taskID FROM tasklistntres WHERE owner = \'", Sys.info()['nodename'], "\' AND inProgress = 1")
    
    test = NULL
    
    while(is.null(test)){
      
      test = tryCatch(expr = {out = dbGetQuery(conn = con, statement = statement)},
                      error = function(e){
                        # message(e)
                        Sys.sleep(rpois(n = 1, lambda = 5))
                      }
      )
    }
    
    dbDisconnect(conn = con)
    
    tasksToUpdate = done[done %in% out$taskID]
    
    # Mark completed
    if(length(tasksToUpdate > 0)){updateTaskCompleted(reservedTasks = tasksToUpdate)}
    
    message(paste0("Updated ", length(tasksToUpdate), " tasks at ", format(Sys.time(), '%H:%M:%S'), "."))
    
    message("DON'T CLOSE ME, I AM MONITORING TASKS AND UPDATING THEIR STATUS EVERY 10 MINUTES")
    
    Sys.sleep(10*60)
    
  }

}

subrt_updateComplete()