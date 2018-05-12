source('uploadOutput.R')

subrt_upload = function(){
    
  repeat{
    
    uploadFiles(filePaths = 'localOutput/', drivePath = 'Archive/CT_sim_outputs/')
    
    Sys.sleep(5*60)
    
  }
  
}

subrt_upload()
