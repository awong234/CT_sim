# This file executes read/writes to the SQL server of tasks reserved/completd, with the intention to test its functionality.

# NOTICE: Executing the next two lines will install packages DBI and odbc if you don't already have them.

if(!require(DBI)){install.packages('DBI')}
if(!require(odbc)){install.packages('odbc')}
if(!require(doParallel)){install.packages('doParallel')}


source('functionsSQL.R')

# Reserve tasks - always to be run initially
reservedTasks = reserveTasks()

# Loop while there are free tasks. When there are no more free tasks,
# length(reservedTasks) == 0, and loop will end. 

# Can cancel mid-operation at any point without issue; upon next start,
# reservedTasks() will free up those tasks ended prematurely.

testSQL(reservedTasks = reservedTasks)

# To look at the database, use function printDB() without any arguments. The
# filter will only show you tasks you've reserved with this computer.

remoteTaskList = printDB()

remoteTaskIDs = remoteTaskList[remoteTaskList$owner == Sys.info()['nodename'],1]

# Compare to local record

localTaskIDs = read.csv('reservedTasks.csv', header = F)[,1]

# If TRUE, then there are no remote tasks that aren't in your local set
# If FALSE, there is a task claimed by you on the remote server that wasn't done on your computer; unlikely
all(remoteTaskIDs %in% localTaskIDs)

# If TRUE, then there are no local tasks that aren't in the remote set
# If FALSE, there is a task done on your computer that was not claimed by you (probably because someone else claimed it at the same time); more likely
all(localTaskIDs %in% remoteTaskIDs)
