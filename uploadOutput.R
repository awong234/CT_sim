# Upload to drive, test script

# WORKS, but takes a long, long time, even for two example .csv's. 

# Drag and drop is super fast and we won't be worrying about overwrites since
# all files will have unique names.

for(i in 1:2){
if(!require(googledrive)){install.packages('googledrive')}
}
googledrive::drive_auth()

# Example files
# write.csv(x = "test", file = 'test1.csv')
# write.csv(x = "test", file = 'test2.csv')

# files = c('test1.csv', 'test2.csv')

uploadFiles = function(outFolder, drivePath, par = F){
  
  # Get local files
  
  filePaths = dir(path = 'localOutput/', pattern = '.Rdata')
  
  # Check path format - must end in backslash
  lastChar = substr(drivePath, start = nchar(drivePath), stop = nchar(drivePath))
  if(!lastChar == '/'){drivePath = paste0(drivePath, '/')}

  # See what's already on the server
  message("Comparing existing files to local set . . . ")
  dirls = googledrive::drive_ls(path = drivePath)
  remoteFiles = dirls$name[grep(pattern = '.csv', x = dirls$name, ignore.case = T, perl = T)] # Will need to change based on what format we end up with.
  uploadIndex = (! filePaths %in% remoteFiles)

  if(all(!uploadIndex)){
    message("All files already uploaded")
    return(NULL)
    }

  filePaths = filePaths[uploadIndex]
  
  filePaths = paste0(outFolder, filePaths)
  
  message(paste0(length(filePaths), " files to be uploaded."))

  if(length(filePaths) > 1){
  
    if(par){
      
      message(paste0("Uploading ", length(filePaths), " files in parallel . . ."))
      
      cl = makeCluster(parallel::detectCores())
      
      parLapply(cl = cl, X = filePaths, fun = function(f){googledrive::drive_upload(media = f, path = drivePath)})
      
      stopCluster(cl = cl)
      
    }else{
      
      message(paste0("Uploading ", length(filePaths), " files serially . . ."))
      
      # lapply(X = filePaths, FUN = function(f){googledrive::drive_upload(media = f, path = drivePath)})
      
      for(i in 1:length(filePaths)){
        googledrive::drive_upload(media = filePaths[i], path = drivePath)
        message(paste0('Uploading file ', i, ' of ', length(filePaths), ' at ', Sys.time()))
      }
      
    }
    
  }else{
    
    message("Uploading 1 file . . .")
    
    googledrive::drive_upload(media = filePaths, path = drivePath)
    
  }
  message(paste0("Upload of ", length(filePaths), " file(s) complete at ", Sys.time()))
  
  }
  


# uploadFiles(files, 'Archive/CT_sim_outputs/')