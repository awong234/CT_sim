# Host for functions used in camera trapping simulation.

# Remote task read/write section ------------------------------------------------------------------------------

# Need a function to read task ID's, whether in progress, whether output saved (or code with error), and owner

taskIN = function(debug = FALSE, taskURL){
  
  if(debug){
    testTaskList = data.frame("taskID" = seq(from = 1, to = 100), "inProgress" = 0, "completed" = 0, "owner" = NA)
    testTaskList = rbind.data.frame(testTaskList, data.frame("taskID" = c(101,102), "inProgress" = c(1,1), "completed" = c(0,0), "owner" = c(Sys.info()['nodename'], "other")))
    row.names(testTaskList) = NULL
    write.csv(testTaskList, file = 'testTaskList.csv')
    rm(testTaskList)
  }
  
  nName = Sys.info()['nodename'] # Reports name of computer
  
  # Check to see if tasks taken by computer are not done yet - in event of unexpected shutdowns.
  
  taskList = read.csv(file = taskURL)
  
  # Is your computer 'working on' an event at the time of this check? If so, it never finished from the previous startup.
  resetIndex = nName == taskList$owner & taskList$inProgress == 1 
  
  # So, set inProgress to 0, and owner to NA, freeing up the task. 
  
  taskList$inProgress[resetIndex] = 0
  taskList$owner[resetIndex] = NA
  
  taskOut(taskList)
  
  return(taskList)
  
}


# Need a function to write data to remote file. 

taskOut = function(dataToWrite){
  
  return(NULL)
  
}