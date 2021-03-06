 
  # ---------------------------------------------------------------------
  # Wrapping function to access GMT (Generic Mapping Tools)
  #     
  #     Warning: GMT calls must be understood by your system: 
  #     i.e., GMT program must be in the file path 
  #     "Gawk" is used in some instances ..  this can eventually be implemented directly in R
  
  make.maps = function( U, params, variables, plottimes, basedir, conversions="ps2png", delta=1, init.files=NULL, db="snowcrab", cltype="SOCK") {
    require(parallel)
    nid = length( variables )
    if (!params$do.parallel) {
      make.maps.core(U=U, params=params, variables=variables, plottimes=plottimes, basedir=basedir, conversions=conversions, delta=delta, init.files=init.files, db=db)
    } else if (params$do.parallel) {
      cl = makeCluster( spec=clusters, type=cltype)
      ssplt = lapply( clusterSplit(cl, 1:nid), function(i) i )   # subset data into lists
      clusterApplyLB( cl, ssplt, make.maps.core, 
        U=U, params=params, variables=variables, plottimes=plottimes, basedir=basedir, conversions=conversions, delta=delta, init.files=init.files, db=db )
      stopCluster(cl)
    }
    return ("Completed mapping")
  }


