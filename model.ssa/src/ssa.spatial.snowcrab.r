




############## Model Parameters 
# Basic logistic with spatial processes  
# Using: logistic model as base
# dX/dt = rX(1-X/K)

  

  # set.seed(1)


  p = list()
  p$init = loadfunctions( c( "model.ssa", "model.pde", "common", "snowcrab" )  )
 
  p$np = 6  # no. of processes
  
  
  # pde related params
  p$eps  = 1e-6   # A in units of t/km^2 -- number below which abundance can be considered zero ~ 1 kg/ km^2 = 1g / m^2
  p$atol = 1e-9  # atol -- absolute error tolerance for lsoda
  p$rtol = 1e-9  # rtol -- relative error tolerance for lsoda
  


  ## read in PDE -related parameterizations
  p$spatial.domain = "snowcrab"  # spatial extent and data structure 
  p = model.pde.define.spatial.domain(p)
  
  # rate of increase per day .. for snow crab r~1 per capita per year ===> therefore per day = 1/365
  # p$modeltimes = c( 0, 5, 100, 200, 400, 800, 1600 )  # times at which output is desired
  p$modeltimeoutput = c( 0, 5, 10, 20, 21, 22, 23, 24, 25, 40, 50 )  # times at which output is desired

  p$parmeterizations = c( 
    "reaction.K.snowcrab.mature", 
    "reaction.r.constant", 
    # "diffusion.random.normal",
    "diffusion.second.order.central",
    # "diffusion.first.order.upwind",
    # "advection.random.normal",
    #"advection.random.normal",
    ""
  ) 

  p$y = 2010
  
 
  # model parameters
  p$b = 3 / 365 # birth rate
  p$d = 2 / 365 # death rate
  p$r = 1   ### not really used in SSA but must match above


  p$K = model.pde.external.db( p=p, method="snowcrab.male.mature", variable="abundance.mean" ) 
  p$K[ p$inothabitat ] = p$eps
  iifin = which (!is.finite( K) ) 
  if (length(iifin)>0) p$K[iifin] = p$eps


  # abundance::
  X = model.pde.external.db( p=p, method="snowcrab.male.mature", variable="abundance.mean" ) 
  X[] = X[] * runif( 1:length(X) ) + p$eps 

  # in the stochastic form:: using a birth-death Master Equation approach 
  # birth = b
  # death = d
  # carrying capacity = K
  # r = b-d >0 
 
  
  # diffusion coef d=D/h^2 ; h = 1 km; per year (range from 1.8 to 43  ) ... using 10 here 
  # ... see b ulk estimation in model.lattice/src/_Rfunctions/estimate.bulk.diffusion.coefficient.r
  p$dr=10 
  p$dc=10 
  p$Da = matrix( ncol=p$nc, nrow=p$nr, data=10 ) 

  
  
  
  # model run dimensions and times
  p$n.times = 365  # number of censuses  
  p$t.end =   365   # in model time .. days
  p$t.censusinterval = p$t.end / p$n.times
  p$modeltimeoutput = seq( 0, p$t.end, length=p$n.times )  # times at which output is desired .. used by pde
 
  
  # rows are easting (x);  columns are northing (y) --- in R 
  # ... each cell has dimensions of 1 X 1 km ^2
 
  expand.parameters.in.space = FALSE
  if (expand.parameters.in.space) {
    p$r = matrix( nrow=p$nr, ncol=p$nc, data=rnorm( p$nn, mean=p$r, sd=p$r/10) )
    p$K = matrix( nrow=p$nr, ncol=p$nc, data=rnorm( p$nn, mean=p$K, sd=p$K/10) )
    p$Da = matrix( ncol=p$nc, nrow=p$nr, data=rnorm( p$nn, mean=p$Da, sd=p$Da/10 ) ) 
  }



  out = array( 0, dim=c( p$nr, p$nc, p$n.times ) )
  







  ####################   SSA 
  # Spatial prototype for Gillespie Alogrithm:  direct computation of everything


  simtime = itime = next.output.time = nevaluations = 0
 
  # initiate P the propensities 
  P = array( 0, dim=c( nr, nc, np ) )
  nP = length(P)
  jr = 1:nr
  jc = 1:nc
  for ( ip in 1:np ) P[,,ip] = eval( parse( text=RE.logistic.spatial( ip ) ) ) 
  P.total = sum(P)
 
  
