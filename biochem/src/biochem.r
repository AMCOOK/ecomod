
## http://www.meds-sdmm.dfo-mpo.gc.ca/biochemQuery/authenticate.do?errors=yes


  
    require(chron)
    require(gstat)
    require(snow)
    require(RODBC)


    if (is.null(biochem.user)) biochem.user = "you.need.to.define.biochem.user"
    if (is.null(biochem.password)) biochem.password = "you.need.to.define.biochem.password"


    biochem.db( DS="odbc.datadump" ) 
    biochem.db( DS="flatten" ) 
    biochem.db( DS="scotian.shelf.redo" )
    

    # Biochem data analysis  .. focus on bottom oxygen

    # start data uptake and processing

    p = list()
    p$init.files = loadfunctions( c("common", "bathymetry", "temperature", "biochem" ) ) 
    p$tyears = c(1950:2012)  # 1945 gets sketchy -- mostly interpolated data ... earlier is even more sparse.
    p$newyear = newyear = c( 2012)


    # only one data stream necessary at present .. the largest extent
    p = spatial.parameters( p=p, type= "canada.east" )
    

    for ( j in c("SSE", "canada.east" ) ) {
        
      # ----------------
      # parameters 
      
      #   j = "SSE"
   
        p = spatial.parameters( p=p, type=j )
        p$clusters = rep("localhost",  1) # debug
        # p$clusters = c( rep("kaos.beowulf",23), rep("nyx.beowulf",24), rep("tartarus.beowulf",24) )
      
      # ----------------
      # grid bottom data    
        hydro.db( p=p, DS="bottom.gridded.redo", yr=p$tyears )
      
      # ----------------
      # this glues all the years together
        hydro.db( p=p, DS="bottom.gridded.all.redo", yr=p$tyears  ) 
          
      # ----------------
      # temporal interpolations assuming a sinusoidal seasonal pattern 
        p$clusters = rep("localhost",  24) # ~ 155 hours with 24 cpus and 1950:2012, ESS; 20 GB total
        # ?? p$clusters = c( rep("kaos.beowulf",20), rep("nyx.beowulf",20), rep("tartarus.beowulf",20) ) # speeded ??
        temperature.interpolations( p=p, DS="temporal.interpolation.redo" ) 
          # 1950-2012, SSE took +46 hrs  

      # ----------------
      # simple spatial interpolation (complex/kriging takes too much time/cpu) ==> 3-4 hr/run
      # temperature.interpolations( p=p, DS="spatial.interpolation.redo" ) 
      p$clusters = c( rep("kaos.beowulf",23), rep("nyx.beowulf",24), rep("tartarus.beowulf",24) )
      parallel.run( clusters=p$clusters, n=length(p$tyears), temperature.interpolations, p=p, DS="spatial.interpolation.redo" ) 
    
      # ----------------
      # extract relevant statistics
      # hydro.modelled.db(  p=p, DS="bottom.statistics.annual.redo" )
      # or parallel runs: ~ 1 to 2 GB / process
      # 4 cpu's ~ 10 min
      p$clusters = c( rep("kaos.beowulf",23), rep("nyx.beowulf",24), rep("tartarus.beowulf",24) )
      parallel.run( clusters=p$clusters, n=length(p$tyears),	hydro.modelled.db, p=p, DS="bottom.statistics.annual.redo" ) 

      # ----------------
      # climatology database 
      # 4 cpu's ~ 5 min
      bstats = c("tmean", "tamplitude", "wmin", "thalfperiod", "tsd" )
      # hydro.modelled.db(  p=p, DS="bottom.mean.redo", vname=bstats ) 
      p$clusters = rep( "nyx", length(bstats) )
      parallel.run( clusters=p$clusters, n=length(bstats), hydro.modelled.db, p=p, DS="bottom.mean.redo", vname=bstats  )  
   

      # glue climatological stats together
      temperature.db ( p=p, DS="climatology.redo") 
      
      # annual summary temperature statistics for all grid points --- used as the basic data level for interpolations 
      parallel.run( clusters=p$clusters, n=length(p$tyears), temperature.db, p=p, DS="complete.redo") 



      # ----------------
      # hydro.map( p=p, yr=p$tyears, type="annual" ) # or run parallel ;;; type="annual does all maps
      # hydro.map( p=p, yr=p$tyears, type="global" ) # or run parallel ;;; type="annual does all maps
      p$clusters = c( rep("kaos.beowulf",23), rep("nyx.beowulf",24), rep("tartarus.beowulf",24) )
      parallel.run( clusters=p$clusters, n=length(p$tyears), hydro.map, p=p, yr=p$tyears, type="annual"  ) 
      parallel.run( clusters=p$clusters, n=length(p$tyears), hydro.map, p=p, yr=p$tyears, type="global") 



    }



