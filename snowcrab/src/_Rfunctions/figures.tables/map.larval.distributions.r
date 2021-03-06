
  map.larval.distributions = function(p, outdir, conversions, init.files ) {

    xyz = read.table(file=file.path( project.directory("snowcrab"), "data", "larvae", "brachyura.xyz"),  sep = "\t")
    colnames(xyz) = c("lon", "lat", "n.m3")
    xyz$n.m3 = log(xyz$n.m3)
    xyz$yr = 2000
    xyz$sa = 1

    p$mapres = "2min"
    p$block = F
    p$tension = "-T0.75"  # 0.35+ for steep; 0.25 for smooth
    p$maskres = "-S20k"
    p$interpres = "-Sb"
    p$basedir=outdir

    variables="n.m3"
    make.maps(set=xyz, p, variables, plottimes="annual", p$basedir, conversions=conversions, init.files=init.files )
  }



