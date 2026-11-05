# MHW Step 1: Get MHW time series for the US West coast
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

  input_folder <- "/Volumes/Adrienne_Hons_2025/CMIP_tos_Oday_merged_std_regridded"
  output_folder <- "/Users/davidschoeman/mhw_by_box"
    if(Sys.info()[["user"]] == "dschoema") output_folder <- str_replace(output_folder, "davidschoeman", "dschoema")
    if(!dir.exists(output_folder)) dir.create(output_folder)

  global_inputs <- dir(input_folder, full.names = TRUE) %>% 
    str_subset("_cropped.nc", negate = TRUE)
  cropped_inputs <- global_inputs %>% 
    str_replace(".nc", "_cropped.nc")
  fin_outputs <- file.path(output_folder, basename(global_inputs)) %>% 
    str_replace("_rgdw_", "_WCimp1000_") %>% 
    str_replace("tos_", "mhw_")
  
  pwalk(
    list(
      g_in = global_inputs,
      # f_in = fast_inputs,
      c_in = cropped_inputs,
      f_out = fin_outputs
      ),
    function(g_in, c_in, f_out) {
      
      cdo_code <- str_c("cdo -L -sellonlatbox,-178.5,-77.25,8,72 ", g_in, " ", c_in)
        system(cdo_code)

      source("R/MHW_FUN_Compute_mhw_intensity_WCoast.R")
      get_mhw_by_box(c_in, f_out)
      terminal_code <- str_c("rm ", c_in)
        system(terminal_code)

    }
  )
  