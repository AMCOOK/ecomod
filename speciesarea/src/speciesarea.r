
	### requires an update of databases entering into analysis: 
  # snow crab:  "cat" and "set.clean"
  # groundfish: "sm.base", "set"
  # and the glue function "bio.db"


# create base species area stats  ... a few hours

	
  p = list()
  p$libs = loadlibraries ( c("chron", "fields", "mgcv", "sp", "parallel")) 
  p$init.files = loadfunctions( c( "common", "bathymetry", "temperature", "habitat", "taxonomy", "bio", "speciesarea"  ) )
 
  # faster to use RAM-based data objects but this forces use only of local cpu's
  # configure SHM (shared RAM memory to be >18 GB .. in fstab .. in windows not sure how to do this?)
  p$use.bigmemory.file.backing = FALSE  
  # p$use.bigmemory.file.backing = TRUE  # file-backing is slower but can use all cpu's in a distributed cluster


  p = spatial.parameters( p, "SSE" )  # data are from this domain .. so far
  p$data.sources = c("groundfish", "snowcrab") 
  p$speciesarea.method = "glm" 
  
  p$pred.radius = 50 # km
  p$timescale = c( 0, 1, 2 ) # yr
  p$lengthscale = c( 10, 15, 20, 25, 30, 35, 40, 45, 50, 60, 70, 80, 90, 100, 110, 120 )  # km used in counting for rarefaction curve
  p$interpolation.distances = 25  # habitat interpolation scale
   
  p$taxa = "maxresolved"
  # p$taxa = "family.or.genera"
  # p$taxa = "alltaxa"
  
  p$season = "allseasons"

  # choose:
  # p$clusters = c( rep( "nyx.beowulf", 24), rep("tartarus.beowulf", 24), rep("kaos", 24 ) )
  # p$clusters = rep( "localhost", 1)  # if length(p$clusters) > 1 .. run in parallel
  # p$clusters = rep( "localhost", 2 )
  # p$clusters = rep( "localhost", 8 )
  # p$clusters = rep( "localhost", 4 )
  p$clusters = rep("localhost", detectCores() )
  

  p$yearstomodel = 1970:2013 # set map years separately to temporal.interpolation.redo allow control over specific years updated
  p$varstomodel = c( "C", "Z", "T", "Npred" )

  p$modtype = "complex" 
  
  p$habitat.predict.time.julian = "Sept-1" # Sept 1
 
  p$spatial.knots = 100
  p$movingdatawindow = c( -4:+4 )  # this is the range in years to supplement data to model 
  p$movingdatawindowyears = length (p$movingdatawindow)

  p$optimizer.alternate = c( "outer", "nlm" )  # first choice is bam, then this .. see GAM options



# -------------------------------------------------------------------------------------
# Run BIO.DB to update the multi-survey databases /home/jae/ecomod/bio/src/bio.r
# -------------------------------------------------------------------------------------


  # count and record rarification curves from all available data --- refresh "bio.db" ~/ecomod/bio/src/bio.r  
  speciesarea.db( DS="speciesarea.counts.redo", p=p )  # 60 MB / process  -- can use all cpus
  

  # compute species-area relationships 
  speciesarea.db( DS="speciesarea.stats.redo", p=p ) # ~ 1 minute
  speciesarea.db( DS="speciesarea.redo", p=p ) # intermediary file for modelling and interpolation



# -------------------------------------------------------------------------------------
# Generic spatio-temporal interpolations and maping of data 
# using the interpolating functions and models defined in ~ecomod/habitat/src/
# -------------------------------------------------------------------------------------

  #required for interpolations and mapping 
  p$project.name = "speciesarea"
  p$project.outdir.root = project.directory( p$project.name, "analysis" )


  # create a spatial interpolation model for each variable of interest 
  # full model requires 30-40 GB ! no parallel right now for that .. currently running moving time windowed approach
  p = make.list( list(vars= p$varstomodel, yrs=p$yearstomodel ), Y=p ) 
  parallel.run( habitat.model, DS="redo", p=p ) 
  # habitat.model ( DS="redo", p=p ) 
 

  # predictive interpolation to full domain (iteratively expanding spatial extent)
  # ~ 5 GB /process required so on a 64 GB machine = 64/5 = 12 processes 
  p = make.list( list( yrs=p$yearstomodel ), Y=p )
  parallel.run( habitat.interpolate, p=p, DS="redo" ) 
  # habitat.interpolate( p=p, DS="redo" ) 


  # map everything
  p = make.list( list(v=p$varstomodel, y=p$yearstomodel ), Y=p )
  parallel.run( habitat.map, p=p, type="annual"  ) 
  # habitat.map( p=p, type="annual"  ) 




