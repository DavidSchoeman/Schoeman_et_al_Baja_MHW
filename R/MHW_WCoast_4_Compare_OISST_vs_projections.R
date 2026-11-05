# MHW Step 4: Compare monthly projections with OISST cumulative MHW intensity for September 2026
	# Written by Dave Schoeman (david.schoeman@gmail.com)
		# October 2026


# Attach package libraries -----------------------------------------------------

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


# Folders and files ------------------------------------------------------------

  proj_folder <- "/Volumes/Disk_1/mhw_by_box_NUR_Omon"
  output_folder <- "/Volumes/Disk_1/mhw_year_exceeded_NUR_AUG"
    if(!dir.exists(output_folder)) dir.create(output_folder)
  
  p_files <- dir(proj_folder, full.names = TRUE, pattern = "Omon_")
    
  

# Set up the functions ---------------------------------------------------------

  
    get_first_exceedance <- function(f, # a netCDF of projected MHWs
                                     obs_file = "/Volumes/Disk_1/OISST_mhw_by_box/Omon_mhw_OISST_1982-2026_to_end_sept.nc",  # a netCDF of observed MHWs; 
                                     m = "2026-09", # a month as character in the format "yyyy-mm"
                                     o_folder = output_folder
                                     ) {
      r <- terra::rast(obs_file)
      months <- terra::time(r) %>%
        as.character() %>%
        stringr::str_sub(1, 7)
      obs_mhw <- r[[months == m]]

      prj_mhw <- terra::rast(f)
      
      yrs <- prj_mhw %>%
        time() %>%
        str_sub(1, 4) %>%
        as.numeric()

      diff_mhw <-  prj_mhw - obs_mhw

      d_rast <- terra::ifel(diff_mhw > 0, 1, NA)
      
      first_non_na_index <- function(x) {
        idx <- which(!is.na(x))
        if (length(idx) > 0) {
          return(idx[1])
        } else {
          return(NA_integer_)
        }
      }
      
      ind_rast <- app(d_rast, 
          fun = first_non_na_index)
      
      yr_rast <- subst(ind_rast, from = 1:length(yrs), to = yrs)

      out_file <- file.path(o_folder, basename(f) %>%
                    str_split_i("mhw_Omon_", 2) %>%
                    str_split_i("_r1", 1) %>%
                    str_c("_year_exceeded.nc"))

      writeCDF(
        yr_rast,
        filename = out_file,
        varname = "year_exceeded",
        longname = "Year when projected cumulative monthly MHW intensity exceeds observed",
        unit = "year",
        overwrite = TRUE
      )
      
    }  
    
  walk(p_files, get_first_exceedance)
  
 