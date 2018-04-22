# Main script housing preparation of data, analysis of data, and exporting analysis elements.

# Sections 

# Preparation
  # Extract settings
  # Generate grids
  # Generate SCR data
  # Generate OCC data
# Analysis
  # Analyze data under SCR
  # Analyze data under OCC
  # Export analysis elements

library(doParallel)

source('writeSettings.R')
source('build.cluster.R')
source('simSCR.R')
source('functionsSQL.R')

numTasks = detectCores() - 1 # how many concurrent analyses to be done?

registerDoParallel(cores = numTasks) # editable with numTasks

# Extract Settings ------------------------------------------------------------------------------------

settings = writeSettings()

# Function `assign`s each column in `settings` to an object in the environment
extract = function(what){invisible(Map(f = function(x,y){assign(x = x, value = y, pos = 1)}, x = names(what), y = what))}

# Reserve some tasks to be completed.
# reservedTasks = reserveTasks(numTasks = numTasks)

# DEBUG PURPOSES
reservedTasks = c(1,5400,930)

#while(length(reservedTasks) > 0){
  
  items = foreach(i = reservedTasks) %dopar% {
  
    settingsLocal = settings[i,] # Extract settings for task i
    
    extract(settingsLocal) # Assign all components (p0, lam0, etc.) to scoped to FUNCTION environment - won't affect other tasks.
    
    # Generate trap array ---------------------------------------------------------------------------------
    X = build.cluster.alt(ntraps = nTraps, ntrapsC = ntrapsC, spacingin = spaceIn, spacingout = spaceOut)
    
    # Simulate activity centers ---------------------------------------------------------------------------
    
    # Either a fixed population per design choice, or fully random populations 
    # Right now all done in simSCR()
    
    # Simulate encounters ---------------------------------------------------------------------------------
    scrData = simSCR(D = D, lam0 = lam0, sigma = sigma, K = K, X = X, buff = buff, thinning.rate1 = thinRate1, thinning.rate2 = thinRate2, grid.space = grid.space, seed = seeds)
    
    return(scrData)
    
    # Verified separate settings data passing into function.
    
    # Write components of sim dataset to file?
    
    # Gather data into analysis tool (occupancy and SCR) --------------------------------------------------
    
    # Format properly . . . 
    
    # Perform analysis . . . 
    
    # ANALYSIS i . . . 
    
    # Write result to output directory of choice . . . 
    
    if(!dir.exists("localOutput/")){
      dir.create("localOutput/")
    }
    
    # Note completion on server
    updateTaskCompleted(reservedTasks = i)
    
    # Reserve some more tasks 
    reservedTasks = reserveTasks(numTasks = numTasks)
    
  }
  
# }



