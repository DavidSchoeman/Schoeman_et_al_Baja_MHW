# MHW Step 2: Sum daily MHW time series for the US West coast by month
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

  input_folder <- "/Volumes/Jet_Drive_too/mhw_by_box_NUR"
  output_folder <- "/Volumes/Jet_Drive_too/mhw_by_box_NUR_Omon"
    if(!dir.exists(output_folder)) dir.create(output_folder)

  input_files <- dir(input_folder, full.names = TRUE)
  output_files <- file.path(output_folder, basename(input_files)) %>% 
    str_replace("Oday_", "Omon_")
  
  pwalk(
    list(
      f_in = input_files,
      f_out = output_files
      ),
    function(f_in, f_out) {
      
      cdo_code <- str_c("cdo -L -monsum ", f_in, " ", f_out)
        system(cdo_code)

    }
  )
  