# SETUP file to be run on the first time of analysis or when new versions are pushed to the github.

# For ease of use, install SPIM manually using the Tools > Install Packages Dialog.

for(i in 1:2){
  # Install SPIM automatically from Github.
  if(!require(devtools)){install.packages('devtools')}
  if(!require(SPIM) & find_rtools()){install_github('benaug/SPIM')}
  # Install and load LOCAL database stuff.
  if(!require(RSQLite)){install.packages('RSQLite')}
  if(!require(dbplyr)){install.packages('dbplyr')}
}

source('writeSettings.R')

# Get settings list
settings = writeSettings(nreps = 500)

save(list = c("settings"), file = 'settings.Rdata')

# Open local sql connection
con = dbConnect(SQLite(), 'settings.sqlite')

# Write settings list to connection
dbWriteTable(conn = con, name = 'settings', value = settings)

# Close connection
dbDisconnect(conn = con)