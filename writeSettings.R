library(dplyr)

# Settings for simulations

# This will be a data frame with 1 row per task, and columns specifying simulation settings. 

# Make vectors of all of the below, and expand.grid will automatically generate all combinations.

# It will write to the directory. 

# Settings for trap design ----------------------------------

# Number of traps

nTraps = c(40, 80, 120)

# Cluster size

clusterSize = c(2, 3, 4, 5, 6, 7)

# Within cluster spacing

spaceIn = c(1.5, 1, 1.5)

# Among cluster spacing

spaceOut = c(1.5, 2, 2.5)

# Settings for population sim -------------------------------

# sigma - Ben mentioned that since spacing is relative to sigma, this needs not be varied.

sigma = 0.5

# lam0

lam0 = c(0.4)

# p0 - Mentioned that this needs tuning.

p0 = c(0.2, 0.4)

# K

K = 5

# Density

D = c(0.1, 0.25, 0.5)

# Buffer

buff = 3

# thinning.rate1

thinRate1 = c(0.7)

# thinning.rate2

thinRate2 = c(0.7)


# Simulation Seeds ---------------------------------------------------------------------------------------------------

exampleSettings = expand.grid(c(1,2,3), letters, LETTERS)

settings = expand.grid(nTraps = nTraps, 
                       clusterSize = clusterSize, 
                       spaceIn = spaceIn, 
                       spaceOut = spaceOut, 
                       sigma = sigma, 
                       lam0 = lam0, 
                       p0 = p0, 
                       K = K,
                       D = D, 
                       buff = buff, 
                       thinRate1 = thinRate1, 
                       thinRate2 = thinRate2)

settings = settings %>% as.matrix()

settingsChecksums = apply(X = settings, MARGIN = 1, FUN = digest::sha1)

whichDups = settingsChecksums %>% table %>% as.data.frame %>% {which(.$Freq > 1)} # Duplicates

uniqueSettings = settings %>% unique

apply(X = uniqueSettings, MARGIN = 1, FUN = digest::sha1) %>% table %>% as.data.frame %>% {which(.$Freq > 1)} # No duplicates

replicates = 2

settings = uniqueSettings[rep(seq(nrow(uniqueSettings)), replicates),]

# Check to see that there are exactly `replicates` duplicates

settings %>% apply(MARGIN = 1, FUN = digest::digest) %>% table # All return `replicates`. There are exactly `replicates` of each combination; each combination uniquely identified by a checksum.

# Question of how many populations to simulate? {# setting combinations} x {# replicates}, or just {# replicates} applied to each setting combination? 
# If the former:

settings %>% mutate(seeds = seq(1,nrow(.))) # One seed for {every settings combo} x {every replicate} ; a unique number 

# If the latter:

settings %>% mutate(seeds = rep(seq(nrow(uniqueSettings)), replicates)) # One seed for every replicate, each DESIGN samples the same population
