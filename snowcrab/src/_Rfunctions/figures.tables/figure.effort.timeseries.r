  figure.effort.timeseries = function( yearmax, outdir=NULL, outfile=NULL, type="line" ) {
   
    regions = c("cfanorth", "cfasouth", "cfa4x")
    e = NULL
    for (r in regions) {
      res = get.fishery.stats.by.region(Reg=r)
      e = cbind( e, res$effort  )
    }
    
    e = e / 1000

    e = as.data.frame( e )
    colnames(e) = regions
    rownames(e) = res$yr
   
    e = e[ which( as.numeric(rownames(e)) <= yearmax ), ] 
    uyrs = as.numeric(rownames(e) ) 

    
    dir.create( outdir, recursive=T, showWarnings=F )
    fn = file.path( outdir, paste(outfile,"png",sep="." ) )
    Cairo( file=fn, type="png", bg="white",, pointsize=30, units="in", width=6, height=4, dpi=300  )

    if (type=="bar") {
      e[is.na(e)] = 0
      formed.data = t(as.matrix(e))
      barplot( formed.data, space=0, xlab="Year", ylab="Effort (1000 trap hauls)", col=cols)
      legend(x=1, y=130, c("N-ENS", "S-ENS", "4X"), fill=cols[reverse], bty="n")
    }
    if (type=="line") {
      pts = c(19, 22, 24)
      lns = c(1, 3, 1)
      cols = c("grey10", "grey10",  "grey20")
      e[ which(e==0) ] = NA
      yrange = range (e, na.rm=T)
      yrange[1] = 0
      xrange = range(uyrs)
      xrange[1] = xrange[1] - 0.5
      xrange[2] = xrange[2] + 0.5
      m=1; plot( uyrs, e[,m],  type="b", ylab="Effort (1000 trap hauls)", xlab="Year", col=cols[m], lwd=3, lty=lns[m], pch=pts[m], axes=F, xlim=xrange, ylim=yrange)
      m=2; points(uyrs, e[,m], type="b", col=cols[m], lwd=3, lty=lns[m], pch=pts[m])
      m=3; points(uyrs, e[,m], type="b", col=cols[m], lwd=3, lty=lns[m], pch=pts[m])
      axis( 1 )
      axis( 2 )
      legend(x=1980, y=100, c("N-ENS", "S-ENS", "4X"), bty="n", lty=lns, lwd=3, pch=pts, col=cols, cex=1.4 )
    }
    dev.off()
    cmd( "convert -trim -frame 10x10 -mattecolor white ", fn, fn )
    table.view( e)
    return( fn )
  }


