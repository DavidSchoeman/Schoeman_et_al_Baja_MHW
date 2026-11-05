# Script to loop through OISST HTML pages and download the data for a set time period
	# Written by Dave Schoeman (david.schoeman@gmail.com)
		# October 2026


# Packages
	library(RCurl)
	library(xml2)
	library(rvest)
	library(tidyverse)
	library(furrr)
	# library(doMC)
		
# Set destination folder
	output_folder <- "/Volumes/Jet_Drive/OISST" # Where processed OISST data live
	temp_folder <- "/Volumes/Jet_Drive/OISST/temp" # Where downloaded OISST data live
	  if(!dir.exists(temp_folder)) dir.create(temp_folder)

# Set base URL
	url <- "https://www.ncei.noaa.gov/data/sea-surface-temperature-optimum-interpolation/v2.1/access/avhrr"

# Get the links that appear there as yyyymm dates
	pg <- read_html(url) # Read the HTML
	sFld <- html_attr(html_nodes(pg, "a"), "href") %>%  # Extract the links
		grep("\\d\\d\\d\\d\\d\\d", ., value = TRUE) # Just the folders with 6 digits (i.e., one per month)
	
# Function to get netCDFs for a month
	get_nc <- function(i) {
	  urli <- str_c(url, "/", i)
	  pgi <- read_html(urli) # Read the HTML
	  sFldi <- html_attr(html_nodes(pgi, "a"), "href") %>%  # Extract the links
	    str_subset(".nc") # Just the netCDFs
	  get_file <- function(j) {
	    download.file(str_c(urli, "/", j), file.path(temp_folder, j))
	    }
	  walk(sFldi, get_file)
	 }

# Download in parallel
  plan(multisession, workers = 10)
  	future_walk(sFld %>% 
           str_subset(str_c(2022:2026 %>% 
                              as.character() %>% 
                              str_c(collapse = "|"))),
         get_nc, 
         .progress = TRUE)
	plan(sequential)
		
# Use CDO to get just sst, then merge and clean up
	
	tmp_folder <- file.path(temp_folder, "tmp")
	  if(!dir.exists(tmp_folder)) dir.create(tmp_folder)
	base_file <- "/Volumes/Jet_Drive/OISST/OISST_1982_2021.nc"
	dwnld_files <- dir(temp_folder, full.names = TRUE,
	                   pattern = ".nc") %>% 
	  str_subset("prelim", negate = TRUE)
	out_file <- "/Volumes/Jet_Drive/OISST/OISST_2022-2026_prelim.nc"
	fix_nc <- function(f) {
	  out_nc <- f %>% 
	    str_replace(dirname(.), tmp_folder)
	  cdo_code <- str_c("cdo -L -selname,sst ",
	                    f, " ", out_nc)
	    system(cdo_code)
	  }
	plan(multisession, workers = 10)
  	future_walk(dwnld_files,
  	            fix_nc, 
  	            .progress = TRUE)
	plan(sequential)
	
# Use CDO to merge into a single netCDF
  	files <- dir(tmp_folder, full.names = TRUE)
  	cdo_code <- str_c("cdo -L -mergetime ", 
  	                  str_c(files, collapse = " " ),
  	                  " ", out_file)
  	  system(cdo_code)
  	  
  # And again
	  cdo_code <- str_c("cdo -L -setctomiss,-999 -remapbil,global_0.25 -mergetime ", base_file, " ", out_file, " /Volumes/Jet_Drive/OISST/OISST_1982-2026_prelim.nc")
	    system(cdo_code)
	  
  # Clean up
	  terminal_code <- str_c("rm -rf ", temp_folder)
	    system(terminal_code)
    terminal_code <- str_c("rm -rf ", out_file)
	    system(terminal_code)
      	  
  	  