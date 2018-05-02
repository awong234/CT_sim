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

setWDHere = function(){
  sourcePath<-rstudioapi::getSourceEditorContext()$path[1]  # gets the location of the script that this piece of code is in
  sourceLoc<-strsplit(sourcePath, "/RUNSCRIPT")[[1]][1] # get the parent folder
  setwd(sourceLoc) # set the wd to the parent folder
}

setWDHere()

# Preparation block ------------------------------------------------------------------------------------------------------------------------------

if(!require(doParallel)){install.packages('doParallel')}
if(!require(googledrive)){install.packages('googledrive')}
if(!require(parallel)){install.packages('parallel')}
if(!require(Rcpp)){install.packages('Rcpp')}
if(!require(devtools)){install.packages('devtools')}

# Install spim package. If you do it this way, you will need to install Rtools
# v3.4 (find_rtools() Checks for this). Link in github front page.

if(!require(SPIM) & find_rtools()){install_github('benaug/SPIM')}

source('writeSettings.R')
source('build.cluster.R')
source('simSCR.R')
source('functionsSQL.R')

# Setup block ----------------------------------------------------------------------------------------------------------------------------------------

# Set up parallel backend. 

# You may customize the core load here. You will want to use more than 1 core
# for more efficiency, but if you need to work on other things, you may limit it
# to 2 cores, for example. When your computer is free, restart this process with
# as many cores as you have for max performance.

cores = detectCores() - 1 

# How many tasks to do at once?
numTasks = cores

registerDoParallel(cores = cores) 

# Automatic uploads? WARNING: VERY SLOW

# First time run will take you to a web page to authorize `googledrive` to
# access your drive account. You will want to make sure to have CT_sim_outputs
# already in your drive in the top-most directory!

autoUpload = F

if(autoUpload){source('uploadOutput.R')}

files = dir(path = 'localOutput/', pattern = ".Rdata")

# Where did you put the shared folder in your drive?
drivePath = 'CT_sim_outputs/'


# Extract Settings ------------------------------------------------------------------------------------

source('writeSettings.R') # now writes directly to prevent accidental changes to nreps.

# Function `assign`s each column in `settings` to an object in the environment
extract = function(what){invisible(Map(f = function(x,y){assign(x = x, value = y, pos = 1)}, x = names(what), y = what))}


# Analysis loop ----------------------------------------------------------------------------------------------------

# Reserve some tasks to be completed. Take as many tasks as you have cores.

# PARALLEL once again. all settings combos / replicates are available to grab on server as per conversation on 2018-04-25.

reservedTasks = reserveTasks(numTasks = numTasks)

# DEBUG PURPOSES
# reservedTasks = c(1,1001,2001,3001,4001)

