# MHW Step 6: Compute and plot MHW for Sept 2026 using OISST (cropped to unfilled mask)
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

  download_folder <- "/Volumes/Disk_1/OISST"
    if(!dir.exists(download_folder)) dir.create(download_folder)
  

# Download the data for the mask -----------------------------------------------
  
  if(!file.exists(file.path(download_folder, "OISST_mask.nc"))) {
    target_date <- "2026-09-30"
    oisst_info <- info(datasetid = "ncdcOisst21Agg_LonPM180", url = "https://coastwatch.pfeg.noaa.gov/erddap/")
    nc <- griddap(
      datasetx = oisst_info,
      url = "https://coastwatch.pfeg.noaa.gov/erddap/",
      time = c(target_date, target_date),
      zlev = c(0, 0),
      latitude = c(8, 72),
      longitude = c(-178.5,-77.25)
    )
    nc_baja <- nc$summary$filename # The name of the downloaded netCDF
    out_file <- file.path(download_folder, "OISST_mask_raw.nc")
    file.copy(nc_baja, out_file)
    rm(nc)

  final_mask <- out_file %>% 
    str_remove("_raw")
  terminal_code <- str_c("rm ", nc_baja)
    system(terminal_code)
  cdo_code <- str_c("cdo -L -expr,'sst  = (sst >= -1e30) ? 1 : sst;' ", out_file, " ", final_mask)
    system(cdo_code)
  }    
    
# Get MHW, mask and plot -------------------------------------------------------
  
  obs_file = "/Volumes/Disk_1/OISST_mhw_by_box/Omon_mhw_OISST_1982-2026_to_end_sept.nc"  # a netCDF of observed MHWs
  m = "2026-09" # the month as character in the format "yyyy-mm"
  final_mask <- rast(file.path(download_folder, "OISST_mask.nc"))
  e <- ext(-125, -105,
           15, 35)

  r <- terra::rast(obs_file)
  months <- terra::time(r) %>%
    as.character() %>%
    stringr::str_sub(1, 7)
  obs_mhw <- r[[months == m]]
  
  mask <- final_mask %>% 
    crop(obs_mhw)
  
  mhw_int <- (obs_mhw * mask) %>% 
    crop(e)
  
  mhw_patches <- ifel(mhw_int > mhw_int %>% 
                   values() %>% 
                   quantile(.95, na.rm = TRUE),
                 1, NA) %>%
    patches()
  mhw_id <- mhw_patches %>% 
    values() %>% 
    table() %>% 
    which.max()
  mhw_poly <- ifel(mhw_patches == mhw_id, 1, NA) %>% 
    as.polygons(aggregate = TRUE) %>% 
    st_as_sf() %>% 
    st_set_crs(4326)
  
  world_poly <- ne_countries(scale = "medium", returnclass = "sf")
  
  mhw <- st_difference(mhw_poly, st_union(world_poly))
  
  sf_polygons <- st_cast(mhw, "POLYGON")
  sf_polygons$area <- st_area(sf_polygons)
  mhw_poly <- sf_polygons %>%
    filter(area == max(area)) %>% 
    summarise(geometry = st_union(geometry))
  
  write_rds(mhw_poly, "objects/mhw_poly.rds")
      
  oisst_plot <- ggplot() +
    geom_spatraster(data = mhw_int/1000) +
    scale_fill_viridis_c() +
    geom_sf(data = mhw_poly, colour = "red", fill = NA, linewidth = .55) +
    geom_sf(data = world_poly) +
    coord_sf(
      xlim = c(-125.0, -105.0), 
      ylim = c(15.0, 35.0),
      expand = FALSE
    ) +
    labs(fill = str_wrap("Cumulative marine heatwave intensity (°C days)", 15))
  oisst_plot
 