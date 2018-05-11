source('functionsSQL.R')

subrt_updateComplete = function(){

  print("DON'T CLOSE ME, I AM MONITORING TASKS AND UPLOADING THEM EVERY 10 MINUTES")
    
  repeat{
    
    # Check localOuput/ folder for tasks that are done
    
    files = dir(path = 'localOutput', pattern = ".Rdata")
    matches = (regmatches(x = files, m = gregexpr(pattern = '\\d+', text = files, perl = T)))
    done = do.call(what = rbind, args = lapply(matches, as.integer))
    
    # Compare against server and find which ones are not done up there
    
    con <- dbConnect(odbc::odbc(), .connection_string = "Driver={SQL Server};Server=den1.mssql6.gear.host;Database=tasklistntres;Uid=tasklistntres;Pwd=Gy435_eN5-Ry;")
    
    statement = paste0("SELECT taskID FROM tasklistntres WHERE owner = \'", Sys.info()['nodename'], "\' AND inProgress = 1")
    
    out = dbGetQuery(conn = con, statement = statement)
    
    tasksToComplete = done[!done %in% out]
    
    # Mark completed
    if(length(tasksToComplete > 0)) # updateTaskCompleted(reservedTasks = tasksToComplete)
    
    print(paste0("Updated ", length(tasksToComplete), " tasks."))
    
    Sys.sleep(10*60)
    
  }

}

subrt_updateComplete()