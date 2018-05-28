setWDHere = function(){
  sourcePath<-rstudioapi::getSourceEditorContext()$path[1]  # gets the location of the script that this piece of code is in
  sourceLoc<-strsplit(sourcePath, "/SETUP.R")[[1]][1] # get the parent folder
  setwd(sourceLoc) # set the wd to the parent folder
}

setWDHere()

# SETUP file to be run on the first time of analysis or when new versions are pushed to the github.

# For ease of use, install SPIM manually using the Tools > Install Packages Dialog.

for(i in 1:2){
  # Install and load LOCAL database stuff.
  if(!require(RSQLite)){install.packages('RSQLite')}
  if(!require(dbplyr)){install.packages('dbplyr')}
  if(!require(dplyr)){install.packages('dplyr')}
  if(!require(Rcpp)){install.packages('Rcpp')}
}

# Write settings as per iteration 1, for new computers - only if settings.sqlite DNE.

source('writeSettings.R')

if(!file.exists('settings.sqlite')){
  
  # Get settings list
  settings = writeSettings_iter_1(nreps = 500)
  
  # Have moved away from the .Rdata file.
  # save(list = c("settings"), file = 'settings.Rdata')
  
  # Open local sql connection
  con = dbConnect(SQLite(), 'settings.sqlite')
  
  # Write settings list to connection
  dbWriteTable(conn = con, name = 'settings', value = settings)
  
  # Close connection
  dbDisconnect(conn = con)
  
}


##### Write new settings table as per discussion on May 20. #######

if(!file.exists('settings_v2.sqlite')){
  
  newSettings_full = writeSettings_iter_2(nreps = 200)
  
  con = dbConnect(SQLite(), 'settings.sqlite')
  
  oldTable = dbReadTable(conn = con, name = 'settings')
  
  dbDisconnect(con)
  
  # Want everything up until task 335742. This is the last task completed during the pause in Memorial Day weekend.
  
  lastTask = 335742
  
  oldTable_portion = oldTable %>% filter(taskID <= lastTask) %>% select(taskID, nTraps : grid.space)
  oldTable_portion$HASH = apply(X = oldTable_portion[,2:13], MARGIN = 1, FUN = function(x){digest(x, algo = 'md5')})
  
  # Now we want to get everything after task 335742 that matches the new desired settings.
  
  # Rewrite the taskID's to start from the last task + 1
  
  newSettings_full$taskID = seq(lastTask+1, (nrow(newSettings_full)+lastTask))
  
  newSettings_full = newSettings_full %>% select(-settingID, -replicate)
  
  newSettingsTable = rbind.data.frame(oldTable_portion, newSettings_full)
  
  hashOrder = order(newSettingsTable$HASH, newSettingsTable$taskID)
  hashSorted = newSettingsTable$HASH[hashOrder]
  replicateVec = sapply(X = table(hashSorted) %>% as.integer, function(x){seq(1,x)}) %>% do.call(what = c, args = .)
  
  newSettingsTable$replicate[hashOrder] = replicateVec
  
  conLocal = dbConnect(SQLite(), 'settings_v2.sqlite')
  
  dbWriteTable(conn = conLocal, name = 'settings', value = newSettingsTable)
  
  dbDisconnect(conLocal)
  
  save(list = "newSettingsTable", file = 'settings_v2.Rdata')
  
  # End
  
}
