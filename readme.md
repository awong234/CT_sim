# Instructions

## For analysis participants:

**NOTE: I can only guarantee that these functions will work on WINDOWS, particularly the database functions. For those who do not use Windows, I will not effectively be able to debug any issues.**

## START HERE

I suggest running these **ONE-BY-ONE** so you know exactly where you may encounter errors. This is also because the `registerUsers()` function is skipped over when running things in bulk.

### Preparation

You will need to install a few things before getting started, most importantly Ben's SPIM package. There are two ways to go about this.

#### From a zip file

This method is the easiest. There is a .zip file in the repo called `SPIM_0.1.zip`. 

Install the package using the `install.packages` dialog going through Tools > Install Packages > Install From > Package Archive File. Then select the .zip file. 

The package *should* install without issue.

#### Directly within R

If the former method doesn't work, try this.

You will need to install Rtools and then run some commands that are already in the script. 

Go get Rtools from the [link here](https://cran.r-project.org/bin/windows/Rtools/Rtools34.exe). This link will go get the installer immediately. Run the installer as you would any other installer.

Then, run the SETUP.R script (a new file). 

#### SETUP.R

This file builds the local SQL database to draw particular settings from. Run the whole script, and you will know that it has been successful if a file `settings.sqlite` of size 3GB shows up in your working directory. 

#### Preparation block

Once you have installed SPIM and run the SETUP.R file, **particularly on your first run** run each line of the preparation block one at a time. Each package will be installed if you don't have it, or loaded if you do. Make note of any errors. 

**Please** run `source(functionsSQL.R)` at the top, the program should ask you to register your netID or initials - just use one username for all your computers please! If you notice a mistake in your username, please adjust it by running 

```
registerUser(update = T)
```

## Running the program - **RUNSCRIPT.R**

Once you've installed the SPIM package and all the other requisite packages, you will need **only** to execute the contents in `RUNSCRIPT.R`. 

To do so, open the file in R and just hit the source button up top. You can also run the document interactively, but I'd prefer you source it, so that there are no mistakes selecting lines.

![](https://github.com/awong234/CT_sim/blob/master/assets/sourceButton.png)

### Monitors

You will see things output into the `localOutput` folder as they are completed. For those who are more curious, you may use the Shiny app `taskMonitor.R` to observe the work that all the computers are doing. You will need to have the `shiny` library to execute, but the app will launch from either R or Rstudio. It will open a browser window with multiple tabs to observe the processes at work. 

### Customizing run

Within the setup block you may customize a few things. Specifically, you can change how many cores your computer will run on, whether you want automatic uploading, and if so, where the paths to the files and cloud folder are. 

#### Cores

Set `cores = detectCores()` for maximum performance. Set `cores = 1` for minimum load (if you need the resources for something else).

#### Number of tasks to complete per cycle

By default, `numTasks = cores`, so you're doing one task per core that you have. 

#### autoUpload

As mentioned before, you can have the script manage your uploads for you by setting `autoUpload = T`. However, you will see a performance penalty because the `googledrive` package takes a long time to talk to the server. 

### Managing outputs

When you've run the program for some time, you will see a folder called `localOutput` in the `CT_sim` directory, and `.Rdata` files within. There are two ways to get this up to the cloud, either automatically or manually. In either case, you will need to know the cloud folder link:

https://drive.google.com/open?id=1ScHvlCXL-8kjzeeLfb_LTH45worK4b3Y

**NOTE: Automatic uploads are painfully SLOW. On 7 files of size 2kb each, the upload took 3 minutes, as opposed to seconds dragging and dropping. I will be manually uploading my outputs.**

#### Automatic upload

This option will probably be feasible only if you have unlimited google drive space through Cornell. First, ensure that you have migrated the shared folder into your own google drive by clicking on the link above, clicking the folder name, and clicking "Add to My Drive". Ensure that it is in the root (top-most) directory.

![](https://github.com/awong234/CT_sim/blob/master/assets/googleDriveMigrate.png)

If you want the script to manage your uploads automatically, within `RUNSCRIPT.R`, change the value of `autoUpload` to `TRUE`, within the setup block. The file will then source `uploadOutput.R`. 

It will prompt you to generate a token, and at the same time bring up a browser window. 

![Browser prompt.](https://github.com/awong234/CT_sim/blob/master/assets/googleDriveBrowserPrompt.png)

![R prompt.](https://github.com/awong234/CT_sim/blob/master/assets/googleDriveAuth.png)

First, address any inputs that R may ask of you, then in the browser allow tidyverse to access your google drive. You will have a token created in the directory that will authenticate your R session as it communicates with your Drive account.

The script will upload the files as they come out. Once again, note that this will penalize efficiency due to slow uploads.

#### Manual upload

***IMPORTANT***

For those who are **not** using automation to upload the files, you will need to drag and drop the outputs to the [shared folder](https://drive.google.com/open?id=1ScHvlCXL-8kjzeeLfb_LTH45worK4b3Y). You should see a green icon in the lower-right hand corner indicating successful uploads.

![](https://github.com/awong234/CT_sim/blob/master/assets/gdriveUpload.png)

When you go to upload **new** files, be sure to follow the next steps! Select all of the files in the `localOutput` directory, and drag and drop into the shared folder. It will show you a dialog as follows:

![](https://github.com/awong234/CT_sim/blob/master/assets/gdrivePrompt.png)

**SELECT CANCEL.**

* If you select "Keep Separate", it will duplicate all of the files you have already uploaded. **We definitely don't want this.**
* If you select "Update Existing", it will re-upload all of the files you have already uploaded, which will become tedious with greater amounts of files, but not harmful. 

Be sure to upload your outputs frequently so that we have them all in case of system failure.

#### Freeing space

If you have an external hard drive and don't want to use your main hard drive space, please operate in the following order:

1. Stop the analysis on the computer whose space you want to free up. **This is especially important so that there are no outputs being created between steps 2 and 3 that will not be uploaded!**
1. Upload the outputs to the shard drive.
1. Move the output files to the external drive.
1. Restart the analysis.

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

### RUNSCRIPT.R

This will be the script that users will ultimately execute to participate in the analyses. It has major components that are outlined at the start of the script.

### SETUP.R

This file writes a local SQL database of the tasks to be done. Please run this on your first initialization of the analysis.

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

### uploadOutput.R

tidyverse's `googledrive` package only services your OWN google drive, so MUST have directory already in your account. This function will upload files in the `localOutput/` directory to the shared drive.

### writeSettings.R

This file, when sourced, will write a record of all the proposed settings to memory. This is used in `RUNSCRIPT.R`

### settings.sqlite

After you have run `SETUP.R`, this file will generate in your working directory. It contains all 32 million tasks to be completed.