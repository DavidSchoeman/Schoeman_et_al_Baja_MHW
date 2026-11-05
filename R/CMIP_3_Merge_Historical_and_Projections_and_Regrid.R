# CMIP Step 3: Merge historical runs and projections, then regrid to 0.25º and fill to coast
  # Written by Dave S
    # July 2026; Updated September 2026


# Packages ---------------------------------------------------------------------

  pacman::p_load(
    tidyverse,
    terra,
    furrr,
    ncdf4
  )
  source("R/Helpers.R")


# Merge historical and projected, and crop to 1982–2100 and regrid -------------

  input_folder <- "/Volumes/Giant_2/CMIP_tos_Oday_merged_std"
  output_folder <- "/Volumes/Giant_2/CMIP_tos_Oday_merged_std_regridded"
    if(!dir.exists(output_folder)) dir.create(output_folder)
  
  files <- dir(input_folder, full.names = TRUE)
  hist_files <- files %>% 
    str_subset("historical")
  
  models <- files %>% 
    basename() %>% 
    str_split_i("_", 3) %>% 
    unique()
  
  scenarios <- files %>% 
    basename() %>% 
    str_split_i("_", 4) %>% 
    unique() %>% 
    str_subset("historical", negate = TRUE)
  
  combos <- expand_grid(Model = models, Scenario = scenarios)
  
  mrg <- function(m, s) {
    f_files <- files %>% 
      str_subset(m) %>% 
      str_subset(s)
    if(length(f_files) > 0) {
        h_files <- hist_files %>% 
        str_subset(m)
      merge_files <- c(h_files, f_files)
      y_strt1 <- merge_files[1] %>% 
        basename() %>%
        str_split_i("merged_", 2) %>% 
        str_sub(1, 8)
      y_end1 <- merge_files[1] %>% 
        basename() %>%
        str_split_i("merged_", 2) %>% 
        str_remove(".nc") %>% 
        str_sub(-8)
      y_end <- merge_files[length(merge_files)] %>% 
        basename() %>%
        str_split_i("merged_", 2) %>% 
        str_remove(".nc") %>% 
        str_sub(-8)
      out_file <- merge_files[1] %>% 
        str_replace(input_folder, output_folder) %>% 
        str_replace(str_remove_all(y_end1, "-"), y_end) %>% 
        str_replace("_historical_", str_c("_", s, "_")) %>% 
        str_replace(str_c("_merged_",y_strt1), str_c("_rgdw_", y_strt1))
      if(!file.exists(out_file)) {
        cdo_code <- str_c("cdo -L -setmisstodis -sellonlatbox,-180,180,-90,90 -remapbil,global_0.25 -mergetime ",
                           str_c(merge_files, collapse = " "),
                           " ", out_file)
        system(cdo_code)
        }
      }
  }
  
  plan(multisession, workers = 8) # Reading at 10-48 mbps writing at 39-66 mbps, so can likely use 8 cores without saturating the bandwidth
    future_walk2(combos$Model, combos$Scenario, mrg,
                 .progress = TRUE)
  plan(sequential)
