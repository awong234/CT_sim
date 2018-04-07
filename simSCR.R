e2dist=function (x, y) {
  i <- sort(rep(1:nrow(y), nrow(x)))
  dvec <- sqrt((x[, 1] - y[i, 1])^2 + (x[, 2] - y[i, 2])^2)
  matrix(dvec, nrow = nrow(x), ncol = nrow(y), byrow = F)
}

simSCR<- 
 function(N=120,lam0=2,sigma=0.50,K=10,X ,buff=3,thinning.rate1 = 0.7,
          thinning.rate2=0.7,grid.space=0.5, seed = NULL){
   
   # Added for reproducibility
   set.seed(seed)
   
   xmin<- min(X[,1])-buff
   xmax<- max(X[,1])+buff
   ymin<- min(X[,2])-buff
   ymax<- max(X[,2])+buff
   Xgrid<- expand.grid(seq(xmin,xmax,grid.space), seq(ymin,ymax,grid.space))
   
   # # simulate USAGE for a population of activity centers
   s<- cbind(runif(N, min(X[,1])-buff,max(X[,1])+buff), runif(N,min(X[,2])-buff,max(X[,2])+buff))
   D<- e2dist(s,rbind(X,Xgrid) )
   lamd<- lam0*exp(-D*D/(2*sigma*sigma))
   J<- nrow(X) + nrow(Xgrid)
   # Simulate encounter history
   y.use <-array(0,dim=c(N,J,K))
   for(i in 1:N){
     for(j in 1:J){
       for(k in 1:K){
         y.use[i,j,k]=rpois(1,lamd[i,j])
       }
     }
   }
   y.use<- y.use[1:N, 1:nrow(X), 1:K]
   
   # compute total occupancy on the landscape by evaluating on a fine grid (Xgrid above)
   lam.grid<- lamd[1:N, (nrow(X)+1):J]
   lam.gridJ=colSums(lam.grid)
   p.grid=1-exp(-lam.gridJ)
   psi.grid=1-(1-p.grid)^K

   # compute total occupancy probability on the trap locations
   lamd<- lamd[1:N, 1:nrow(X)]
   lamJ=colSums(lamd)
   p=1-exp(-lamJ)
   psi=1-(1-p)^K
   
   # Now compute the SCR data:
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
   #make occupancy data set
   y.occ=1*(apply(y.det,c(2,3),sum)>0)#site by occasion detections
   y.occ=rowSums(y.occ)#sum over occasions
   #remove uncaptured individuals in SCR data set
   y<- y.scr
   caps=apply(y,1,sum)
   idx=order(caps,decreasing=TRUE)
   y=y[idx,,]
   s=s[idx,]
   n=sum(caps>0)
   y=y[rowSums(y)>0,,]
   #Count spatial recaps
   y2D=apply(y,c(1,2),sum)
   scaps=rowSums(1*(y2D>0))
   scaps[scaps>0]=scaps[scaps>0]-1 #spatial recaps per ind
   nscap=sum(scaps>0) #Total number of individuals with spatial recaps
   sumscap=sum(scaps) #Total number of spatial recaps. Use this to screen data sets.
   #estimate occupancy p
   y.use2D=apply(y.use,c(2,3),sum)
   sites.use=sum(rowSums(y.use2D)>0)#sites use at least once
   y.det2D=1*(apply(y.det,c(2,3),sum)>0)#trap by occ presence/absence
   p.bar=sum(y.det2D)/(sites.use*K) #estimated occupancy p
   out<-list(y.use=y.use,y.occ=y.occ,y.scr=y,s=s,X=X, K=K,n=n,nscap=nscap,sumscap=sumscap,buff=buff,
             psi.bar = mean(psi.grid),p.bar=p.bar )
   return(out)
 }