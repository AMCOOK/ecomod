
  # maps some fishery performance indicators in Google Earth

  loadfunctions( "shrimp", functionname="load.shrimp.environment.r" )
  loadfunctions( "googleearth" )
    

  refresh.data=F
  if (refresh.data) {
   sm = shrimp.db( DS="shrimp.shrcomlog.redo" )
   sm = shrimp.db( DS="shrimp.marfis.redo" )
  }
   
  # mapping of fisher stats
  # loc = file.path( project.directory("shrimp"), "maps" )  
  loc = file.path( "C:\\Rsaves" )   # <<<< output directory .. change to desired location
  loc.k = file.path( loc, "kml" )
  dir.create(path=loc.k, recursive=T, showWarnings=F)
 
  coords = c("lon", "lat", "elevation")
  pins = c( "pin.blue", "pin.yellow", "pin.red" )
  
  res = 2 # resolution in minutes


  # bring in fishery data
  sm = shrimp.db( DS="shrimp.shrcomlog" )
  sm = sm[ which( sm$btype.simple=="mobile" & is.finite(sm$fhours) ) ,]
  sm = sm[ filter.region.polygon ( sm, region="scotia.fundy" ), ]
  
  # rename a few vars to allow use of function "aggregate.fish.stats", below 
  sm$catch = sm$weight
  sm$effort = sm$fhours
  sm$cpue = sm$catch / sm$effort
  sm = lonlat.change.res ( sm, res=res ) 


  
  for ( i in c( "annual", "monthly", "all", "fiveyear" ) ) {
    
    outfn =  file.path( loc.k, paste( i, "kml", sep=".") ) 
        
    # start kml document
    con = kml.start( outfn,  i  )
      
    # define point styles/colours, etc
    kml.placemark.make( con, item="style", style.id="pin.red", colour="c0ffffff", scale=0.25, 
      href='files/reddot.png' )  # red dot
    kml.placemark.make( con, item="style", style.id="pin.yellow", colour="a0ffffff", scale=0.25, 
      href='files/yellowdot.png' )  # yellow dot
    kml.placemark.make( con, item="style", style.id="pin.blue", colour="a0ffffff", scale=0.25, 
      href='files/bluedot.png' )  

    # main folder start
    kml.folder.start( con, folder.name="Scotian Shelf Shrimp", 
      desc="Scotian Shelf Shrimp fishery statitics (Bedford Institute of Oceanography)" 
    )

    for (v in c("catch", "effort", "cpue" ) ) {
      sm$w = recode.time.block ( X=sm, type=i )  
      o = aggregated.fish.stats( sm )
       
      kml.folder.start( con, v )
      for ( y in sort( unique( o$w ) ) ) {
        oY = o[ which(o$w==y ) , ]
        xyz = oY[ , c( "lon", "lat", v )]
        xyz = xyz [ which( is.finite( xyz[,v] ) ) ,]
        xyz$elevation = 0  # a dummy variable
        xyz[, v] = log10 ( xyz[, v] ) 
        er = quantile( log10( o[ which( is.finite(o[,v]) ),v] ), probs=c(0, 0.333, 0.666, 1) ) 
        xyz$val = as.numeric( cut( xyz[,v], breaks=er, ordered_result=T, include.lowest=T ))
        uniquevalues = sort(unique( xyz$val) )  # low=1, middle=2, high=3

        kml.folder.start( con, y )
        for ( g in uniquevalues) {
          gi = which( xyz$val == g ) 
          kml.folder.start( con, g )   # low=1, middle=2, high=3
            for ( h in gi ) { 
              kml.placemark.make( con, desc=round(10^(xyz[h,v])), style.id=pins[ xyz[h,"val"] ], x=xyz[h, coords] ) 
            }
          kml.folder.end( con ) # yr
        }
        kml.folder.end( con ) # yr
      } # end y  
      kml.folder.end( con ) # v
    } # end  v
    kml.folder.end( con ) # end main
  kml.end( con )  # end file
  print( outfn )
} # end i




