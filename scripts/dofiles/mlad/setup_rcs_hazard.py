from scipy.special import roots_legendre
from jax import vmap
import jax.numpy as jnp
import  mladutil as mu

def mlad_setup(M):
  vrcsgen = (vmap(mu.rcsgen,(0,None,None),0))
  nodes, weights = roots_legendre(M["Nnodes"])
  
  nodes2 = 0.5*(M["t"] - M["t0"])*nodes + 0.5*(M["t"] + M["t0"])
  M["allnodes"] = vrcsgen(jnp.log(nodes2),M["knots"][0],M["R_bhazard"])
  M["weights"] =  weights 
  return(M)
