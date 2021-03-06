  make.timeseries.data = function( areas=NULL, p=NULL ) {
    set = snowcrab.db( DS ="set.complete", p=p )
    if (is.null(areas)) areas = c( "cfa20", "cfa21", "cfa22", "cfa23", "cfa24", "cfa4x", 
      "cfa23slope", "cfa24slope", "cfaslope", "cfanorth", "cfasouth", "cfaall" )
    variables =  variable.list.expand("all.data")
    tsdata =  get.time.series (set, areas, variables, outfile="ts.rdata", from.file=F)  # this returns 1.96SE as "se"
    return( paste("Saved: ts.rdata in",  file.path(project.directory("snowcrab"), "R") ) )
  }
