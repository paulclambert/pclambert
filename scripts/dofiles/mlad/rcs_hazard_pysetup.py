import jax.numpy as jnp   
import mladutil as mu

def python_ll(beta,X,wt,M):
  ## Parameters
  xb    = mu.linpred(beta,X,1)
  xbrcs = mu.linpred(beta,X,2)

  ## cumulative hazard
  ch_at_nodes = jnp.exp(jnp.matmul(M["allnodes"],beta[1][:-1]) + beta[1][-1] + xb)
  cumhaz = (0.5*(M["t"]-M["t0"]))*jnp.sum(M["weights"]*ch_at_nodes,axis=1,keepdims=True)

  return(jnp.sum(wt*(M["d"]*(xb + xbrcs) - cumhaz)))

