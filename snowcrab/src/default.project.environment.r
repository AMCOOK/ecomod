

  loadlibraries ( c( 
    "DBI", "Cairo", "Hmisc", "chron", "vegan", "akima", "fields", "lattice", 
    "gstat", "rgdal", "maptools"
  ) )


	# files required to initialised the same base state when running in parallel mode
  init.files = loadfunctions( c("common", "snowcrab", "groundfish", "substrate", "temperature", "taxonomy", "habitat", "habitatsuitability", "bathymetry" ) )
	init.files = c( ecomod.rprofile, init.files )
 
	workpath = file.path( project.directory("snowcrab"), "R" )
  dir.create( workpath, recursive=T, showWarnings=F )
  setwd (workpath)


  # Global snow crab parameters
  
	# sex codes
    male = 0 
    female = 1
    sex.unknown = 2

  # maturity codes
    immature = 0
    mature = 1 
    mat.unknown = 2

    planar.corners = data.frame(rbind( cbind( plon=c(220, 990), plat=c(4750, 5270) ))) # for plots in planar coords
    
  # default plotting time format
    plottimes=c("annual", "globalaverage")

  # default figure generation (from maps)
    conversions=c("ps2png")
 
	# default time format
    dateformat.snow = c(dates="year-m-d", times="h:m:s")  # default date output format for chron objects
 

