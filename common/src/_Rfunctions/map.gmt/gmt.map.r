  gmt.map = function( P, toplot, year, vname, conversions="ps2png" ) {

		tmpdir  = tempdir()
 

    # tmp local GMT files
      cpt   = file.path(tmpdir, make.random.string(".gmt.cpt"))  # palette file
      gmtgrid  = file.path(tmpdir, make.random.string("gmt.grid"))
      bin   = file.path(tmpdir, make.random.string(".gmt.bin"))  # binary data
      clip  = file.path(tmpdir, make.random.string(".gmt.clip"))
      indat = file.path(tmpdir, make.random.string(".gmt.indat"))
      blocked = file.path(tmpdir, make.random.string(".gmt.blocked"))
      annotations = file.path(tmpdir, make.random.string(".gmt.annotations"))
      outfile = paste( file.path(tmpdir, make.random.string(".gmt.outfile")), ".ps", sep="") # final postscript file

    # final data check
      toplot = toplot[is.finite(rowSums(toplot)) ,]
      if (dim(toplot)[2]==3) toplot$dummy=1  # mimic a weighting variable when one does not exist

      write.table( toplot, file=indat, quote=F, col.names=F, row.names=F)
   
      # set up colour scale
      colscale = paste( "-C", P$gmtcol, sep="" )
      colpalette  = paste("-C", cpt, sep="")
      cmd( "makecpt", colscale, P$crange, P$colourflags, ">", cpt )

    # define some local parameters
      gmtappend = "-O -K"
      gmt.prep (fnt=P$fnt, psres=P$psresolution)

    # begin mapping
      cmd( "psbasemap", P$region, P$gmtproj, P$annot, "-K >", outfile )

     # overlay data
      if (P$block) {
        add.flag = ""
        if (P$blocktype=="mean") block.prg="blockmean"
        if (P$blocktype=="median") block.prg="blockmedian"
        if (P$blocktype=="mode") block.prg="blockmode"
        if (P$blocktype=="sum") {
          block.prg = "blockmean"
          add.flag = "-Sz"  # forces a sum as output
        }
        cmd( block.prg, P$region, P$res, indat, add.flag, "-W >", blocked )
        cmd( "surface", P$region, P$res, blocked, P$tension, paste("-G", gmtgrid, sep="") )
      } else if (! P$block) {
        cmd( "surface", P$region, P$res, indat, P$tension, paste("-G", gmtgrid, sep="") )
      }

      cmd( "psmask", indat, P$region, P$gmtproj, P$res, P$maskres, gmtappend, ">>", outfile )
      cmd( "grdimage", gmtgrid, P$region, P$gmtproj, gmtappend, P$interpres, colpalette, ">>", outfile )
      cmd( "psmask -C", gmtappend, ">>", outfile )

      # various overlays
      cmd( "cat", P$basemap, ">>", outfile ) # bathymetry
      if (!is.null(P$overlay)) {
        if ( length(P$overlay)>0) {
          for (o in P$overlay) {
            if ( o == "" ) next()
            cmd( "psxy", get.polygon.data.location(o), P$region, P$gmtproj, gmtappend, P$polygon.options, ">>", outfile ) # polygons
      }}}

      cmd( "pscoast", P$region, P$gmtproj, P$coast.options, gmtappend, ">>", outfile ) # coastline
      cmd( "psscale", colpalette, P$incscale, P$scale.location, gmtappend, ">>", outfile ) # colourscale
      if (P$annot.text=="") P$annot.text = year
      if (as.character( P$annot.text) == "1000" ) P$annot.text = "Mean state"
      write( paste(P$annot.lon0, P$annot.lat0, P$annot.fontsize, P$annot.angle, P$annot.fontno, P$annot.justify, P$annot.text), file=annotations )
      cmd( "pstext", annotations, P$region, P$gmtproj, "-O >>", outfile )  # variablename, year
      remove.files ( c( cpt, gmtgrid, bin, clip, indat, blocked, annotations ))
          
      if (!is.finite(conversions)) { #assume postscript not needed
        graphics.convert ( outfile, P$outfile.basename, conversions )
      } else { # assume just the postscript file is required
        file.copy(from=outfile, to=paste( P$outfile.basename,"ps",sep="."), overwrite=T)
      }
    
    gmt.cleanup ()
    
 }


