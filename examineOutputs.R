library(dplyr)
library(doParallel)
library(ggplot2)

load('settings_v2.Rdata')

settings = newSettingsTable; rm(newSettingsTable)

files = dir(path = 'localOutput/',pattern = '.Rdata', full.names = T)

# Get task ID's from file names

taskIDs = regmatches(x = files, m = 
             regexpr(pattern = '\\d+', text = files, perl = T)
) %>% as.integer

# taskIDsOrder = order(taskIDs)
# 
# taskIDs_sorted = taskIDs[taskIDsOrder]
# files_sorted = files[taskIDsOrder]

getData = function(files, index){
  
  load(files[index])
  
  estimate = tryCatch(expr = {
    estimate = exp(out$SCR$estimate[3])
    estimate = estimate + out$DATA$n
  },
  error = function(m){out = NA})
  
  N = out$DATA$N
  
  return(list("estimate" = estimate, "N" = N))
  
}

registerDoParallel(cores = 4)

outputsEstimates = foreach(i = seq_along(files), .combine = rbind) %dopar% {
  
  output = getData(files = files, index = i)
  
  Nhat = output$estimate
  
  taskID = taskIDs[i]
  
  fileName = files[i]
  
  N = output$N
  
  out.df = data.frame(Nhat = Nhat, N = N, taskID = taskID, fileName = fileName)
  
  return(out.df)
  
}

relevantSettings = settings %>% filter(taskID %in% taskIDs)

outEstSettings = outputsEstimates %>% left_join(relevantSettings, by = c("taskID" = "taskID")) %>% mutate(N_Diff = (Nhat - N)/N)

meanDifferences = outEstSettings %>% group_by(HASH) %>% summarize(meanDifference = mean(N - Nhat, na.rm = T))

settingsUnique = settings %>% select(-taskID, -replicate) %>% filter(!duplicated(settings %>% select(-taskID, -replicate)))

meanDifferences %>% dplyr::left_join(settingsUnique, by = c("HASH" = "HASH"))

outEstSettings %>% 
  ggplot() +
    geom_point(aes(x = nTraps, y = N_Diff)) + 
    theme_bw()
