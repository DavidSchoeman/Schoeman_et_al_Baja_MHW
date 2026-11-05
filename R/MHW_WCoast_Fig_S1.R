# MHW Fig S1: Compute and plot MHW stats for Sept 2026 using OISST (cropped to unfilled mask)
	# Written by Dave Schoeman (david.schoeman@gmail.com)
		# October 2026


# Attach package libraries -----------------------------------------------------

  pacman::p_load(
    tidyverse,
    terra,
    sf,
    tidyterra,
    rnaturalearth,
    patchwork,
    heatwaveR
    )
    source("R/Helpers.R")

# Get the MHW data --------------------------------------------------------

  oisst <- "/Volumes/Disk_1/OISST/OISST_1982-2026_to_end_sept.nc"
  oisst_mhw <- "/Volumes/Disk_1/OISST_mhw_by_box/Oday_mhw_OISST_1982-2026_to_end_sept.nc"
  hmw_poly <- read_rds("objects/mhw_poly.rds")
  oisst_mhw <- rast(oisst_mhw) 

  
# Plot the MHW ------------------------------------------------------------

  dates <- time(rast(oisst)) %>% 
    as.Date()
  mhw_utm <- oisst %>% 
    rast() %>% 
    crop(hmw_poly) %>% 
    mask(hmw_poly) %>% 
    project("EPSG:32612")  # Using UTM for equal area
  
  mhw_dat <- tibble(
    t = dates,
    temp = global(mhw_utm, fun = "mean", na.rm = TRUE) %>% 
      pull(mean)
    )  
    
  ts <- ts2clm(mhw_dat, climatologyPeriod = c("1983-01-01", "2012-12-31"))
  mhw <- detect_event(ts)
  mhw$event %>% 
    dplyr::ungroup() %>%
    dplyr::select(event_no, duration, date_start, date_peak, intensity_max, intensity_cumulative) %>% 
    dplyr::arrange(-intensity_max) %>% 
    head(5) # Maybe should focus just on the August-Sept period?
  
  A <- event_line(mhw, spread = 150, metric = intensity_max,
             start_date = "1982-01-01", end_date = "2026-09-30") +
    labs(y = "Temperature (°C)",
         x  = "Date") +
    theme_nature() +
    theme(legend.position = "inside", legend.position.inside = c(0.14, 0.85),
          legend.direction = "vertical",
          legend.background = element_rect(fill = "white", colour = "grey50"))

# Plot the summary stats --------------------------------------------------

  months <- terra::time(oisst_mhw) %>%
    as.character() %>%
    stringr::str_sub(1, 7)
  obs_mhw <- oisst_mhw[[months == "2026-09"]] %>% 
    crop(hmw_poly) %>% 
    mask(hmw_poly) %>% 
    project("EPSG:32612")  # Using UTM for equal area
  mhw_vals <- obs_mhw %>% 
    values() %>% 
    as.vector() %>% 
    na.omit()
    
  summary(mhw_vals/1000)
    
  B <- mhw_vals %>% 
    tibble() %>% 
    dplyr::rename(mhw_int = 1) %>% 
    mutate(mhw_int = mhw_int/1000) %>% 
    ggplot(aes(x = mhw_int)) +
      # stat_ecdf(geom = "step", linewidth = 1)
      geom_density(fill = "firebrick",
                   colour = "firebrick",
                   alpha = .3) +
    labs(x = "Daily MHW intensity (° days)",
         y = "Density of observations") +
    theme(legend.position = "none") +
    theme_nature()
  B
    

# Stick them together -----------------------------------------------------

  (A | B) + 
    plot_annotation(tag_levels = 'A')
  ggsave("figures/figS1.pdf")
  