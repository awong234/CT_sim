source('uploadOutput.R')

subrt_upload = function(){
  
  i = "test"
  
  repeat{
    
    message(i)
    
    uploadFiles(outFolder = 'localOutput/', drivePath = 'Archive/CT_sim_outputs/')
    
    Sys.sleep(5*60)
    
  }
  
}

subrt_upload()
