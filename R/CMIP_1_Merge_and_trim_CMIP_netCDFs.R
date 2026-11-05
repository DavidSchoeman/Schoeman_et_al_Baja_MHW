# CMIP Step 1: Merging the Raw CMIP6 data (projections and historical)
	# Written by Dave Schoeman (david.schoeman@gmail.com)
		# March 2022; modified October 2023, September 2026

  # We will trim times to the period 1982-2100 because this has been my standard.
  # Assumes that you have ONLY historical data and ssp projections; if you have more complex scenarios, you will need to edit the code below "# Ignore any files that don't conform to our start and end years"

# Packages ---------------------------------------------------------------------

	pacman::p_load(
	  tidyverse,
	  terra,
	  furrr
	  )
  source("R/Helpers.R")


# Folders and other parameters to set ------------------------------------------

  input_folder <- "/Volumes/Giga_Disk/CMIP_Raw"
  output_folder <- "/Volumes/Giant_1/CMIP_tos_Oday_merged"
    if(!dir.exists(output_folder)) dir.create(output_folder)
  w <- parallel::detectCores()-4  # Number of workers (parallel processes) to use
  hist_year_start <- 1982 # Start of historical
  hist_year_end <- 2014 # End of CMIP6 historical
  ssp_year_start <- 2015 # Standard for CMIP6
  ssp_year_end <- 2100 # Most models end here...alter if you are working with longer series



# ESMs and scenarios -----------------------------------------------------------

  # Here I used only ESMs that looked OK after I plotted annual time series for Alice's VoCC acceleration analysis
    models <- c("ACCESS-CM2", 
              "ACCESS-ESM1-5", 
              "BCC-CSM2-MR", 
              "CanESM5", 
              "CESM2-WACCM", 
              "CMCC-ESM2", 
              "GFDL-ESM4",
              "IPSL-CM6A-LR",
              "MIROC6",
              "MPI-ESM1-2-HR",
              "MRI-ESM2-0",
              "NorESM2-LM",
              "NorESM2-MM")
  # Just the main tier-1 scenarios
    scenarios <- c("ssp126",
              "ssp245",
              "ssp370",
              "ssp585",
              "historical")
  
    
# Merge by model and scenario --------------------------------------------------

    l <- expand_grid(Scenario = scenarios,
                     Model = models) %>% 
      as.list() %>% 
      unname()
    
    do_merge <- function(s, m) {
      cat(str_c(s, "_", m))
      files <- dir(input_folder, full.names = TRUE) %>% 
        str_subset(str_c("(?=.*", m, "_", ")(?=.*", s, "_", ")")) # in reg exp ".*" means any string of any length, so this formulation requires the variable, model and scenario to be in THAT order in a string, with each followed by "_", but with no other real constraints
    # Ignore any files that don't are out of scope for our start and end years
      if(s == "historical") {
        files <- files %>% 
          basename() %>% 
          get_yr_end() %>% 
          map(~ifelse(as.Date(.x, format = "%Y%m%d") < as.Date(str_c(hist_year_start, "-01-01")), FALSE, TRUE)) %>% 
          unlist() %>% 
          files[.]
        } else {
          files <- files %>% 
            basename() %>% 
            get_yr_start() %>%  # Get year_start from each element of the list
            map(~ifelse(as.Date(.x, format = "%Y%m%d") > as.Date(str_c(ssp_year_end, "-12-31")), FALSE, TRUE)) %>% 
            unlist() %>% 
            files[.]
        }
      if(length(files) > 0) { # Only if there are files to process
          y1 <- files[1] %>% 
            get_yr_start
          y2 <- files[length(files)] %>% 
            get_yr_end()
          var_freq <- files[1] %>%
            basename() %>% 
            str_split_i(str_c("_", m), 1)
          out_file <- file.path(output_folder, 
                                str_c(var_freq, "_", m, "_", s,
                                      "_r1i1p1f1_merged_", y1, "-",y2, ".nc"))
          if(!file.exists(out_file)) {
          cdo_code <- str_c("cdo -L -mergetime -selname,'tos' ", str_c(files, collapse = " "), " ", out_file)
            system(cdo_code)
            }
        }
      }
    plan(multisession, workers = w)
      future_pwalk(l, do_merge)
    plan(sequential)
    
# Goto CMIP_2_Standardise_netCDF_years_and_calendars_and_harmonise_units.R