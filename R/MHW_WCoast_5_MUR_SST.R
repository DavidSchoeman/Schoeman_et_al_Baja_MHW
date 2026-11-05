# MHW Step 5: Download MUR SST for Baja compute monthly mean for Sept 26 and plot
	# Written by Dave Schoeman (david.schoeman@gmail.com)
		# October 2026


# Attach package libraries -----------------------------------------------------

  pacman::p_load(
    tidyverse,
    terra,
    sf,
    tidyterra,
    rnaturalearth,
    rerddap
    )


# Folders ----------------------------------------------------------------------

  download_folder <- "/Volumes/Disk_1/MUR_SST_Raw"
    if(!dir.exists(download_folder)) dir.create(download_folder)
  

# Download the data ------------------------------------------------------------
  
  out_file <- file.path(download_folder, "tos_Oday_Baja_MUR_20260901-20260930.nc")
  if(!file.exists(out_file)) {
    sst_info <- info('jplMURSST41', url = "https://coastwatch.pfeg.noaa.gov/erddap/")
    nc <- griddap(sst_info, 
                  latitude = c(15.0, 35.0), 
                  longitude = c(-130.0, -105.0), 
                  time = c("2026-09-01", "2026-09-30"), 
                  fields = "analysed_sst")
    nc_baja <- nc$summary$filename # The name of the downloaded netCDF
    file.copy(nc_baja, out_file)
    rm(nc)
    terminal_code <- str_c("rm ", nc_baja)
      system(terminal_code)
    }
    
# Compute mean and plot --------------------------------------------------------
  
  mon_file <- out_file %>% 
      str_replace("_Oday_", "_Omon_")
  if(!file.exists(mon_file)) {
    cdo_code <- str_c("cdo -L -timmean ", 
                      out_file, " ", 
                      mon_file)
      system(cdo_code)
    }
  
  world_poly <- ne_countries(scale = "medium", returnclass = "sf")
  mhw_poly <- read_rds("objects/mhw_poly.rds")
      
  MUR_plot <- ggplot() +
    geom_spatraster(data = rast(mon_file)) +
    scale_fill_viridis_c() +
    geom_sf(data = mhw_poly, colour = "red", fill = NA, linewidth = .55) +
    geom_sf(data = world_poly) +
    coord_sf(
      xlim = c(-125.0, -105.0), 
      ylim = c(15.0, 35.0),
      expand = FALSE
    ) +
    labs(fill = str_wrap("Mean sea surface temperature (°C)", 15))
  MUR_plot  
 