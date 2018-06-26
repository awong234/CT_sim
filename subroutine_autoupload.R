# Upload to drive, test script

for(i in 1:2){
  if(!require(boxr)){devtools::install_github('awong234/boxr')}
  if(!require(dplyr)){install.packages('dplyr')}
}

# Check for latest version of boxr
devtools::install_github('awong234/boxr')

ID_lines = readLines(con = 'app.cfg')

clientID = ID_lines[1]
clientSecret = ID_lines[2]

auth = box_auth(client_id = clientID, client_secret = clientSecret)

subrt_upload = function(){
  
  repeat{
    
    message(paste0('Obtaining directory from Box folder at ', Sys.time() %>% format('%H:%M:%S')))
    
    existing = NULL
    attempt = 1
    
    while(is.null(existing)){
      message(paste0("Attempting to retrieve list . . . attempt number ", attempt, " at ", Sys.time() %>% format('%H:%M:%S')))
      try({
        existing = box_ls(dir_id = 48978104905, fields = 'name', limit = 1000)
      })
      attempt = attempt + 1
    }
    
      
    existing = sapply(X = existing, FUN = `[`, 'name') %>% unlist
    
    message(paste0('Obtaining set of local files at ', Sys.time() %>% format('%H:%M:%S')))
    
    localFiles = list.files('localOutput/', full.names = T)
    
    localFiles_names = strsplit(localFiles, split = '/') %>% sapply(FUN = `[`, 2)
    
    message(paste0('Comparing remote to local set at ', Sys.time() %>% format('%H:%M:%S')))
    
    toUpload = localFiles[!localFiles_names %in% existing]
    
    if(length(toUpload) == 0){
      
      message(paste0('No new files to upload. ', Sys.time() %>% format('%H:%M:%S')))
      
    }else{
      
      message(paste0('Began upload of ', length(toUpload),' files at ', Sys.time() %>% format('%H:%M:%S')))
      
      for(file in 1:length(toUpload)){
        
        test = NULL
        while(is.null(test)){
          try(expr = {
            test = box_ul(dir_id = 48978104905, file = toUpload[file], pb = F)
          })
        }
        message(paste0('Uploaded ', toUpload[file],': ', file, ' of ', length(toUpload), ' at ', Sys.time() %>% format('%H:%M:%S')))
      }
      
      message(paste0('Finished upload of ', length(toUpload),' files at ', Sys.time() %>% format('%H:%M:%S'), '. Restarting.'))
      
    }
    

    # boxr_timediff <- function(x) paste0("took ", format(unclass(x), digits = 3), " ", attr(x, "units"))
    # 
    # f <- x$file_list
    # 
    # tdif <- boxr_timediff(x$end - x$start)
    # 
    # message(paste0("\nboxr ", x$operation, " operation\n\n"))
    # 
    # message(paste0(
    #   "  User           : ", getOption("boxr.username"), "\n",
    #   "  Local dir      : ", x$local_tld,                "\n",
    #   "  box.com folder : ", x$box_tld_id,               "\n",
    #   "  started at     : ", x$start , " (", tdif, ")",  "\n",
    #   "\n"
    # ))
    # 
    # message(paste(summarise_ops(x$file_list, x$msg_list)))
    
    Sys.sleep(5)
    
  }
  
}

subrt_upload()
