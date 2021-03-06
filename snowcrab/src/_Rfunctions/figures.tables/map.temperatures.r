
  map.temperatures = function( p, outdir, plottimes, conversions, init.files ) {
    tx = get.temperatures(DS="OE.saved")
    variables="t"
    tx$sa = 1/tx$err  # this mapping routine expects a weighting variable ("sa")
    p$block = F  # override ... the data are already blocked
    p$mapres = "1min"
    p = gmt.resolution(p) # refresh due to change in mapres

    p$maskres      = "-S15k"
    p$interpres    = "-Sb"
    p$tension      = "-T0.4"  # 1= harmonic surface
    make.maps(tx, p, variables=variables, plottimes=plottimes, basedir=outdir, conversions=conversions, init.files=init.files)
  }


