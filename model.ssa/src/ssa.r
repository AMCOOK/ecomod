

  # Spatial reaction-diffusion model solved via stochastic simulation using the Gillespie Alogrithm
  # exact and approximations with some parallel implementations

  # set.seed(1)

  p = list()
  p$init = loadfunctions( c( "model.ssa", "model.pde" )  )
  
  # details of output storage locations
  p$runname = "test4"

  p$rn = 0  # default run number .. no need to change
  p$outdir = project.directory( "model.ssa", "data", p$runname )
  
  
  p = ssa.model.definition( p, ptype = "default.logistic" ) 
  p = ssa.parameters( p, ptype = "systemsize.debug" ) 
  p = ssa.parameters( p, ptype = "logistic.debug" ) 
  
  
  p = ssa.parameters( p, ptype = "simtimes.debug" ) 
  # overrides
      p <- within( p, { 
        n.times = 3 # 365  # number of censuses  
        t.end =   5 # 365   # in model time .. days
        t.censusinterval = t.end / n.times
        modeltimeoutput = seq( 0, t.end, length=n.times )  # times at which output is desired .. used by pde
      })



  if (ssa.method == "exact" ) {
    p = ssa.db( p , ptype="debug" ) # initialize state variables and propensity matrix
    p = ssa.engine.exact( p )   # using the exact solution ... ~ 1 day -> every 25-30 minutes
  }

 

  if (ssa.method == "approximation" ) {
    # approximation simular to the tau-leaping method:: ideally only one process should be picked at a time ... 
    #   sampling from the propensities is time-expensive, so a number of picks are made in advance and then updated ..
    p$ssa.approx.proportion = 0.01
    p$nsimultaneous.picks =  round( p$nrc * p$ssa.approx.proportion ) # 1% update simultaneously should be /seems to be safe  ~ 1 day -> every 1-2 min or 2hrs->100days 
    p = ssa.db( p , ptype="debug" ) # initialize state variables and propensity matrix
    p = ssa.engine.approximation( p )
  }




  if (ssa.method == "approximation.parallel" ) {

    # use parallel mode to run multiple simulations is the most efficient use of resources 
    # wrapper is "ssa.parallel" (below)
    p$libs = loadlibraries(  "snow" , "rlecuyer" )
  
    p$cluster = c( rep("tethys", 7), rep( "kaos", 23), rep("nyx", 24), rep( "tartarus", 24) ) 
    # p$cluster = 4  # if a single number then run only on localhost with n cores.
    p$cluster = rep( "localhost", 5 )
    
    p$cluster.message.system = "SOCK" 
    #p$cluster.message.system = "PSOCK" 

    # choose and make a copy of the core ssa engine 
    # p$ssa.engine = ssa.engine.exact
    # p$ssa.engine = ssa.engine.approximation
    # p$ssa.engine = ssa.engine.approximation.snowcrab
    p$ssa.engine = ssa.engine.approximation 

    p$nsimultaneous.picks =  round( p$nrc * 0.01 ) # 0.1% update simultaneously should be safe
    p$nruns = 6
 
    p = ssa.db( p , ptype="debug" ) # initialize state variables and propensity matrix
   
    ssa.parallel.run ( DS="run", p=p  ) # run the simulation in parallel
    ssa.parallel.run ( DS="post.process", p=p  ) # postprocess the simulations gathering a few statistics

    # load some of the run results
    X = ssa.parallel.run ( DS="load", p=p, run=1 )  # to load run 1 (to debug) 
    X = ssa.parallel.run ( DS="load", p=p, run="median" ) # etc. .. "mean", "var", "min", "max" ... add as needed.
  
    # delete raw simulation files 
    ssa.parallel.run ( DS="delete.individual.runs", p=p  ) 
  }

  

  if ( pmethod=="rambacked.approximation.parallel" )  {
    # no real spead up vs exact method ... most time is spent swaping memory space / attaching/detaching
    p$libs = loadlibraries(  "parallel", "bigmemory" )
    p$cluster = c( rep("localhost", 4) ) 
    p$cluster = c( rep("tethys", 7), rep( "kaos", 23), rep("nyx", 24), rep( "tartarus", 24) ) 
    p$pconnectmethod = "SOCK" 
    p$nsimultaneous.picks =  round( p$nrc * 0.01 ) # 0.1% update simultaneously should be safe
    p = ssa.db( p , ptype="debug.big.matrix.rambacked" )
    p = ssa.engine.parallel.bigmemory( p  )
  }



  if (ssa.method == "filebacked.approximation.parallel" ) {
    # no real spead up vs exact method ... most time is spent swaping memory space / attaching/detaching
    p$libs = loadlibraries(  "parallel", "bigmemory" )
    p$cluster = c( rep("localhost", 4) ) 
    p$cluster = c( rep("tethys", 7), rep( "kaos", 23), rep("nyx", 24), rep( "tartarus", 24) ) 
    p$cluster.message.system = "SOCK" 
    p$nsimultaneous.picks =  round( p$nrc * 0.01 ) # 0.1% update simultaneously should be safe
    p = ssa.db( p , ptype="debug.big.matr:ix.filebacked" )
    p = ssa.engine.parallel.bigmemory( p )
  }





  if ( pmethod=="compare.with.PDE.solution" ) {
    # Compare with a PDE version of the model 
    require (deSolve)
    require (lattice)
    p$parmeterizations = c( "reaction", "diffusion.second.order.central") 
    p = ssa.db( p , ptype="debug" )  # update state variable to initial conditions
    A = p$X
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
  }


  plot( seq(0, t.end, length.out=n.times), apply(out[], 3, mean), pch=".", col="blue", type="b" ) 

 






