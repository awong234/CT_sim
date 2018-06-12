# Upload to drive, test script

for(i in 1:2){
  if(!require(boxr)){devtools::install_github('awong234/boxr')}
  if(!require(dplyr)){install.packages('dplyr')}
}

ID_lines = readLines(con = 'app.cfg')

clientID = ID_lines[1]
clientSecret = ID_lines[2]

auth = box_auth(client_id = clientID, client_secret = clientSecret)

subrt_upload = function(){
    
  repeat{
    
    existing = box_ls_short(dir_id = 48978104905)
      
    existing = sapply(X = existing, FUN = `[`, 'name') %>% unlist
    
    localFiles = list.files('localOutput/', full.names = T)
    
    localFiles_names = strsplit(localFiles, split = '/') %>% sapply(FUN = `[`, 2)
    
    toUpload = localFiles[!localFiles_names %in% existing]
    
    for(file in toUpload){
      box_ul(dir_id = 48978104905, file = file, pb = T)
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
    
    Sys.sleep(5*60)
    
  }
  
}

subrt_upload()
