# Upload to drive, test script

source('autoUploadResource.R')

for(i in 1:2){
  if(!require(boxr)){install.packages('boxr')}
}

ID_lines = readLines(con = 'app.cfg')

clientID = ID_lines[1]
clientSecret = ID_lines[2]

auth = box_auth(client_id = clientID, client_secret = clientSecret)

subrt_upload = function(){
    
  repeat{
    
    x = box_push(dir_id = 48978104905, local_dir = 'localOutput', overwrite = F, delete = F)
    
    boxr_timediff <- function(x) paste0("took ", format(unclass(x), digits = 3), " ", attr(x, "units"))
    
    f <- x$file_list
    
    tdif <- boxr_timediff(x$end - x$start)
    
    message(paste0("\nboxr ", x$operation, " operation\n\n"))
    
    message(paste0(
      "  User           : ", getOption("boxr.username"), "\n",
      "  Local dir      : ", x$local_tld,                "\n",
      "  box.com folder : ", x$box_tld_id,               "\n",
      "  started at     : ", x$start , " (", tdif, ")",  "\n",
      "\n"
    ))
    
    message(paste(summarise_ops(x$file_list, x$msg_list)))
    
    Sys.sleep(5*60)
    
  }
  
}

subrt_upload()
