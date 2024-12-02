import jax.numpy as jnp   
import mladutil as mu

def python_ll(beta,X,wt,M):
  lnlam =  mu.linpred(beta,X,1)
  lngam  = mu.linpred(beta,X,2)
  gam = jnp.exp(lngam)

  lli = M["d"]*(lnlam + lngam + (gam - 1)*jnp.log(M["t"])) - jnp.exp(lnlam)*M["t"]**(gam)
  return(jnp.sum(lli))



