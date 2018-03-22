# This file executes read/writes to the SQL server of tasks reserved/completd, with the intention to test its functionality.

# NOTICE: Executing the next two lines will install packages DBI and odbc if you don't already have them.

if(!require(DBI)){install.packages('DBI')}
if(!require(odbc)){install.packages('odbc')}
if(!require(doParallel)){install.packages('doParallel')}
library(dplyr)

source('functions.R')

# Reserve tasks - always to be run initially
reservedTasks = reserveTasks()

# Loop while there are free tasks. When there are no more free tasks,
# length(reservedTasks) == 0, and loop will end. 

# Can cancel mid-operation at any point without issue; upon next start,
# reservedTasks() will free up those tasks ended prematurely.

testSQL(reservedTasks = reservedTasks)

# To look at the database, use function printDB() without any arguments. The
# filter will only show you tasks you've reserved with this computer.

printDB() %>% filter(owner == Sys.info()['nodename'])
