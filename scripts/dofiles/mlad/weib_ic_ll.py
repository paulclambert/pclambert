import jax.numpy as jnp
import mladutil as mu

def python_ll(beta, X, wt, M):
  lam = jnp.exp(mu.linpred(beta,X,1))
  gam = jnp.exp(mu.linpred(beta,X,2))
  
  lli = (jnp.where(M["ctype"]==1,jnp.log(mu.weibdens(M["ltime"],lam,gam)),0)                                 +
         jnp.where(M["ctype"]==2,jnp.log(mu.weibsurv(M["ltime"],lam,gam)),0)                                 +
         jnp.where(M["ctype"]==3,jnp.log(1 - mu.weibsurv(M["rtime"],lam,gam)),0)                             +
         jnp.where(M["ctype"]==4,jnp.log(mu.weibsurv(M["ltime"],lam,gam)-mu.weibsurv(M["rtime"],lam,gam)),0))
  return(jnp.sum(wt*lli))      
