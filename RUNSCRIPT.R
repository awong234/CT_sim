# UNDER CONSTRUCTION # UNDER CONSTRUCTION # UNDER CONSTRUCTION
# # # UNDER CONSTRUCTION # UNDER CONSTRUCTION # UNDER CONSTRUCTION


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


# Set up parallel backend. 

# You may customize the core load here. You will want to use more than 1 core
# for more efficiency, but if you need to work on other things, you may limit it
# to 2 cores, for example. When your computer is free, restart this process with
# as many cores as you have for max performance.

cores = detectCores() - 1 

registerDoParallel(cores = cores) 

# Extract Settings ------------------------------------------------------------------------------------

settings = writeSettings()

# Function `assign`s each column in `settings` to an object in the environment
extract = function(what){invisible(Map(f = function(x,y){assign(x = x, value = y, pos = 1)}, x = names(what), y = what))}

# How many replicates per settings combo?
nreps = 100

# Need a seed for each setting combo, for each replicate. Built to be larger than what we need, in case we want to run more reps per population. Upper limit is 1e3 reps.

seeds.df = data.frame("taskID" = rep(settings$taskID, each = 1e3), "seeds" = 1:(nrow(settings)*1e3))

# Analysis loop ----------------------------------------------------------------------------------------------------


# Reserve some tasks to be completed. 

# NOTE: Doing ONE task at a time. Parallelizing replicates.

# If we are doing replicates of tasks internally (that is, NOT one task
# per replicate per setting), it is better to take one setting combo at a time,
# and have the computer dedicate all of its resources to complete those `nreps`
# replicates because we are NOT saving those intermediate outputs, only a final
# summary of them.

# This means that the analysis can NOT be resumed after cancelling *within* a
# loop of `nreps` replicates. If you cancel it before those `nreps` analyses are
# done, the output file won't be generated and you will have to start over.

# Unless, however, we temporarily store outputs from `reps` < `nreps` replicates
# and then delete them once completed. That's an option.

# reservedTasks = reserveTasks(numTasks = 1) # NOT PARALLEL

# DEBUG PURPOSES
reservedTasks = c(1)

#while(length(reservedTasks) > 0){
  
  # Old loop structure. This was when each replicate of each setting had a taskID. 
  # items = foreach(i = reservedTasks) %dopar% {

  # New loop structure. Do one task (read: unique setting) at a time, and replicate `nreps` internally.
  # Parallelize HERE
  foreach(r = 1:nreps) %dopar% {
  
    settingsLocal = settings[reservedTasks,] # Extract settings for task reserved
    
    seeds = subset(seeds.df, taskID == reservedTasks)[r,2] # ONE seed per setting combo, per replicate.
    
    extract(settingsLocal) # Assign all components (p0, lam0, etc.) to scoped to FUNCTION environment - won't affect other tasks.
    
    # Generate trap array ---------------------------------------------------------------------------------
    X = build.cluster.alt(ntraps = nTraps, ntrapsC = ntrapsC, spacingin = spaceIn, spacingout = spaceOut)
    
    # Simulate activity centers ---------------------------------------------------------------------------
    
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
    reservedTasks = reserveTasks(numTasks = 1)
    
  }
  
# }



