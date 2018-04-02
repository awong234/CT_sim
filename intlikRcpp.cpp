//////////Integrated Likelihood/////
#include <Rcpp.h>
using namespace Rcpp;
// [[Rcpp::export]]
double intlikRcpp(NumericVector parm, NumericMatrix ymat,IntegerMatrix X, int K, NumericMatrix G,
                  NumericMatrix D,int n){
  RNGScope scope;
  double part1;
  double part2;
  double LLout;
  double nG=G.nrow();
  int J=X.nrow();
  NumericMatrix Pm(J,nG);
  NumericMatrix probcap(J,nG);
  NumericVector lik_cond(nG);
  NumericVector nv(n+1,1.0);
  double lik_cond_sum;
  NumericVector lik_marg(n+1);
  double p0=1/(1+exp(-parm(0)));
  double sigma=exp(parm(1));
  double n0=exp(parm(2));
  //calculate probcap
  for (int j=0; j<J; j++) {
    for (int g=0; g<nG; g++){
      probcap(j,g)=p0*exp(-1/(2*pow(sigma,2))*D(j,g)*D(j,g));
    }
  }
  nv(n)=n0;
  // calculate marginal likelihood
  for (int i=0; i<(n+1); i++){
    lik_cond_sum=0;
    for (int g=0; g<nG; g++){
      lik_cond(g)=0;
      for (int j=0; j<J; j++) {
        Pm(j,g)=R::dbinom(ymat(i,j),K,probcap(j,g),TRUE);
        lik_cond(g)+=Pm(j,g);
      }
      lik_cond_sum+=exp(lik_cond(g));
    }
    lik_marg(i)=lik_cond_sum*(1/nG);
  }
  part1=lgamma(n+n0 +1)-lgamma(n0+1);
  part2=0;
  for (int i=0; i<(n+1); i++){
    part2+=nv(i)*log(lik_marg(i));
  }
  LLout=-(part1+part2);
  double to_return;
  to_return = LLout;
  return to_return;
}