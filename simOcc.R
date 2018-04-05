simOcc<- 
  function(p,psi,J,K){
    occupied=detected=matrix(0,nrow=J,ncol=K)
    for(j in 1:J){
      occupied[j]=rbinom(1,1,psi)
      for(k in 1:K){
          detected[j,k]=rbinom(1,occupied[j],p)
      }
    }
    return(y=rowSums(detected))
  }