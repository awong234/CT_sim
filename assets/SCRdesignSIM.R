# This is a script designed to simulate a few different study designs for a SCR study
# and compare the estimates and their standard errors that result, relative to the 
# known data-generating values. You can modify this script and the simulator function within,
# to test other design scenarios.
 

# Design problem: You have a large region and you only have 36 traps you can use.
# Density is lowish...thought to be around 50 individuals in this large state-space.
# We think that baseline capture probability will be around 0.2, and that sigma will be roughly 0.8 units.
# In preparing your project, you want to know the best way to allocate your meager 36 camera traps
# and so you want to compare three different potential designs.

# Design 1: a grid of 6 x 6 traps in the central part of the state-space, evenly spaced with delta = 1 unit
# Design 2: same situation but with a wider spacing to cover the state-space uniformly delta = 1.8 units
# Design 3: 4 clusters of 3 x 3 with spacing of delta = 1 within a cluster and 2 units seperating the clusters

# Simulate a basic SCR data set
set.seed(1234) #this function can be re-run with this input before you run a simulation based
                # some random # generation. That will ensure you use the same random #s and you
                # have different results every time...

# Define the state-space as 13 by 13 units
xlim<- c(0, 13)
ylim<- c(0, 13)
area<- diff(xlim)*diff(ylim)

# Set population size
N<- 50 # D = 50/169 = 0.296
#create N random (from uniform dist) x and y values between 0 and 13, then combine (cbind) to form
# X,Y locations for activity centers
s <- cbind(runif(N, xlim[1], xlim[2]), runif(N, ylim[1],ylim[2]) )

# Trap locations for the three different designs, each with 36 traps
traps1<- expand.grid( 4:9, 4:9) # Design 1, single central tight grid
traps2<- expand.grid(seq(2,11,,6), seq(2,11,,6)) #Design 2, wider spacing of 1.8 units.
                                                  #Sequence of 6 values spaced evenly from 2 to 11.
traps3a<- expand.grid(3:5, 3:5) #first sub-grid of Design 3
traps3b<- expand.grid(8:10, 8:10) #second subgrid of Design 3
traps3c<- expand.grid(3:5,8:10) #third sub-grid of Design 3
traps3d<- expand.grid(8:10, 3:5) #fourth sub-grid of Design 3
traps3<- rbind(traps3a, traps3b, traps3c, traps3d) #create full Design #3 combining the 4 sub-grids

par(mfrow=c(2,2))

#Plot the 3 study designs, first plotting the traps, then the N home range centers
plot(traps1,pch=3, xlim=c(0,13),ylim=c(0,13), xlab=" ",ylab=" ", main = "Design 1")
points(s, pch=20,col="red")
plot(traps2,pch=3, xlim=c(0,13),ylim=c(0,13), xlab=" ",ylab=" ", main = "Design 2")
points(s, pch=20,col="red")
plot(traps3,pch=3, xlim=c(0,13),ylim=c(0,13), xlab=" ",ylab=" ", main = "Design 3")
points(s, pch=20,col="red")


library(oSCR)

#Create a simulator function which takes a set of trap locations as input, randomly assigns
# 50 activity centers in the state space, calculates p for each trap relative to each activity center,
# based on their distances apart, creates a 3D [i,j,k] array of individuals,
# by traps, by ocassions using a binomial function to determine which animals are
# captured, how often, and where. Finally, it uses oSCR to run a basic SCR model on the capture
# information to see how accurate and precise your estimates are relative to the true values. Outputs
# of each of the 100 simulations are placed into a matrix "simout", and then averaged. Remember that if you
# are confused about what any of this code does, you can walk through the simulation code inside the
#function, line by line, putting in an actual trap object wherever "traps" occurs.

