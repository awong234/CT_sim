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

source('build.cluster.R')
source('simSCR.R')
source('functionsSQL.R')

# Register user names with computer names
userName = if(!dir.exists("username.txt")){
  name = registerUser()
  write.table(name, file = 'username.txt', row.names = F, col.names = F)
}else{NULL}

numTasks = detectCores() - 1 # how many concurrent analyses to be done?

registerDoParallel(cores = numTasks) # editable with numTasks

# Extract Settings ------------------------------------------------------------------------------------

extract = function(what){invisible(Map(f = function(x,y){assign(x = x, value = y, envir = .GlobalEnv)}, x = names(what), y = what))}

# Example
# Read in settings table
settings = read.csv(file = 'settings.csv', stringsAsFactors = F)

extract(settings[1,])

# Reserve some tasks to be completed.
reservedTasks = reserveTasks(numTasks = numTasks)

while(reservedTasks > 0){
  
  foreach(i = reservedTasks, .export = c("updateTaskCompleted", "simSCR", "build.cluster.alt", "extract")) %dopar% {
    
    settingsLocal = settings[i,] # Extract settings for task i
    
    extract(settingsLocal) # Assign all components (p0, lam0, etc.) to scoped to FUNCTION environment - won't affect other tasks.
    
    # Generate trap array ---------------------------------------------------------------------------------
    X = build.cluster.alt(ntraps = nTraps, ntrapsC = ntrapsC, spacingin = spacingin, spacingout = spacingout)
    
    # Simulate activity centers ---------------------------------------------------------------------------
    
    # Either a fixed population per design choice, or fully random populations 
    # Right now all done in simSCR()
    
    # Simulate encounters ---------------------------------------------------------------------------------
    scrData = simSCR()
    
    # Gather data into analysis tool (occupancy and SCR) --------------------------------------------------
    
    # Format properly . . . 
    
    # Perform analysis . . . 
    
    # ANALYSIS i . . . 
    
    # Write result to output directory of choice . . . 
    
    # Note completion on server
    updateTaskCompleted(reservedTasks = i)
    
    # Reserve some more tasks 
    reservedTasks = reserveTasks(numTasks = numTasks)
    
  }
  
}



