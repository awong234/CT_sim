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






#####Test speed of different R packages to fit null SCR model######
#Simulate data
source("simSCR.R")
N=50
p0=0.2
sigma=0.5
K=10
buff=3
X=expand.grid(3:9,3:9)
data=simSCR(N=N,p0=p0,sigma=sigma,K=K,X=X,
            buff=buff)

#Skipping SPIM here
##fit the model using secr
library(secr)
ncap=sum(data$y>0)
input=data.frame(session=rep("a",ncap),ID=rep(0,ncap),Occasion=rep(0,ncap),Detector=rep(0,ncap))
caps=which(data$y>0,arr.ind=TRUE)
for(i in 1:nrow(caps)){
  input[i,c(2,3,4)]=c(caps[i,1],caps[i,3],caps[i,2])
}

traps=data.frame(num=1:nrow(X),x=X[,1],y=X[,2])
traps=read.traps(data=traps,detector="proximity")
data2=make.capthist(input,traps)
## generate habitat mask
mask=make.mask (traps, buffer = buff, nx = 48)
#fit and time model
a=Sys.time()
secr.out=secr.fit(data2, model = g0~1, mask = mask,detectfn=0)
b=Sys.time()
b-a

##fit the model using oSCR
library(oSCR)
tdf=data.frame(Detector=1:49,X=X[,1],Y=X[,2])
tdf=list(cbind(tdf,matrix(1,nrow=49,ncol=K)))
input=cbind(input,rep(1,ncap))#Give everyone the same sex
data.oscr=data2oscr(input,sess.col=1,id.col=2,occ.col=3,trap.col=4,ntraps=49,K=10,tdf=tdf,sex.col=5)
data.sf=make.scrFrame(caphist=data.oscr$y3d, indCovs=NULL, 
                             traps=data.oscr$traplocs,trapCovs=NULL ,
                             trapOperation=data.oscr$trapopp )
# Make a state-space
data.ss=make.ssDF(data.sf, buffer=buff, res = 0.25)

#  fit and time model
a=Sys.time()
oSCR.out=oSCR.fit(model=list(D~1,p0~1,sig~1), data.sf, ssDF=data.ss,
                 start.vals=c(qlogis(p0),log(sigma),log(0.5)),trimS=4)
b=Sys.time()
b-a

##SCRbook integrated likelihood
#The parameter estimates will differ slightly from oSCR and secr because 
#This is the binomial integrated likelihood, while those packages use the 
#poisson integrated likelihood to handle multi session data
#Note, this likelihood estimates n0, the number of individuals
#not captured. N_hat is n0_hat+n, the number captured.
y=apply(data$y,c(1,2),sum)
n=data$n
parm=c(qlogis(p0),log(sigma),log(N-nrow(y)))
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
  alpha0 <- plogis(parm[1])
  sigma <- exp(parm[2])
  n0 <- exp(parm[3])
  nv <- c(rep(1, n), n0)
  probcap <- alpha0 * exp(-1/(2*sigma^2) * D * D)
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
p0=0.2
sigma=0.5
K=5
buff=3
X=expand.grid(3:9,3:9)
data=simSCR(N=N,p0=p0,sigma=sigma,K=K,X=X,
            buff=buff)
#convert to occupancy data
y=1*(apply(data$y,c(2,3),sum)>0)#site by occasion detections
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

