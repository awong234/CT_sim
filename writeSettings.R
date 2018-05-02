if(!require(dplyr)){install.packages('dplyr')}

# Settings for simulations
# This will be a data frame with 1 row per task, and columns specifying simulation settings. 
# Make vectors of all of the below, and expand.grid will automatically generate all combinations.

# Settings for trap design ----------------------------------

# It's a function to avoid all of the side effects from specifying the individual settings parameters.

writeSettings <- function(nreps) {
  
  # Number of traps
  nTraps = c(40, 80, 120)
  
  # Number of traps in a cluster
  ntrapsC = c(1,2,3,4,5,6,7,8,9,10,12,15,16,20)
  
  # Within cluster spacing
  spaceIn = c(0.5,0.6, 0.7, 0.8,0.9 ,1, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9,
2.0, 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9, 3.0)
  
  # Among cluster spacing
  spaceOut = c(1.5, 1.75, 2, 2.25, 2.5, 2.75, 3.0, 3.25, 3.5)
  
  # Settings for population sim -------------------------------
  
  # sigma - Ben mentioned that since spacing is relative to sigma, this needs not be varied.
  sigma = 1.0
  
  # lam0
  lam0 = c(0.005, 0.01, 0.02)
  
  # K
  K = 60
  
  # Density
  D = c(0.01, 0.20, 0.5)
  
  # Buffer
  buff = 3
  
  # thinning.rate1
  thinRate1 = c(0.6)
  
  # thinning.rate2
  thinRate2 = c( 0.8)
  
  # Grid spacing
  
  gridSpace = c(0.5)
  
  
  # Expand all combos ---------------------------------------------------------------------------------------------------
  
  settings = expand.grid(nTraps = nTraps, 
                         ntrapsC = ntrapsC, 
                         spaceIn = spaceIn, 
                         spaceOut = spaceOut, 
                         sigma = sigma, 
                         lam0 = lam0, 
                         K = K,
                         D = D, 
                         buff = buff, 
                         thinRate1 = thinRate1, 
                         thinRate2 = thinRate2, 
                         grid.space = gridSpace)
  
  attr(settings, which = c("out.attrs")) = NULL
  
  # any(settings %>% duplicated()) # No duplicates
  
  settings = settings %>% mutate(settingID = seq(1,nrow(.)))
  
  # NOW duplicate nreps times
  
  settingsLong = settings[rep(1:nrow(settings), each = nreps),] %>% cbind.data.frame(., "replicate" = 1:nreps) %>% arrange(replicate, settingID) %>% cbind.data.frame("taskID" = 1:nrow(.)) %>% 
    select(taskID, settingID, replicate, nTraps:grid.space)
  
  return(settingsLong)
  
}

settings = writeSettings(nreps = 500)