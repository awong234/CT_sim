# Overview

The contents here aim to simulate encounters of animals under varied survey designs using clustered point detectors of a fixed sampling effort. The simulated data will be analyzed using spatial capture-recapture and occupancy modeling. 

The output from the analyses will be compared to obtain the most effective designs for occupancy analysis, SCR analysis, and potentially both. 

## For analysis participants:

**NOTE: I can only guarantee that these functions will work on WINDOWS, particularly the database functions. For those who do not use Windows, I will not effectively be able to debug any issues.**

When the first production run of the procedure is to be implemented, you will need only execute the contents in `RUNSCRIPT.R`. To do so, open the file in R, highlight all of the contents in the file, and hit `run`. 

For those curious, you may use the Shiny app `taskMonitor.R` to observe the work that all the computers are doing. You will need to have the `shiny` library to execute, but the app will launch from either R or Rstudio. It will open a browser window with multiple tabs to observe the processes at work. 

# Files contained

## assets\

This folder hosts various graphics germane to the project.

## localOutput\

This folder will be automatically created when you execute `RUNSCRIPT.R`, and will host local copies of the analysis outputs.

## rmd\

This folder hosts Rmarkdown files used to edit the Wiki page. 

## Main folder

### .gitignore

This file indicates what files are to be ignored by Git.

### build.cluster.R

Functions included to build clustered traps. There is an older function `build.cluster()` that develops square clusters only, and a newer one `build.cluster.alt()` that develops clusters of irregular arrangements. 

#### Arguments 

Since we will most likely use `build.cluster.alt()` in the production run, I list the arguments for that function here.

* ntraps    : The number of traps TOTAL.
* ntrapsC   : The number of traps *per cluster*.
* spacingin : The spacing among traps *within* a cluster.
* spacingout: The spacing among clusters.
* plotit    : Whether to plot the clusters - default is FALSE.

### functionsSQL.R

Functions contained to execute SQL transactions to update tasks to be completed. Included are functions:

* `reserveTasks`         : Will reserve a set of `numTasks` tasks.
* `updateTasksCompleted` : Will update the tasks previously reserved as completed.
* `printDB`              : Will print a record of the task database.
* `registerUser`         : Will register a user name with a machine name to a separate database.
* `executeWithRestart`   : Executes SQL transactions with automatic restarts. 

`RUNSCRIPT.R` sources this file. 

### intlikRcpp.cpp

C++ implementation of SCR likelihood calculation

### nullSCR testscript.R

TEMPORARY

Test for application of analytical tools to multiple simulated sampling scenarios.

### RUNSCRIPT.R

This will be the script that users will ultimately execute to participate in the analyses. It has major components that are outlined at the start of the script.

### SCRdesignSIM.R

This file is the original script provided by Andy trialing the basic idea for the simulation.

### simOcc.R

Simulates some occupancy data under parameters:

* `p`     : detection probability.
* `psi`   : occupancy probability.
* `J`     : Number of sites.
* `K`     : Number of occasions.
* `seed`  : Seed for replication.

### simSCR.R

Function to simulate SCR and occupancy data. See the [Wiki page on the function](https://github.com/awong234/CT_sim/wiki/Simulation-Function-\(simSCR.R\)) for a detailed, step-by-step walkthrough.

### taskMonitor.R

This is a Shiny app that will automatically launch a browser window. The purpose is to monitor the completion of tasks over time and provide a rough estimate of completion time. There are three tabs:

#### Full table

This page displays the full table of tasks as well as some brief metrics such as machine name, time started, time ended, and duration of analysis.

#### Compute statistics

This page displays some charts for the distribution of tasks taken by user, and the time efficiency of the machines. 

#### Compute time estimate

This page displays the start/end times of each task graphically, and a linear trend of the form (taskIndex ~ timeEnded) is assessed over tasks for prediction of the date of completion. 

### writeSettings.R

This file, when sourced, will write a record of all the proposed settings to memory. This is used in `RUNSCRIPT.R`