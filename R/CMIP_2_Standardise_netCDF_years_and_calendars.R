# CMIP Step 2: Trim the merged CMIP6 data (projections and historical) to selected periods, fix calendars and harmonise units
	# Written by Dave Schoeman (david.schoeman@gmail.com)
		# March 2022; modified October 2023, September 2026

  # We will trim times to the period 1982-2100
  # Assumes that you have ONLY historical data and ssp projections

# Packages ---------------------------------------------------------------------

  pacman::p_load(
    tidyverse,
    terra,
    furrr,
    ncdf4
  )
  source("R/Helpers.R")


# Folders and other parameters to set ------------------------------------------

  input_folder <- "/Volumes/Giant_1/CMIP_tos_Oday_merged"
  output_folder <- "/Volumes/Giant_2/CMIP_tos_Oday_merged_std"
    if(!dir.exists(output_folder)) dir.create(output_folder)
  w <- parallel::detectCores()-4  # Number of workers (parallel processes) to use
  hist_year_start <- 1982 # Start of historical
  hist_year_end <- 2014 # End of CMIP6 historical
  ssp_year_start <- 2015 # Standard for CMIP6
  ssp_year_end <- 2100 # Most models end here...alter if you are working with longer series
  

# Trim times -------------------------------------------------------------------
  # Projections
		pjs <- dir(input_folder) %>% 
		  str_subset("ssp") # Just the projections
		trim_projections <- function(f) {
		  dt <- get_yr_end(f) %>% 
		    as.Date(format = "%Y%m%d")
		  if(dt > as.Date(str_c(ssp_year_end, "-12-31"))) {
		    get_years(f, ssp_year_start, ssp_year_end, input_folder, input_folder)
		    terminal_code <- str_c("rm ", input_folder, "/", f)
		      system(terminal_code)
		    }
		}
		plan(multisession, workers = w)
		  future_walk(pjs, trim_projections, .progress = TRUE)
		plan(sequential)
		
	# Historical
		pst <- dir(input_folder) %>% 
		  str_subset("historical") # Just the projections
		trim_historical <- function(f) {
		  dt1 <- f %>% 
		    get_yr_start() %>% 
		    as.Date(format = "%Y%m%d")
		  dt2 <- f %>% 
		    get_yr_end() %>% 
		    as.Date(format = "%Y%m%d")
		  if(dt1 < as.Date(paste0(hist_year_start, "-01-01")) | dt2 > as.Date(paste0(hist_year_end, "-12-31"))) {
		    get_years(f, hist_year_start, hist_year_end, input_folder, input_folder)
		    terminal_code <- paste0("rm ", input_folder, "/", f)
		      system(terminal_code)
		  }
		}
		plan(multisession, workers = w)
		  future_walk(pst, trim_historical, .progress = TRUE)
		plan(sequential)


# Fix calendars ----------------------------------------------------------------
	
	fix_cal <- function(f) {
	  yrs <- nc_open(f)	%>% 
	    ncvar_get(., "time") %>% 
	    length(.) %% 365 # Modulo...returns zero if number of days divides by 365 without remainder
	  if(yrs != 0) {
	    cat(str_c(basename(f), " DOES have leap days to be removed"))
	    cat("\n")
	    cdo_code <- str_c("cdo -L -setcalendar,365_day -delete,month=2,day=29 ", f, " ", output_folder, "/", basename(f))
	      system(cdo_code)
	    # system(str_c("rm ", f))
	    # file.rename(str_c(dirname(f), "/tmp_", basename(f)), f)
	  } else {
	    cat(str_c(basename(f), " does not have leap days"))
	    cat("\n")
	    cdo_code <- str_c("cdo setcalendar,365_day ", f, " ", output_folder, "/", basename(f))
        system(cdo_code)
	    # system(str_c("rm ", f))
	    # file.rename(str_c(dirname(f), "/tmp_", basename(f)), f)
	  }
	}	
	netCDFs <- dir(input_folder, full.names = TRUE)
	plan(multisession, workers = w)
	  future_walk(netCDFs, fix_cal, .progress = TRUE)
	plan(sequential)

	
# Goto CMIP_3_Compute_means_for_baseline_period.R
		