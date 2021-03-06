

  temperature.timeseries.interpolate = function( ip=NULL, p, P, B ) {


    if (exists( "init.files", p)) loadfilelist( p$init.files ) 
    if (exists( "libs", p)) loadlibraries( p$libs ) 
    if (is.null(ip)) ip = 1:p$nruns

    for ( iip in ip ) {
      mm = p$runs[iip,"loc"]
      Pi=P[mm,]
      print (mm)			
      
      for ( dm in p$dist.km ) { 
        drange = c(-1,1) * dm
        plon0 = Pi$plon + drange
        plat0 = Pi$plat + drange
        i = which( 
          B$plon > plon0[1] & 
          B$plon < plon0[2] & 
          B$plat > plat0[1] & 
          B$plat < plat0[2] &
          B$z > (Pi$z * p$depthrange.fraction[1] )  &  # +/1 25% of depth
          B$z < (Pi$z * p$depthrange.fraction[2] )   
        ) 
        if (length(i) > p$nMin.tbot ) break()  # nMin.tbot is the prefered number of data points
      }						
      
      if (length(i) == 0 ) next()  # do not return yet as raw data must be placed into the output 

      b = B[i,] # faster to reduce the size of  B
      # weight data in space: inverse distance squared
      b$w = 1 / (( Pi$plon - b$plon)**2 + (Pi$plat - b$plat)**2 )
      b$w[ which( is.infinite( b$w ) ) ] = 1
        

      OP = expand.grid( plon=Pi$plon, plat=Pi$plat, z=Pi$z, weekno=p$wtimes, yr=p$tyears )

      OP = timeseries.impute( x=b, OP=OP, method=p$tsmethod, harmonics=p$tsharmonics, gam.optimizer=p$gam.optimizer ) 
      
      OP$id = c( 1: nrow(OP) )
      OPnrow = nrow(OP)

      # return real data back into the predictions
      ii = which( b$plon==Pi$plon & b$plat==Pi$plat )
      if ( length (ii) > 0 ) {
        b = b[ii,]
        b$yrwk = b$yr + b$weekno/52 
        bd = duplicated( b$yrwk )
        if (any( bd)) {
          for ( bi in which(bd) ) {
            bj = which( b$yrwk == b$yrwk[bi] )
            b$t[bj] = mean( b$t[bj] ) # update dups temps with mean
          }
        }
        b = b[ -which(bd), ]
        ii = which( b$plon==Pi$plon & b$plat==Pi$plat ) #update list
        b = b[ii, c("yr","weekno","t") ]
        OP = merge ( OP, b, by=c("yr", "weekno"), all.x=TRUE, all.y=FALSE, sort=TRUE )
        orig = which( is.finite( OP$t ) )
        if ( length( orig) > 0 ) {
          OP$fit[orig] = OP$t[orig]
          OP$se[orig] = 0  # fix to 0 as it is raw observation
        }
      }

      debug = FALSE
      if (debug) {
        x11()
        plot(  fit ~ I(yr+weekno/52), data=OP, pch=".", type="l")
        points( t ~I(weekno/52 + yr), data=b, pch="*", col="red")
      }
 
      tbot <- attach.big.matrix( p$tbot.desc )
      tbot[ mm,] <- OP$fit
      
      tbot.se <- attach.big.matrix( p$tbot.se.desc )
      tbot.se[mm,] <- OP$se
    
    } # end each point

  }


