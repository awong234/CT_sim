setWDHere = function(){
  sourcePath<-rstudioapi::getSourceEditorContext()$path[1]  # gets the location of the script that this piece of code is in
  sourceLoc<-strsplit(sourcePath, "/RUNSCRIPT")[[1]][1] # get the parent folder
  setwd(sourceLoc) # set the wd to the parent folder
}

setWDHere()



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

# PLEASE RUN THIS BY ITSELF TO REGISTER # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

source('functionsSQL.R')

# run this if your user name has an error
# registerUser(update = T) 

# YOU ONLY NEED TO DO THIS ONCE # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

# THANK YOU! # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Main script housing preparation of data, analysis of data, and exporting analysis elements.

# Sections 

# Preparation
  # Extract settings
  # Generate grids
  # Generate SCR data
  # Generate OCC data
# Analysis
  # Analyze data under SCR
  # Analyze data under OCC
  # Export analysis elements

# Preparation block ------------------------------------------------------------------------------------------------------------------------------

# Second time around loads the packages if they needed to be installed . . . 

for(i in 1:2){
  if(!require(doParallel)){install.packages('doParallel')}
  if(!require(parallel)){install.packages('parallel')}
  if(!require(Rcpp)){install.packages('Rcpp')}
  if(!require(RSQLite)){install.packages('RSQLite')}
  if(!require(dbplyr)){install.packages('dbplyr')}
  library(SPIM)
}

# Install spim package. If you do it this way, you will need to install Rtools
# v3.4 (find_rtools() Checks for this). Link in github front page.

source('build.cluster.R')
source('simSCR.R')

# Setup block ----------------------------------------------------------------------------------------------------------------------------------------

# Set up parallel backend. 

# You may customize the core load here. You will want to use more than 1 core
# for more efficiency, but if you need to work on other things, you may limit it
# to 2 cores, for example. When your computer is free, restart this process with
# as many cores as you have for max performance.

cores = detectCores() - 1
# cores = detectCores() / 2

# How many tasks to do at once?
numTasks = cores^2

registerDoParallel(cores = cores) 

# Analysis loop ----------------------------------------------------------------------------------------------------

# Start subroutine for updating completion of tasks. Don't close this window please.

system(command = 'subroutine.bat', wait = F, invisible = F)
system(command = 'subroutine_autoupload.bat', wait = F, invisible = F)

# Reserve some tasks to be completed. Take as many tasks as you have cores.

# PARALLEL once again. all settings combos / replicates are available to grab on server as per conversation on 2018-04-25.

reservedTasks = reserveTasks(numTasks = numTasks)

# Debug with large pop

# conLocal = dbConnect(SQLite(), 'settings.sqlite')
# 
# settingsLocal = dbGetQuery(conn = conLocal, statement = paste0('SELECT * FROM settings WHERE ntraps = 120 AND lam0 = 0.02 AND D = 0.5 LIMIT 20'))
# 
# dbDisconnect(conLocal)
# 
# reservedTasks = settingsLocal$taskID

# DEBUG PURPOSES
# reservedTasks = c(1,1001,2001,3001,4001)

while(length(reservedTasks) > 0){
    
  foreach(task = reservedTasks, .packages = c("Rcpp", "RSQLite", "DBI","SPIM")) %dopar% {
    runFunc(task)
    gc()
    }
  
  updateTaskCompleted(reservedTasks = reservedTasks)
  
  # Reserve some more tasks 
  reservedTasks = reserveTasks(numTasks = numTasks)
  
}

