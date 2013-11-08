


  ssa.parallel.run = function( DS="load", p=NULL, run=NULL ) {


    if (DS=="load") {
      if (is.numeric(run)) {
        # load a specific run --- for debugging
        for ( it in 1:p$n.times ) {
          X = array( NA, dim=c(p$nr, p$nc, p$n.times)) 
          X[,,it] = ssa.db( ptype="load", outdir=outdir, tio=it, rn=run ) 
        }
        return(X)
      }

      if (run=="median") {
        load( file.path( p$outdir, "ssa.med.rdata" ) )
        return( ssa.med )
      }
      
      if (run=="mean") {
        load( file.path( p$outdir, "ssa.mean.rdata" ) )
        return( ssa.mean )
      }
      
      if (run=="var") {
        load( file.path( p$outdir, "ssa.var.rdata" ) )
        return( ssa.var )
      }
      
      if (run=="max") {
        load( file.path( p$outdir, "ssa.max.rdata" ) )
        return( ssa.max )
      }
      
      if (run=="min") {
        load( file.path( p$outdir, "ssa.min.rdata" ) )
        return( ssa.min )
      }
    }


    if (DS %in% c("run" ) ) {
      # simple wrapper to run a parallel ssa 
      require(snow)
      cl = makeCluster( spec=p$cluster, type=p$cluster.message.system )  # SOCK works well but does not load balance as MPI 
      clusterSetupRNG(cl)

      idx = clusterSplit( cl, 1:p$nruns )
      ssplt = lapply( idx, function(i) i )

      FUNC = function(ip, p) { 
        if (!is.null(p$init)) for( i in p$init ) source (i)
        if (is.null(ip)) ip = 1:p$nruns   
        for ( rn in ip ) {
          p$rn = rn
          p = p$ssa.engine( p )  # default
        }
        return(ip)
      }

      oo = clusterApplyLB( cl, ssplt, FUNC, p=p )

      stopCluster( cl )
      return (oo)
    }
 

    if (DS =="post.process" ) {

      # now load the saved data and process a few statistics 

      with(p, {
        ssa.mean = ssa.var = ssa.med = ssa.min = ssa.max = array( NA, dim=c(nr, nc, n.times) )
        for ( it in 1:n.times ) {
          X = array( NA, dim=c(nr, nc, nruns)) 
          for ( ir in 1:nruns ) {
            u = ssa.db( ptype="load", outdir=outdir, tio=it, rn=ir )  
            if (is.null(u)) next() 
            X[,,ir] = u
          }
          ssa.med[,,it] = apply( X, c(1,2), median, na.rm=T )
          ssa.mean[,,it] = apply( X, c(1,2), mean, na.rm=T )
          ssa.var[,,it]  = apply( X, c(1,2), var, na.rm=T )
          ssa.min[,,it]   = apply( X, c(1,2), min, na.rm=T )
          ssa.max[,,it]   = apply( X, c(1,2), max, na.rm=T )
        }
        save ( ssa.med, file=file.path( outdir, "ssa.med.rdata" ), compress=TRUE )
        save ( ssa.mean, file=file.path( outdir, "ssa.mean.rdata" ), compress=TRUE )
        save ( ssa.var, file=file.path( outdir,  "ssa.var.rdata" ), compress=TRUE )
        save ( ssa.max, file=file.path( outdir,  "ssa.max.rdata" ), compress=TRUE )
        save ( ssa.min, file=file.path( outdir,  "ssa.min.rdata" ), compress=TRUE )
        save ( p, file=file.path( outdir, "p.rdata" ), compress=TRUE )
      })

    }


    if (DS=="delete.individual.runs") {
      repeat {
        fns = list.files( file.path( p$outdir, "individual.runs"), pattern="*", recursive=TRUE, full.names=TRUE, include.dirs=TRUE  )
        to.delete = fns[ grep( "individual.runs", fns ) ]
        if (length( to.delete) ==0 ) break() 
        file.remove( to.delete ) # newly emptied directories 
      }
    }
  }



