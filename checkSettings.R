library(doParallel)

source('build.cluster.R')
source('simSCR.R')

if(!exists('settings')){load('settings.Rdata')}

registerDoParallel(cores = detectCores())

extract = function(what){invisible(Map(f = function(x,y){assign(x = x, value = y, pos = 1)}, x = names(what), y = what))}

runFunc = function(task){
  
  settingsLocal = settings[task,] # Extract settings for task reserved
  
  extract(settingsLocal) # Assign all components (D, lam0, etc.) to scoped to FUNCTION environment - won't affect other tasks.
  
  # Generate trap array ---------------------------------------------------------------------------------
  X = build.cluster.alt(ntraps = nTraps, ntrapsC = ntrapsC, spacingin = spaceIn, spacingout = spaceOut)
  
  # Simulate activity centers ---------------------------------------------------------------------------
  
  # Right now all done in simSCR()
  
  # Simulate encounters ---------------------------------------------------------------------------------
  # This is actually SCR AND OCC data. Look at the return values in the simSCR.R script to see why.
  
  seed = task
  
  scrData = simSCR(D = D, lam0 = lam0, sigma = sigma, K = K, X = X, buff = buff, thinning.rate1 = thinRate1, thinning.rate2 = thinRate2, grid.space = grid.space, seed = seed)
  
  test = scrData$sumscap >= 1
  
  return(cbind.data.frame("TaskID" = task, "SettingNo" = settingID, "RepNo" = replicate, "Test" = test, "SCAPS" = scrData$sumscap))
  
}

test = foreach(task = 1:(nrow(settings)), .combine = rbind) %do% {runFunc(task)}

save(test, 'checkSettings.Rdata')