while(length(reservedTasks) > 0){
  
  runFunc = function(task){
    
    # Will source with Ben's SPIM package - otherwise source here.
    if(!require(SPIM)){sourceCpp("intlikRcpp.cpp")}
  
    # Check for tasks already done (if job cancelled)
    files = dir(path = 'localOutput', pattern = ".Rdata")
    matches = (regmatches(x = files, m = gregexpr(pattern = '\\d+', text = files, perl = T)))
    done = do.call(what = rbind, args = lapply(matches, as.integer))
    
    if(task %in% done){return(paste("Task", task, "was already completed"))}
  
    settingsLocal = settings[task,] # Extract settings for task reserved
    
    extract(settingsLocal) # Assign all components (D, lam0, etc.) to scoped to FUNCTION environment - won't affect other tasks.
    
    # Generate trap array ---------------------------------------------------------------------------------
    X = build.cluster.alt(ntraps = nTraps, ntrapsC = ntrapsC, spacingin = spaceIn, spacingout = spaceOut)
    
    # Simulate activity centers ---------------------------------------------------------------------------
    
    # Right now all done in simSCR()
    
    # Simulate encounters ---------------------------------------------------------------------------------
    # This is actually SCR AND OCC data. Look at the return values in the simSCR.R script to see why.
    scrData = simSCR(D = D, lam0 = lam0, sigma = sigma, K = K, X = X, buff = buff, thinning.rate1 = thinRate1, thinning.rate2 = thinRate2, grid.space = grid.space, seed = task)
    
    # I am deciding not to save data since all data can be generate at a later time using the settings grid and the seeds.
    
    # Gather data into analysis tool (occupancy and SCR) --------------------------------------------------
    
    # Format properly
    
    # SCR analysis
    
    scrAnalysis = function(data){
      
      y=apply(data[['y.scr']],c(1,2),sum)
      n=data[['n']]
      N = data[['N']]
      buff = data[['buff']]
      K = data[['K']]
      parm=c(log(thinRate2),log(sigma),log(N-nrow(y)))
      delta=0.25 #state space spacing
      #make state space
      Xl <- min(X[, 1]) - buff
      Xu <- max(X[, 1]) + buff
      Yu <- max(X[, 2]) + buff
      Yl <- min(X[, 2]) - buff
      xg <- seq(Xl + delta/2, Xu - delta/2, delta)
      yg <- seq(Yl + delta/2, Yu - delta/2, delta)
      npix.x <- length(xg)
      npix.y <- length(yg)
      G <- cbind(rep(xg, npix.y), sort(rep(yg, npix.x)))
      #distance btw all SS points and all traps
      distmat <- e2dist(X, G)
      #append uncaptured history (all zeros) to capture history
      ymat <- y
      ymat <- rbind(y, rep(0, ncol(y)))
      
      out.intRcpp = nlm(intlikRcpp, parm, ymat = ymat, X = as.matrix(X), K = K, G = G, D = distmat, n = n, print.level=2, hessian=TRUE)
      
      return(out.intRcpp)
      
    }
    
    # OCC analysis
    
    occAnalysis = function(data){
      y=data[['y.occ']]
      K=data[['K']]
      #LL function from Applied Hierarchical Models book page 43.
      parm=c(qlogis(0.5),qlogis(0.5)) #starting values p=0.4, psi=0.9
      negLogLikeocc=function(parm,y,K){
        p=plogis(parm[1])
        psi=plogis(parm[2])
        marg.like=dbinom(y,K,p)*psi+ifelse(y==0,1,0)*(1-psi)
        return(-sum(log(marg.like)))
      }
      #fit occupancy model 
      occ.out=nlm(negLogLikeocc,parm,y=y,K=K,hessian=TRUE)
    }
    
    # One at a time
    
    out.intRcpp = tryCatch(expr = {scrAnalysis(data = scrData)},
             error = function(e){e})
  
    out.occ = tryCatch(expr = {occAnalysis(data = scrData)},
             error = function(e){e})
    
    # out.intRcpp = scrAnalysis(data = scrData)
    # out.occ = occAnalysis(data = scrData)
    
    # perform simultaneously . . . ? CAN'T EXPORT RCPP FUNCTION WITHOUT COMPILING ON EACH WORKER NODE.
      
    # analyses = list("scrAnalysis", "occAnalysis")
    # 
    # # lapply(X = analyses, FUN = function(m){do.call(m, list(scrData))})  # works....but parallel version doesn't
    # 
    # cl = makeCluster(2)
    # 
    # clusterExport(cl = cl, varlist = c("analyses", "scrAnalysis", "occAnalysis", "scrData", "thinRate2", "sigma", "X", "e2dist", "intlikRcpp"), envir = environment())
    # 
    # out = clusterMap(cl = cl, fun = function(m,x){do.call(m, list(x))}, m = analyses, x = list(scrData), RECYCLE = T, SIMPLIFY = F)
    # 
    # stopCluster(cl = cl)
    
    
    # Write result to output directory of choice. Wrapping into function allows separate writes.
    
    if(!dir.exists("localOutput/")){
      dir.create("localOutput/")
    }
    
    out = list(SCR = out.intRcpp, OCC = out.occ, DATA = scrData)
    
    save(out, file = paste0("localOutput/out_task_", task, ".Rdata"))
    
    # Note completion on server
    updateTaskCompleted(reservedTasks = task)
    
    return(paste("Task", task, "now complete and saved to file"))
    
    
  }
  
  foreach(task = reservedTasks, .packages = c("Rcpp", "DBI","SPIM")) %dopar% {runFunc(task)}
  
  # Reserve some more tasks 
  reservedTasks = reserveTasks(numTasks = numTasks)
  
  if(autoUpload){uploadFiles(filePaths = paste0('localOutput/',files), drivePath = drivePath, par = F)}
  
}

