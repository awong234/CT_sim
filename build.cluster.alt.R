build.cluster.alt=function(ntraps,ntrapsC,spacingin,spacingout,plotit){
  size=ntraps/ntrapsC
  nfullcluster=floor(size)
  #Build normal clusters
  #build remainder cluster
  x=y=0
  m=1
  cluster=matrix(0,ncol=2,nrow=0)
  while(m<(ntrapsC+1)){
    xy=getxy(x,y,m,spacingin)
    x=xy[1]
    y=xy[2]
    cluster=rbind(cluster,xy)
    m=m+1
  }

  #Store all full clusters
  storecluster=list()
  for(l in 1:nfullcluster){
    storecluster[[l]]=cluster
  }
  #Are there traps that don't form a full cluster?
  remainder=ntraps-nfullcluster*ntrapsC
  ncluster=nfullcluster
  if(remainder>0){
    #build remainder cluster
    x=y=0
    m=1
    X2=matrix(0,ncol=2,nrow=0)
    while(m<(remainder+1)){
      xy=getxy(x,y,m,spacingin)
      x=xy[1]
      y=xy[2]
      X2=rbind(X2,xy)
      m=m+1
    }
    #Put remainder cluster at the end
    X2=matrix(X2,ncol=2)
    storecluster=c(storecluster,list(X2))
    ncluster=ncluster+1
  }
  spacex=max(cluster[,1])+spacingout
  spacey=max(cluster[,2])+spacingout
  X=matrix(0,nrow=0,ncol=2)
  x=y=0
  m=1
  
  #Build clusters
  while(m<(ncluster+1)){
    xy=getxy.alt(x,y,m,spacex,spacey)
    x=xy[1]
    y=xy[2]
    newcluster=storecluster[[m]]
    newcluster[,1]=newcluster[,1]+x
    newcluster[,2]=newcluster[,2]+y
    X=rbind(X,newcluster)
    m=m+1
  }
  if(plotit){
    xlim=c(min(X[,1]-space),max(X[,1]+spacex))
    ylim=c(min(X[,2]-space),max(X[,2]+spacey))
    plot(X,xlim=xlim,ylim=ylim)
  }
  return(X)
}



