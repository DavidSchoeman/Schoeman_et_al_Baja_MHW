# MHW Step 3: Get MHW time series for the US West coast from OISST
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
    callr,
    future
    )
  source("R/Helpers.R")


# Folders and files ------------------------------------------------------------

  output_folder <- "/Volumes/Disk_1/OISST_mhw_by_box"
    if(!dir.exists(output_folder)) dir.create(output_folder)

  global_input <- "/Volumes/Disk_1/OISST/OISST_1982-2026_to_end_sept.nc"
  cropped_input <- global_input %>% 
    str_replace(".nc", "_cropped.nc")
  fin_output <- file.path(output_folder, basename(global_input)) %>% 
    str_replace("OISST_1982-2026", "Oday_mhw_OISST_1982-2026")
  
  pwalk(
    list(
      g_in = global_input,
      c_in = cropped_input,
      f_out = fin_output
      ),
    function(g_in, c_in, f_out) {
      
      cdo_code <- str_c("cdo -L -setmisstodis -sellonlatbox,-178.5,-77.25,8,72 ", g_in, " ", c_in) # Note that you have to fill in the coast, if you want to compare with filled projections
        system(cdo_code)

      source("R/MHW_FUN_Compute_mhw_intensity_WCoast.R")
      get_mhw_by_box(c_in, f_out)
      terminal_code <- str_c("rm ", c_in)
        system(terminal_code)

    }
  )
  
  # Sum montly
  cdo_code <- str_c("cdo -L -monsum ", fin_output, " ", fin_output %>% str_replace("Oday_", "Omon_"))
    system(cdo_code)
    