e2dist=function (x, y) {
  i <- sort(rep(1:nrow(y), nrow(x)))
  dvec <- sqrt((x[, 1] - y[i, 1])^2 + (x[, 2] - y[i, 2])^2)
  matrix(dvec, nrow = nrow(x), ncol = nrow(y), byrow = F)
}

simSCR<- function(D = 0.83333,lam0=2,sigma=0.50,K=10,X ,buff=3,thinning.rate1 = 0.7,
          thinning.rate2=0.7,grid.space=0.5, seed = NULL){

# Density per square unit of the state-space. Then N = round(D*area)
#    N = population size on the state-space defined by "buff" (see below)
# lam0 = baseline "use" intensity
# sigma = scale parameter of SCR detection function
# K = number of occasions to sample (nights)
# X = trapping array coordinates
# buff = defines the state space
# thinning.rate1 = thinning rate to convert use to occupancy data
# thinning.rate2 = thinning rate to convert occupancy data to SCR data
# grid.space = spacing of state-space grid points used in likelihood evaluation
# seed = random number seed


   # Added for reproducibility
   set.seed(seed)

    # Define the state-space by buffering the traps
   xmin<- min(X[,1])-buff
   xmax<- max(X[,1])+buff
   ymin<- min(X[,2])-buff
   ymax<- max(X[,2])+buff

    area<- (ymax-ymin)*(xmax-xmin)
    N<- round(D*area,0)

   # Make a fine grid for computing average occupancy over the state-space
    Xgrid<- expand.grid(seq(xmin,xmax,grid.space), seq(ymin,ymax,grid.space))

   # # simulate USAGE for a population of activity centers
   s<- cbind(runif(N, min(X[,1])-buff,max(X[,1])+buff), runif(N,min(X[,2])-buff,max(X[,2])+buff))
   
   # ALEC EDITS: rbind(X,Xgrid) results in an error 
   #  Error in match.names(clabs, names(xi)) : 
   #  names do not match previous names
   
   # This is due to `rbind`ing a matrix to a dataframe with mismatched names.
   
   # I am formatting Xgrid as a matrix with no names so rbind
   # will work. 
   
   Xgrid = as.matrix(Xgrid)
   attr(x = Xgrid, which = 'dimnames') = NULL
   
   D<- e2dist(s,rbind(X,Xgrid))   # compute distance between each activity center and each trap
   # use intensity
   lamd<- lam0*exp(-D*D/(2*sigma*sigma))
   J<- nrow(X) + nrow(Xgrid)
   # Simulate USE history of each pixel according to a Poisson use model
   y.use <-array(0,dim=c(N,J,K))
   for(i in 1:N){
     for(j in 1:J){
       for(k in 1:K){
         y.use[i,j,k]=rpois(1,lamd[i,j])
       }
     }
   }
   
   if(dim(s)[1] > 1){y.use<- y.use[1:N, 1:nrow(X), 1:K]}else{y.use = y.use}

   # compute total occupancy on the landscape by evaluating on a fine grid (Xgrid above)
   lam.grid<- lamd[1:N, (nrow(X)+1):J]
   # FAILS WITH ONE INDIVIDUAL. 
   if(dim(s)[1] > 1){  # Safety for when N = 1
     lam.gridJ=colSums(lam.grid) 
   }else{
     lam.gridJ = lam.grid
   }
   
   p.grid=1-exp(-lam.gridJ)
   psi.grid=1-(1-p.grid)^K

   # compute total occupancy probability on the trap locations
   # This is not used for anything, ignore
   lamd<- lamd[1:N, 1:nrow(X)]
   if(dim(s)[1] > 1){  # Safety for when N = 1
     lamJ=colSums(lamd) 
   }else{
     lamJ = lamd
   }
   p=1-exp(-lamJ)
   psi=1-(1-p)^K

   # Now compute the SCR and OCC data by thinning the USE frequencies
   J<- nrow(X)
   y.det<- y.scr <-array(0,dim=c(N,J,K))
   for(i in 1:N){
     for(j in 1:J){
       for(k in 1:K){
         y.det[i,j,k]=rbinom(1, y.use[i,j,k], prob=thinning.rate1)
         y.scr[i,j,k]=rbinom(1, y.det[i,j,k], prob=thinning.rate2)
       }
     }
   }
   #convert SCR data set from counts to presence/absense
   y.scr[y.scr>0]=1
   #make occupancy data set
   y.occ=1*(apply(y.det,c(2,3),sum)>0)#site by occasion detections
   y.occ=rowSums(y.occ)#sum over occasions

   #remove uncaptured individuals in SCR data set. sort.
   y<- y.scr
   caps=apply(y,1,sum)
   
   # Safety for when caps == 0. For R versions < 3.4
   if(caps == 0){
     n = 0
     nscap = 0
     sumscap = 0
   }else{
     idx=order(caps,decreasing=TRUE)
     y = y[idx,,]
     s=s[idx,]
     n=sum(caps>0)
     y=y[rowSums(y)>0,,]
     #Count spatial recaps
     y2D=apply(y,c(1,2),sum)
     scaps=rowSums(1*(y2D>0))
     scaps[scaps>0]=scaps[scaps>0]-1 #spatial recaps per ind
     nscap=sum(scaps>0) #Total number of individuals with spatial recaps
     sumscap=sum(scaps) #Total number of spatial recaps. Use this to screen data sets.
   }
   
   #estimate occupancy p
   sites.used=sum(apply(y.use,2,sum)>0)#sites use at least once
   p.bar=sum(y.occ)/(sites.used*K) #estimated occupancy p
   out<-list(y.use=y.use,y.det=y.det,y.occ=y.occ,y.scr=y,s=s,X=X, K=K,n=n,nscap=nscap,sumscap=sumscap,buff=buff,
             psi.bar = mean(psi.grid),p.bar=p.bar,
             N = N, # may as well return this too
             seed = seed
             )
   return(out)
 }
