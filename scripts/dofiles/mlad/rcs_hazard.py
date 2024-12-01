import jax.numpy as jnp   
import mladutil as mu
from   jax import vmap

def python_ll(beta,X,wt,M,Nnodes):
  ## Parameters
  xb    = mu.linpred(beta,X,1)
  xbrcs = mu.linpred(beta,X,2)

  ## hazard function
  def rcshaz(t):
    vrcsgen = vmap(mu.rcsgen_beta,(0,None,None,None))
    return(jnp.exp(vrcsgen(jnp.log(t),M["knots"][0],beta[1],M["R_bhazard"]) + xb))

  ## cumulative hazard
  cumhaz = mu.vecquad_gl(rcshaz,M["t0"],M["t"],Nnodes,())   

  ## return likelhood
  return(jnp.sum(wt*(M["d"]*(xb + xbrcs) - cumhaz)))

