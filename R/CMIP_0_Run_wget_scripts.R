# CMIP Step 0: Download of CMIP6 data
  # Written by Dave S
    # March/April 2022
    # Modified December 2022

# Packages ---------------------------------------------------------------------

  source("R/Helpers.R")


# Folders and other parameters to set ------------------------------------------
  output_folder <- "/Volumes/Giga_Disk/CMIP_Raw"
    if(!dir.exists(output_folder)) dir.create(output_folder)
  wget_folder <- "/Users/davidschoeman/Github/Project/wget"
  pth <- getwd()
  w <- parallel::detectCores()-4  # Number of workers (parallel processes) to use


# Purrr the files via terminal -------------------------------------------------

  # Purrr function
    wget_files <-  function(script) {
        setwd(output_folder)
        system(str_c("bash ", script, " -s")) # Change the path to where you want the data stored, then run wget from there
        setwd(pth)
        }

  files <- dir(wget_folder, pattern = "wget", full.names = TRUE)

  plan(multisession, workers = w)
    future_walk(files, wget_files)
  plan(sequential)

# Goto CMIP_1_Merge_and_trim_CMIP_netCDFs.R

