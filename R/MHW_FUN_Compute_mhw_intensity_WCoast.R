# MHW Function 2: Function to compute daily MHW intensity per lonlat box
	# Written by Dave Schoeman (david.schoeman@gmail.com)
		# October 2026


# Source the helpers -----------------------------------------------------------

  pacman::p_load(
    tidyverse,
    terra,
    furrr,
    sf,
    heatwaveR,
    tictoc,
    callr
    )
  source("R/Helpers.R")


# Get MHW intensity -------------------------------------------------------

  	get_mhw_by_box <- function(f, o_file) {
  	  
	  # Internal functions
  	  # Function for terra:app
    	calc_mhw_intensity <- function(sst_vec, time_vec) {
    	  pacman::p_load(
    	    tidyverse,
    	    terra,
    	    heatwaveR
    	  )
    	  if(!all(is.na(sst_vec))) {
      	  df <- data.frame(t = time_vec, temp = sst_vec)
      	  clim <- ts2clm(data = df, 
      	                 climatologyPeriod = c("1983-01-01", "2012-12-31")) # As per Oliver et al. and Smale et al.
      	  out <- detect_event(data = clim) %>% 
      	    pluck("climatology") %>% 
      	    mutate(intensity = temp - seas,
      	           mhw_int = (ifelse(event, intensity, 0) * 1000) %>% 
      	             round() %>% 
      	             as.integer()  #*** Note convert this to an integer for more efficient storage
      	           ) %>% 
      	    drop_na(temp)
      	  return(out$mhw_int)
      	  } else {
      	    return(rep(NA, length(sst_vec)))
        	  }
    	}
	    
  # Do the work
  	sst_raster <- rast(f)
  	dts <- sst_raster %>% 
  	  time() %>% 
  	  as.character() %>% 
  	  str_remove(" 12:00:00") %>% 
  	  as.Date()
  	
  	mhw_intensity <- app(
  	  sst_raster,
  	  fun = calc_mhw_intensity,
  	  time_vec = dts,
  	  cores = 16 # Enable multi-core parallel processing
  	)
  	time(mhw_intensity) <- dts
  
  writeCDF(
    mhw_intensity, 
    filename = o_file, 
    varname = "mhw_int", 
    longname = "Daily MHW intensity during identified MHWs * 1000", 
    unit = "degC", 
    prec = "integer",
    overwrite = TRUE
  )
      
	}
	
	