library(dplyr)

# Settings for simulations
# This will be a data frame with 1 row per task, and columns specifying simulation settings. 
# Make vectors of all of the below, and expand.grid will automatically generate all combinations.

# Settings for trap design ----------------------------------

# It's a function to avoid all of the side effects from specifying the individual settings parameters.

writeSettings <- function(nreps) {
  
  # Number of traps
  nTraps = c(40, 80, 120)
  
  # Number of traps in a cluster
  ntrapsC = c(1,2,3,4,5,6,7,8)
  
  # Within cluster spacing
  spaceIn = c(0.5, 1, 1.5)
  
  # Among cluster spacing
  spaceOut = c(1.5, 2, 2.5)
  
  # Settings for population sim -------------------------------
  
  # sigma - Ben mentioned that since spacing is relative to sigma, this needs not be varied.
  sigma = 0.5
  
  # lam0
  lam0 = c(0.4)
  
  # K
  K = 5
  
  # Density
  D = c(0.1, 0.25, 0.5)
  
  # Buffer
  buff = 3
  
  # thinning.rate1
  thinRate1 = c(0.7)
  
  # thinning.rate2
  thinRate2 = c(0.7)
  
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
  
  settingsLong = settings[rep(1:nrow(settings), each = nreps),] %>% cbind.data.frame(., "replicate" = 1:nreps, "taskID" = 1:nrow(.)) %>% 
    select(taskID, settingID, replicate, nTraps:grid.space)
  
  return(settingsLong)
  
}

settings = writeSettings(nreps = 100)