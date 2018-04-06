e2dist=function (x, y) {
  i <- sort(rep(1:nrow(y), nrow(x)))
  dvec <- sqrt((x[, 1] - y[i, 1])^2 + (x[, 2] - y[i, 2])^2)
  matrix(dvec, nrow = nrow(x), ncol = nrow(y), byrow = F)
}

simSCR<- 
 function(N=120,lam0=2,sigma=0.50,K=10,X ,buff=3,thinning.rate1 = 0.7,
          thinning.rate2=0.7,grid.space=0.5){
   
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
   y.used <-array(0,dim=c(N,J,K))
   for(i in 1:N){
     for(j in 1:J){
       for(k in 1:K){
         y.used[i,j,k]=rpois(1,lamd[i,j])
       }
     }
   }
   y.used<- y.used[1:N, 1:nrow(X), 1:K]
   
   # compute total occupancy on the landscape by evaluating on a fine grid (Xgrid above)
   lam.grid<- lamd[1:N, (nrow(X)+1):J]
   lam.gridJ=colSums(lam.grid)
   p.grid=1-exp(-lam.gridJ)
   psi.grid=1-(1-p.grid)^K

   
   
   # compute total occupancy probability on the trap locations
   lamd<- lamd[1:N, 1:nrow(X)]
   H.total<- colSums(lamd)
   psi<- 1-exp(-H.total)
   
   # Now compute the SCR data:
   J<- nrow(X)
   y.occ<- y.scr <-array(0,dim=c(N,J,K))
   for(i in 1:N){
     for(j in 1:J){
       for(k in 1:K){
         y.occ[i,j,k]=rbinom(1, y.used[i,j,k], prob=thinning.rate1)
         y.scr[i,j,k]=rbinom(1, y.occ[i,j,k], prob=thinning.rate2)
       }
     }
   }
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
   scaps[scaps>0]=scaps[scaps>0]-1
   nscap=sum(scaps>0)
   sumscap=sum(scaps)
   #estimate occupancy p
   y.used2D=apply(y.used,c(2,3),sum)
   y.occ2D=1*(apply(y.occ,c(2,3),sum)>0)
   sites.used=sum(rowSums(y.used2D)>0)
   p.bar=sum(y.occ2D>0)/(sites.used*K) #estimated occupancy p
   out<-list(y.used=y.used,y.occ=y.occ,y.scr=y,s=s,X=X, K=K,n=n,nscap=nscap,sumscap=sumscap,buff=buff,
             psi.bar = mean(psi.grid),p.bar=p.bar )
   return(out)
 }
