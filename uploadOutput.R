# Upload to drive, test script

# WORKS, but takes a long, long time, even for two example .csv's. 

# Drag and drop is super fast and we won't be worrying about overwrites since
# all files will have unique names.

if(!require(googledrive)){install.packages('googledrive')}

googledrive::drive_auth()

# Example files
write.csv(x = "test", file = 'test1.csv')
write.csv(x = "test", file = 'test2.csv')

files = c('test1.csv', 'test2.csv')

uploadFiles = function(filePaths, drivePath){
  
  # Check path format - must end in backslash
  lastChar = substr(drivePath, start = nchar(drivePath), stop = nchar(drivePath))
  if(!lastChar == '/'){drivePath = paste0(drivePath, '/')}

  # See what's already on the server
  dirls = googledrive::drive_ls(path = drivePath)
  remoteFiles = dirls$name[grep(pattern = '.csv', x = dirls$name, ignore.case = T, perl = T)] # Will need to change based on what format we end up with.
  uploadIndex = (! filePaths %in% remoteFiles)

  if(all(!uploadIndex)){
    message("All files already uploaded")
    return(NULL)
    }

  filePaths = filePaths[uploadIndex]

  if(length(filePaths) > 1){
    
    cl = makeCluster(parallel::detectCores())
    
    parLapply(cl = cl, X = filePaths, fun = function(f){googledrive::drive_upload(media = f, path = drivePath)})
    
    stopCluster(cl = cl)
    
  }else{
    
    googledrive::drive_upload(media = filePaths, path = drivePath)
    
  }
  message("Upload complete")
}

uploadFiles(files, 'Archive/CT_sim_outputs/')