simulator<- function( traps ,    nsim) {

  simout1<- matrix(NA,nrow=nsim,ncol=7) #create empty matrix with 100 rows and 7 columns to hold simulation results
  colnames(simout1)<- c("p0","sig","d0","nind", "avg.caps","avg.spatial","mmdm") # assign column names to the
                                                                                 # empty matrix

  for(sim in 1:nsim){           #start a loop to run 100 times
    print(paste("Simulation Number", sim, sep = " ")) #print simulation number to console to keep track of progress

    # Generate home range centers
    s <- cbind(runif(N, xlim[1], xlim[2]), runif(N, ylim[1],ylim[2]) )

    D<- e2dist(s,traps) #distance matrix of distance between each trap to each activity centers

    # Define parameters and compute detection probabilities:
    p0<- 0.2                            #baseline encounter probability
    sigma<- 0.8                         #scale factor of detection function
    pmat<- p0*exp(-D*D/(2*sigma*sigma)) #Calculates matrix of p for all traps, based on all distances
                                        #in N matrix. Each indvidual, represented by each activity center
                                        #has a certain capture probability (p) at each trap, based on how
                                        #far its center is located from that particular trap. This equation
                                        #represents that relationship, and outputs that p for each individual
                                        #at each trap.

    ntraps<- nrow(traps)
    K<- 10 # sampling occasions. You can modify this here for a different design.

    y<- array(0, dim=c(N, ntraps, K)) #create 3D array of individuals (N), by traps, by occasions
    for(i in 1:N){                            # loop through each individual/activity center
      for(j in 1:ntraps){                     # loop through each trap
        y[i,j,1:K]<- rbinom(K, 1, pmat[i,j])  # fills the full i,j,k matrix and pulls a 1 or 0 for each
                                              # individual, at each trap at each
                                              # occasion using the p matrix as the probability of success
                                              # in the binomial trials
      } #end loop for each trap
    } #end loop for each individual

    # Some summary information, only those with "print" will show to the console during simulation
    print(table(y)) #Total captures (total number of 1's vs. zeros in array)
    print(table(apply(y,c(1), sum)))    # show summary of individual encounter frequencies (i.e. how many
                                        # we captured zero, one, two....times)
    ncap<- apply(y,c(1), sum)           # create object representing vector of total sum of captures
                                        # for each individual
    y<- y[ncap>0,,]                     # reduce the y array to include only individuals (first matrix in array)
                                        # with more than 0 captures
    dim(y)                              # number of individuals(caught at least once), number of traps
                                        # and number of occasions

    # Not printed or used, just fyi. Compute how many capture events there are and how many
    # left after reducing to 2-d data
    table(y)
    y2d<- flatten(y) # This shows how many captures you miss of same animal,
                      # same day, at different trap
    table(y2d)

    # Some summary information, that is actually printed for you later with "print(scrFrame)"
    caps.per.ind.trap<- apply(y,c(1,2),sum) #shows number of captures for each indv across all traps
    mean(apply(caps.per.ind.trap>0,1,sum)) #restricting to >0 converts to T/F and so sum ignores the amount of captures I think. This reps mean # of spatial caps I think per indv

    # Make the SCRframe
    colnames(traps)<- c("X","Y")
    scrFrame <- make.scrFrame(caphist=list(y), traps=list(traps), trapCovs=NULL ,
                               trapOperation=NULL )
    print(scrFrame) #printing the scrFrame from oSCR automatically shows a list of summary information

    plot(scrFrame)  # About the same as spiderplot(y, traps,add=FALSE), plots traps, capture locations
                    # for each indvidual, and average trap location for all captured indviduals

    # make a state-space
    ssDF <- make.ssDF(scrFrame, buffer=2, res = 0.5)
    # Note D0 = PER PIXEL so 50/169 in the simulation would now be 50/(169*4) at a 0.5 resolution = 0.074.
    # 0.074 is the true density we'll be looking for in our estimates.

    plot(ssDF) # plot the state space
    points(traps,pch=3,col="red",lwd=2) #plot the trap locations; or: spiderplot(y, traps, add=TRUE)

    # Fit a basic model SCR0 version 0.23 but doesn't print out the behavior coef.
    # Should add a TryCatch() call to identify crashes due to sparse data 
    out1 <- oSCR.fit(model=list(D~1,p0~1,sig~1), scrFrame, ssDF=ssDF,plotit=FALSE ,
                     start.vals=c(log(p0/(1-p0)), log(sigma), log(0.075)),
                     trimS=4)

    stats<- print(scrFrame)[[1]]  # pulls avg caps, avg spatial caps, and mmdm
    est<- out1$outStats[,2]       # pulls p0, sigma, and d0 estimates from the model
    simout1[sim,]<- c(plogis(est[1]), exp(est[2]), exp(est[3]), dim(y)[1], stats) #fills the current line of simout matrix with results from current simulation run

  } #end 1 through 100 cycle loop

  return(simout1) #this ensures that simout1 matrix is created and saved outside the loop, and is not just
                  #an internal object within the function, like stats, est, and out1, which cannot be called
                  #outside the function.

} #close simulation function

simout1<- simulator(traps1,nsim=20)  #runs simulation on the first design
simout2<- simulator(traps2,nsim=20) #runs simulation on the second design
simout3<- simulator(traps3,nsim=20) #runs simulation on the third design
 



 

library(doParallel)
nc <- 3
cl<-makeCluster(nc )
registerDoParallel(cl)
out <-foreach(i=1:9 ) %dopar% {
library(oSCR)
tmp<- simulator(traps1,nsim=1)
   return(tmp)
}
stopCluster(cl)
















colMeans(simout1) #shows average values of the estimates

colMeans(simout2)

colMeans(simout3)

 

apply(simout1,2,sd) #calculates standard deviation of all the estimates

apply(simout2,2,sd)

apply(simout3,2,sd)

 