getxy.alt=function(x,y,m,spacex,spacey){
  #2x2
  if(m==2) y=y+spacey
  if(m==3) x=x+spacex
  if(m==4) y=y-spacey
  #3x3
  if(m==5){
    y=2*spacey
    x=0
  }
  if(m==6) x=x+spacex
  if(m==7) x=x+spacex
  if(m==8) y=y-spacey
  if(m==9) y=y-spacey
  #4x4
  if(m==10){
    y=3*spacey
    x=0
  }
  if(m==11) x=x+spacex
  if(m==12) x=x+spacex
  if(m==13) x=x+spacex
  if(m==14) y=y-spacey
  if(m==15) y=y-spacey
  if(m==16) y=y-spacey
  #5x5
  if(m==17){
    y=4*spacey
    x=0
  }
  if(m==18) x=x+spacex
  if(m==19) x=x+spacex
  if(m==20) x=x+spacex
  if(m==21) x=x+spacex
  if(m==22) y=y-spacey
  if(m==23) y=y-spacey
  if(m==24) y=y-spacey
  if(m==25) y=y-spacey
  #6x6
  if(m==28){
    y=5*spacey
    x=0
  }
  if(m==29) x=x+spacex
  if(m==30) x=x+spacex
  if(m==31) x=x+spacex
  if(m==32) x=x+spacex
  if(m==33) x=x+spacex
  if(m==34) y=y-spacey
  if(m==35) y=y-spacey
  if(m==36) y=y-spacey
  if(m==37) y=y-spacey
  if(m==38) y=y-spacey
  
  #7x7
  if(m==39){
    y=6*spacey
    x=0
  }
  if(m==40) x=x+spacex
  if(m==41) x=x+spacex
  if(m==42) x=x+spacex
  if(m==43) x=x+spacex
  if(m==44) x=x+spacex
  if(m==45) x=x+spacex
  if(m==46) y=y-spacey
  if(m==47) y=y-spacey
  if(m==48) y=y-spacey
  if(m==49) y=y-spacey
  if(m==50) y=y-spacey
  if(m==51) y=y-spacey
  
  #8x8
  if(m==52){
    y=7*spacey
    x=0
  }
  if(m==53) x=x+spacex
  if(m==54) x=x+spacex
  if(m==55) x=x+spacex
  if(m==56) x=x+spacex
  if(m==57) x=x+spacex
  if(m==58) x=x+spacex
  if(m==59) x=x+spacex
  if(m==60) y=y-spacey
  if(m==61) y=y-spacey
  if(m==62) y=y-spacey
  if(m==63) y=y-spacey
  if(m==64) y=y-spacey
  if(m==65) y=y-spacey
  if(m==66) y=y-spacey
  
  #9x9
  if(m==67){
    y=8*spacey
    x=0
  }
  if(m==68) x=x+spacex
  if(m==69) x=x+spacex
  if(m==70) x=x+spacex
  if(m==71) x=x+spacex
  if(m==72) x=x+spacex
  if(m==73) x=x+spacex
  if(m==74) x=x+spacex
  if(m==75) x=x+spacex
  if(m==76) y=y-spacey
  if(m==77) y=y-spacey
  if(m==78) y=y-spacey
  if(m==79) y=y-spacey
  if(m==80) y=y-spacey
  if(m==81) y=y-spacey
  if(m==82) y=y-spacey
  if(m==83) y=y-spacey
  
  #10x10
  if(m==84){
    y=9*spacey
    x=0
  }
  if(m==85) x=x+spacex
  if(m==86) x=x+spacex
  if(m==87) x=x+spacex
  if(m==88) x=x+spacex
  if(m==89) x=x+spacex
  if(m==90) x=x+spacex
  if(m==91) x=x+spacex
  if(m==92) x=x+spacex
  if(m==93) x=x+spacex
  if(m==94) y=y-spacey
  if(m==95) y=y-spacey
  if(m==96) y=y-spacey
  if(m==97) y=y-spacey
  if(m==98) y=y-spacey
  if(m==99) y=y-spacey
  if(m==100) y=y-spacey
  if(m==101) y=y-spacey
  if(m==102) y=y-spacey
  
  #11x11
  if(m==103){
    y=10*spacey
    x=0
  }
  if(m==104) x=x+spacex
  if(m==105) x=x+spacex
  if(m==106) x=x+spacex
  if(m==107) x=x+spacex
  if(m==108) x=x+spacex
  if(m==109) x=x+spacex
  if(m==110) x=x+spacex
  if(m==111) x=x+spacex
  if(m==112) x=x+spacex
  if(m==113) x=x+spacex
  if(m==114) y=y-spacey
  if(m==115) y=y-spacey
  if(m==116) y=y-spacey
  if(m==117) y=y-spacey
  if(m==118) y=y-spacey
  if(m==119) y=y-spacey
  if(m==120) y=y-spacey
  if(m==121) y=y-spacey
  if(m==122) y=y-spacey
  if(m==123) y=y-spacey
  
  #12x12
  if(m==124){
    y=11*spacey
    x=0
  }
  if(m==125) x=x+spacex
  if(m==126) x=x+spacex
  if(m==127) x=x+spacex
  if(m==128) x=x+spacex
  if(m==129) x=x+spacex
  if(m==130) x=x+spacex
  if(m==131) x=x+spacex
  if(m==132) x=x+spacex
  if(m==133) x=x+spacex
  if(m==134) x=x+spacex
  if(m==135) x=x+spacex
  if(m==136) y=y-spacey
  if(m==137) y=y-spacey
  if(m==138) y=y-spacey
  if(m==139) y=y-spacey
  if(m==140) y=y-spacey
  if(m==141) y=y-spacey
  if(m==142) y=y-spacey
  if(m==143) y=y-spacey
  if(m==144) y=y-spacey
  if(m==145) y=y-spacey
  if(m==146) y=y-spacey
  return(c(x,y))
}