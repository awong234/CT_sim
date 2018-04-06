#######Proposed scenarios########
sigma=0.5
#within cluster spacing. sigma units
spacein=seq(0.5,3.5,0.5)
#min cluster spacing is within cluster spacing
#seems logical and reduces the number of scenarios
spaceout1=seq(0.5,3.5,0.5)
spaceout2=seq(1,3.5,0.5)
spaceout3=seq(1.5,3.5,0.5)
spaceout4=seq(2,3.5,0.5)
spaceout5=seq(2.5,3.5,0.5)
spaceout6=seq(3,3.5,0.5)
p0=c(0.2,0.4) # Need to tune this for reasonably sized data sets
K=5 #Arbitrary. Vary p0.
D=c(0.1,0.25,0.5) #N per km^2
ntraps=c(40,80,120)
#Maybe we don't do any cluster sizes that don't create at least 2 full size clusters
clustersize1=c(2,3,4) #for 40 traps, stop at 4 x 4
clustersize2=c(2,3,4,5,6) #for 80 traps, stop at 6 x 6
clustersize3=c(2,3,4,5,6,7) #for 120 traps, stop at 7 x 7
#number of trap spacing combinations
nspace=(length(spaceout1)+length(spaceout2)+length(spaceout3)+
          length(spaceout4)+length(spaceout5)+length(spaceout6))
#number of combinations for each trap #
ncombs40=nspace*length(p0)*length(D)*length(clustersize1)
ncombs80=nspace*length(p0)*length(D)*length(clustersize3)
ncombs120=nspace*length(p0)*length(D)*length(clustersize2)
#total number of combinations
ncombs=ncombs40+ncombs80+ncombs120

fittime=120 #in seconds. Optimistic, given some higher D and trap # scenarios.
nreps=100 #number of reps per scenario
cores=196 #number of cores running at all times
ncombs*fittime*nreps/cores/60/60/24#total run time in days





#######Test the build grid function#########
#This code specifies some cluster sizes, interior and 
#exterior spacings, and plot all combinations.
#Looks to be working correctly to me.

source("build.cluster.R")
ntraps=120 #Currently works for up to 144 clusters or 144 traps in a single cluster.
clusterdim=c(2,3,4,5,6,7)#2 x 2, 3 x 3, etc.
spacingin=c(0.5,1,1.5) #interior spacing
spacingout=c(1.5,2,2.5) #cluster spacing
for(i in 1:6){
  for(j in 1:3){
    for(k in 1:3){
      X=build.cluster(ntraps,clusterdim[i],spacingin[j],
                      spacingout[k],plotit=TRUE)
    }
  }
}

source("build.cluster.R")
source("build.cluster.alt.R")
ntraps=120 #Currently works for up to 144 clusters or 144 traps in a single cluster.
ntrapsC=c(1,2,3,4,5,6,7,8)#number of traps in a cluster
spacingin=c(1,1.5) #interior spacing
spacingout=c(1.5,2.5) #cluster spacing
for(i in 1:8){
  for(j in 1:2){
    for(k in 1:2){
      X=build.cluster.alt(ntraps,ntrapsC[i],spacingin[j],
                      spacingout[k],plotit=TRUE)
    }
  }
}






#Simulate data
source("simSCR.R")
N=50
lam0=0.4
sigma=0.5
K=10
buff=3
X=expand.grid(3:9,3:9)
thinning.rate1 = 0.7
thinning.rate2=0.7
grid.space=0.5 #spacing for grid to calculate psi.bar
data=simSCR(N=N,lam0=lam0,sigma=sigma,K=K,X=X,
            buff=buff,thinning.rate1,thinning.rate2,
            grid.space)


##SCRbook integrated likelihood
#The parameter estimates will differ slightly from oSCR and secr because 
#This is the binomial integrated likelihood, while those packages use the 
#poisson integrated likelihood to handle multi session data
#Note, this likelihood estimates n0, the number of individuals
#not captured. N_hat is n0_hat+n, the number captured.
y=apply(data$y.scr,c(1,2),sum)
n=data$n
parm=c(log(p0),log(sigma),log(N-nrow(y)))
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
D <- e2dist(X, G)
#append uncaptured history (all zeros) to capture history
ymat <- y
ymat <- rbind(y, rep(0, ncol(y)))

#intlik function
intlik=function (parm, ymat = ymat,X=X, K=K,G=G,D=D,n=n) {
  nG <- nrow(G)
  lam0 <- exp(parm[1])
  sigma <- exp(parm[2])
  n0 <- exp(parm[3])
  nv <- c(rep(1, n), n0)
  lamd<- lam0*exp(-D*D/(2*sigma*sigma))
  probcap=1-exp(-lamd)
  Pm <- matrix(NA, nrow = nrow(probcap), ncol = ncol(probcap))
  lik.marg <- rep(NA, nrow(ymat))
  for (i in 1:nrow(ymat)) {
    Pm[1:length(Pm)] <- (dbinom(rep(ymat[i, ], nG), K, probcap[1:length(Pm)],log = TRUE))
    lik.cond <- exp(colSums(Pm))
    lik.marg[i] <- sum(lik.cond) * (1/nG)
  }
  part1 <- lgamma(n + n0 + 1) - lgamma(n0 + 1)
  part2 <- sum(nv * log(lik.marg))
  -1 * (part1 + part2)
}

#fit model using integrated likelihood
a=Sys.time()
out.intR=nlm(intlik,parm,ymat=ymat,X=as.matrix(X), K=K,G= G,D=D,n=n,print.level=2,hessian=TRUE)
b=Sys.time()
b-a

##SCRbook integrated likelihood in Rcpp
library(Rcpp)
sourceCpp("intlikRcpp.cpp")

#fit model using integrated likelihood in Rcpp
a=Sys.time()
out.intRcpp=nlm(intlikRcpp,parm,ymat=ymat,X=as.matrix(X), K=K,G= G,D=D,n=n,print.level=2,hessian=TRUE)
b=Sys.time()
b-a

#more formal speed comparison of R vs Rcpp. Will vary by data set
library(microbenchmark)
microbenchmark(intlikRcpp(parm,ymat,as.matrix(X), K, G,D= D,n=n),
               intlik(parm,ymat,as.matrix(X), K, G,D= D,n=n))





##########occupancy analysis###########
#simulate SCR data again, or use existing data
source("simSCR.R")
N=50
lam0=0.4
sigma=0.25
K=10
buff=3
X=expand.grid(3:9,3:9)
thinning.rate1 = 0.7
thinning.rate2=0.7
grid.space=0.5
data=simSCR(N=N,lam0=lam0,sigma=sigma,K=K,X=X,
            buff=buff,thinning.rate1,thinning.rate2,grid.space)
#convert occupancy data to presence/absence
y=1*(apply(data$y.occ,c(2,3),sum)>0)#site by occasion detections
y=rowSums(y)#sum over occasions
K=data$K
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

#p_hat, psi_hat
plogis(occ.out$estimate)



#example of getting confidence intervals from hessian matrix
fisher=solve(occ.out$hessian)
SE=sqrt(diag(fisher))
upper<-occ.out$estimate+1.96*SE
lower<-occ.out$estimate-1.96*SE
ests=cbind(occ.out$estimate,lower, upper)#on logit scale
plogis(ests) #on real scale



#simulate and fit true occupancy data using same LL
p=0.3
psi=0.8
J=49
K=10
data.occ=simOcc(p,psi,J,K)
#fit occupancy model 
occ.out=nlm(negLogLikeocc,parm,y=data.occ,K=K,hessian=TRUE)
#p_hat, psi_hat
plogis(occ.out$estimate)