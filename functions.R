# Host for functions used in camera trapping simulation.

# Main script will have a `while` function looping until there are no more tasks to be completed. 

# Remote task read/write section ---------------------------------------------------------------------------------------------------------------------------------------------

# Need a function to read task ID's, whether in progress, whether output saved (or code with error), and owner

taskIN = function(testTask = FALSE, debug = FALSE, taskPath = '../CT_sim_tasks/taskList.csv'){
  
  # Generate test task list
  
  if(testTask){
    testTaskList = data.frame("taskID" = seq(from = 1, to = 100), "inProgress" = 0, "completed" = 0, "owner" = NA)
    testTaskList = rbind.data.frame(testTaskList, data.frame("taskID" = c(101,102), "inProgress" = c(1,1), "completed" = c(0,0), "owner" = c(Sys.info()['nodename'], "other")))
    row.names(testTaskList) = NULL
    write.csv(testTaskList, file = 'taskList.csv')
    rm(testTaskList)
  }
  
  nName = Sys.info()['nodename'] # Reports name of computer
  
  # # # # Update task list from repo # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
  
  # Where is the repo stored? MUST store it in same directory as main repo.
  
  pathToTasks = normalizePath('../CT_sim_tasks/')
  
  shell(cmd = paste0("cd ", "\"", pathToTasks, "\"", " & pull.sh"))
  
  
  
  # # # # Check to see if tasks taken by computer are not done yet - in event of unexpected shutdowns. # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
  
  taskList = read.csv(file = taskPath)
  
  # Is your computer 'working on' an event at the time of this check? If so, it never finished from the previous startup.
  resetIndex = nName == taskList$owner & taskList$inProgress == 1 
  
  # So, set inProgress to 0, and owner to NA, freeing up the task. 
  
  taskList$inProgress[resetIndex] = 0
  taskList$owner[resetIndex] = NA
  
  
  
  # # # # Take free tasks # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
  
  
  
  
  
  
  
  # # # # Push update to server # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
  if(!debug) taskOut(taskList)
  
  return(taskList)
  
}


# Need a function to write data to remote file. 

taskOut = function(dataToWrite){
  
  # Intention here is to call a .sh bash script to push changes directly to a
  # Git repo hosting only the task list.
  
  pathToTasks = normalizePath('../CT_sim_tasks/')
  
  shell(cmd = paste0("cd ", "\"", pathToTasks, "\"", " & pushTasks.sh"))
  
  return(NULL)
  
}


# Need a function to select a few tasks

taskSelect = function(taskList, numTasks = NULL){
  
  # Under construction
  
  if(is.null(numTasks)) numTasks = parallel::detectCores() # Default to number of cores.
  
  freeTaskIndex = taskList$inProgress == 0 & taskList$completed == 0 # Which tasks are {NOT in progress AND NOT complete}
  
  freeTasks = taskList$taskID[freeTaskIndex][1:numTasks] # Take first numTasks tasks
  
}

# Design section ---------------------------------------------------------------------------------------------------------------------------------------------------------

# Need functions for arbitrary specification of designs.

# Perhaps a general algorithm is not feasible; since there are numerous ways to
# orient many points in space, the designation of "a cluster of 10" is likely to
# be arbitrary. Perhaps just pick a few cluster designs and use a switch
# function to select.

getDesign = function(sigma = 1, noTraps, noClust, xlim, ylim){
  
  # Under construction
  
  # State space will be a set of limiting values for a rectangle
  
  # My opinion is that we should simulate within the set of {2, 4, 5, 10, 20,
  # 25, 50} clusters to avoid arbitrary placement of singular traps. The effect
  # of optimal placement of singular traps will confound interpretation, I
  # think, and the marginal effect of a singular trap elsewhere in a grid
  # barring some adaptive process is likely very small.
  
  # Need algorithm to create a cluster of equally spaced traps 
  
  # Probably want a rectangular, or hexagonal(|triangular) approach, allowing
  # compact structures that are also equidistant.
  
  trapsPerClust = noTraps / noClust
  
  
  
  
  return(NULL)
  
}

makeTriCluster = function(noPoints,spacing){
  
  # Under construction
  
  # Make cluster in triangular grid fashion
  points = matrix(data = NA, nrow = nPoints, ncol = 2)
  
  return(points)
  
}

makeRectCluster = function(){
  
  # Under construction
  
  # Make cluster in rectangular fashion
  
  points = matrix(data = NA, nrow = nPoints, ncol = 2)
  
  return(points)
  
}


# Deprecated -------------------------------------------------------------------------------------------------------------------------------------

makeVogelCluster = function(noPoints, angle = NULL){
  
  # Makes a cluster of roughly equidistant points inside a unit disc.
  # Probably not great use for small number of points.
  # Probably hard to constrain within-cluster distances.
  
  if(is.null(angle)){angle = pi * (3 - sqrt(5))}
  
  points = matrix(data = NA, nrow = noPoints, ncol = 2)
  
  for(p in 1:noPoints){
    
    theta = p * angle
    r = sqrt(p) / sqrt(noPoints)
    points[p,] = c(r*cos(theta), r*sin(theta))
  }
  
  return(points)
  
  
}
