e2dist<-function (x, y)
{
  i <- sort(rep(1:nrow(y), nrow(x)))
  dvec <- sqrt((x[, 1] - y[i, 1])^2 + (x[, 2] - y[i, 2])^2)
  matrix(dvec, nrow = nrow(x), ncol = nrow(y), byrow = F)
}


#' Simulate data from a SCR study. Modified from SPIM package
#' @param N a vector indicating the number of individuals to simulate
#' @param p0 the detection function baseline detection probability
#' @param sigma the spatial scale parameter
#' @param K the number of capture occasions
#' @param X the K x 2 matrix of trap locations
#' @param buff the distance to buffer the trapping array in the X and Y dimensions to produce the state space
#' @return a list containing the capture history, activity centers, trap object, and several other data objects and summaries.
#' @description This function simulates data from a camera trap SCR study. The extent of the state space is controlled by "buff", which buffers the
#' minimum and maximum X and Y extents.  Therefore, it probably only makes sense for square or rectangular grids.  Functionality
#' for user-provided polygonal state spaces will be added in the future.
#' @author Ben Augustine
#' @export

simSCR <-
  function(N=120,p0=0.2,sigma=0.50,K=10,X=X,buff=3,obstype="bernoulli"){
    # # simulate a population of activity centers
    s<- cbind(runif(N, min(X[,1])-buff,max(X[,1])+buff), runif(N,min(X[,2])-buff,max(X[,2])+buff))
    D<- e2dist(s,X)
    pd<- p0*exp(-D*D/(2*sigma*sigma))
    J<- nrow(X)
    # Simulate encounter history
    y <-array(0,dim=c(N,J,K))
    for(i in 1:N){
      for(j in 1:J){
        for(k in 1:K){
          y[i,j,k]=rbinom(1,1,pd[i,j])
        }
      }
    }
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
    out<-list(y=y,s=s,X=X, K=K,n=n,nscap=nscap,sumscap=sumscap,buff=buff,obstype=obstype)
    return(out)
  }