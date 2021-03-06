
  figure.timeseries.CW = function( outdir, all.areas=T, type="trawl" ) {
    
    if (all.areas) {
      areas = c("cfa4x", "cfasouth", "cfanorth" )
      regions = c("4X", "S-ENS", "N-ENS")
    } else {
      areas = c("cfasouth", "cfanorth" )
      regions = c("S-ENS", "N-ENS")
    }

    n.regions = length(regions)
    n.areas = length(areas)

    cex.main = 1.4
    cex.lab = 1.3
    cex.axis = 1.3

    if (type == "trawl") {
      set = snowcrab.db("set.merge.det")
      v = "cw.comm.mean"
      fn = file.path( outdir, paste( v, "combined", sep="." ) )
      td =  get.time.series ( from.file=T )
      td = td[ which( td$variable == v) ,]
      td$mean =  10^td$mean
      td$ub = 10^td$ub
      td$lb = 10^td$lb

    }
    if (type == "observer") {
      odb = observer.db( DS="odb" )
      odb = odb[ which(odb$cw>=95),]
      v = "cw"
      fn = file.path( outdir, paste( v, "combined.observer", sep="." ) )
      td =  get.time.series (odb, areas, v, outfile=file.path(tempdir(), "ts.tmp.csv") )
    }
 
    td = td[ order(td$region, td$year) , ]
    td$region = factor(td$region, levels=areas, labels =regions)
    #   td[ which(td$region=="4X" & td$year < 2004), c("mean", "se", "ub", "lb", "n")] = NA

    ylim=range(c(td$mean), na.rm=T); ylim[1]=ylim[1]-0.1*ylim[2]; ylim[2] = ylim[2]+ylim[2]*0.2
    xlim=range(td$year); xlim[1]=xlim[1]-0.5; xlim[2]=xlim[2]+0.5
    
    dir.create( outdir, recursive=T, showWarnings=F  )
    Cairo( file=fn, type="pdf", bg="white",  units="in", width=6, height=8)
    setup.lattice.options()
    pl = xyplot( mean~year|region, data=td, ub=td$ub, lb=td$lb,
    #    layout=c(1,n.areas), xlim=xlim, scales = list(y = "free"),
        layout=c(1,n.areas), xlim=xlim,
            main="Carapace width of the fishable biomass", xlab="Year", ylab="Carapace width (mm)",
            cex.lab=cex.lab, cex.axis=cex.axis, cex.main = cex.main,
            panel = function(x, y, subscripts, ub, lb, ...) {
           larrows(x, lb[subscripts],
                   x, ub[subscripts],
                   angle = 90, code = 3, length=0.05)
           panel.xyplot(x, y, type="b", lty=1, lwd=2, pch=20, col="black", ...)
           panel.abline(h=0, col="gray75", ...)
       }
    )
   
    print(pl) 
    dev.off()
    cmd( "convert   -trim -quality 9  -geometry 200% -frame 2% -mattecolor white -antialias ", paste(fn, "pdf", sep="."),  paste(fn, "png", sep=".") )
     return("Done")
  }