# Rprof()

  repeat {
    
    prop = .Internal(pmax(na.rm=FALSE, 0, P/P.total  ))   # using .Internal is not good syntax but this gives a major perfance boost > 40%
    j = .Internal(sample( nP, size=1, replace=FALSE, prob=prop ) )

    # remap random element to correct location and process
    jn  = floor( (j-1)/nn ) + 1  # which reaction process
    jj = j - (jn-1)*nn  # which cell 

    # focal cell coords
    cc = floor( (jj-1)/nr ) + 1
    cr = jj - (cc-1) * nr 

    # determine the appropriate operations for the reaction
    o = NU.logistic.spatial(jn) 

    no = dim(o)[1]
    ro = .Internal( pmin( na.rm=FALSE, nr, .Internal( pmax( na.rm=FALSE, no, cr + o[u,1] ) ) ) )
    co = .Internal( pmin( na.rm=FALSE, nc, .Internal( pmax( na.rm=FALSE, no, cc + o[u,2] ) ) ) )

    for( u in 1:no ) {
      # update state vector (X) 
      X[ro[u],co[u]] = .Internal( pmax( na.rm=FALSE, 0, X[ro[u],co[u]] + o[u,3] ) )

      # update propensity in focal and neigbouring cells 
      jr = .Internal( pmin( na.rm=FALSE, nr, .Internal( pmax( na.rm=FALSE, 1, ro[u] + c(-1,0,1) ) ) ) )
      jc = .Internal( pmin( na.rm=FALSE, nc, .Internal( pmax( na.rm=FALSE, 1, co[u] + c(-1,0,1) ) ) ) )

      for ( iip in 1:np) {
        dP = eval( parse(text=RE.logistic.spatial( iip ))) 
        P.total = P.total + sum( P[jr,jc,iip] - dP )
        P[jr,jc,iip] = dP
      }
    }

    nevaluations = nevaluations + 1
    simtime = simtime - (1/P.total) * log( runif( 1))   # ... again to optimize for speed
    if (simtime > t.end ) break()
    if (simtime > next.output.time ) {
      next.output.time = next.output.time + t.censusinterval 
      itime = itime + 1  # time as index
      out[,,itime] = X[]
      P.total = sum(P) # reset P.total to prevent divergence due to floating point errors
      cat( paste( itime, round(P.total), round(sum(X)), nevaluations, Sys.time(), sep="\t\t" ), "\n" )
      nevaluations = 0 # reset
      image( out[,,itime], col=heat.colors(100)  )
    }
  }


#  Rprof(NULL)




  plot( seq(0, t.end, length.out=n.times), out[1,1,], pch=".", col="blue", type="b" ) 
  







  ### ---------------------------------------
  ### Compare with a PDE version of the model 


  require (deSolve)
  require (lattice)

  A = array( 0, dim=c(p$nr, p$nc ) ) 
  debug = TRUE
  if (debug) {
    rwind = floor(p$nr/10*4.5):floor(p$nr/10*5.5)
    cwind = floor(p$nc/10*4.5):floor(p$nc/10*5.5)
    A = array( 0, dim=c(p$nr, p$nc ) ) 
    A[ rwind, cwind ] = round( p$K * 0.8 )
    # X[,] = round( runif(nn) * K )
  }
 
  
  p$parmeterizations = c( "reaction", "diffusion.second.order.central") 

  
  out <- ode.2D(  times=p$modeltimeoutput, y=as.vector(A), parms=p, dimens=c(p$nr, p$nc),
    func=single.species.2D.logistic, 
    method="lsodes", lrw=1e8,  
    atol=p$atol 
  )
 

  image.default( matrix(out[365,2:10001], nrow=100), col=heat.colors(100) )

  diagnostics(out)
  
  plot(p$modeltimeoutput, apply(out, 1, sum))
  
  image(out)
  hist( out[1,] )

  select <- c(1, 4, 10, 20, 50, 100, 200, 500 )
  image(out, xlab = "x", ylab = "y", mtext = "Test", subset = select, mfrow = c(2,4), legend =  TRUE)
 







  # adding discontinuities -- e.g. fishing
    
  p$perturbation = "fishing.random"
  p$fishing.event = c( 21  )

  out <- ode.2D( times=p$modeltimeoutput, y=as.vector(A), parms=p, 
      dimens=c(p$nr, p$nc), method=rkMethod("rk45ck"), 
      func=single.species.2D.logistic,    
      events = list(func=perturbation.event, time=p$fishing.event ), 
      atol=p$atol 
  )
  



