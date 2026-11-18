# MHW Fig 2: Plot results 0.25 deg
	# Written by Dave Schoeman (david.schoeman@gmail.com)
		# October 2026


# Attach package libraries -----------------------------------------------------

  pacman::p_load(
    tidyverse,
    terra,
    furrr,
    sf,
    tictoc,
    tidyterra,
    rnaturalearth,
    patchwork
    )


# Folders and files ------------------------------------------------------------

  proj_folder <- "/Volumes/Disk_1/mhw_year_exceeded_NUR_SEPT"
 
  files <- dir(proj_folder, full.names = TRUE)
  

# Set up the functions ---------------------------------------------------------
  
  get_median <- function(s) {
    s_files <- files %>% 
      str_subset(s)
    
    r <- rast(s_files) %>% 
      subst(NA, 2105) %>% 
      median()
    names(r) <- s
    return(r)
  }
  
  get_minimum <- function(s) {
    s_files <- files %>% 
      str_subset(s)
    
    r <- rast(s_files) %>% 
      subst(NA, 2105) %>% 
      min()
    names(r) <- s
    return(r)
  }
  
  scenarios <- c("ssp126", "ssp245", "ssp370", "ssp585")
  
  r_med <- map(scenarios, get_median) %>% 
    rast()
  
  # r_min <- map(scenarios, get_minimum) %>% 
  #   rast()
  # 
  mat <- matrix(c(
    1980, 2026, 1,
    2026, 2050, 2,
    2050, 2075, 3,
    2075, 2085, 4,
    2085, 2095, 5,
    2095, 2100, 6,
    2100, 2110, 7
  ),
  ncol = 3, byrow = TRUE)
  
  
# Plot --------------------------------------------------------------------
  
  world_poly <- ne_countries(scale = "medium", returnclass = "sf")
  mhw_poly <- read_rds("objects/mhw_poly.rds")
  
  plot_layer <- function(l,ssp) {
    ggplot() +
      geom_spatraster(data = classify(r_med[[l]], mat, include.lowest = TRUE, right = FALSE) %>% as.factor()) +
      geom_sf(data = mhw_poly, colour = "red", fill = NA, linewidth = .55) +
      geom_sf(data = world_poly, fill = "grey80", color = NA) +
      scale_fill_viridis_d(na.value = NA,
                           labels = c("≤ 2026",
                                      "2026–2050",
                                      "2050–2075",
                                      "2075–2085",
                                      "2085–2095",
                                      "2095–2100",
                                      ">2100")) + 
      theme_minimal() +
      coord_sf(
       xlim = c(-125, -105),
        ylim = c(15, 35),
        expand = FALSE
      ) +
      labs(fill = str_wrap("Decade that cumulative monthly MHW intensity for September 2026 is projected to be attained", 15),
           title = ssp) +
      theme(
        plot.title = element_text(
          face = "bold",
          hjust = 0.5   
        )
      )
    }
  
  p1 <- plot_layer(1,"SSP1–2.6")
  p2 <- plot_layer(2,"SSP2–4.5")
  p3 <- plot_layer(3,"SSP3–7.0")
  p4 <- plot_layer(4,"SSP5–8.5")
  
  (
    (p1 + p2) / (p3 + p4) +
      plot_layout(guides = "collect")
  ) + plot_annotation(tag_levels = "a")
  ggsave("figures/fig2.pdf",
         device = "pdf",
         width = 8,
         height = 8)
  

# Proportions of values per scenario ---------------------------------------
  
  r <- r_med %>%
    crop(mhw_poly) %>% 
    mask(mhw_poly)  %>% 
    project("EPSG:32612") %>%  # Using UTM for equal area
    classify(mat, include.lowest = TRUE, right = FALSE)
  
  TableS3 <- map_dfr(1:nlyr(r), function(x) {
    r[[x]] %>% 
      values() %>%
      na.omit() %>%  
      table() %>% 
      prop.table() %>% 
      round(3)
  }) %>% 
    data.frame() %>% 
    mutate(scenario = scenarios) %>% 
    relocate(scenario) %>% 
    dplyr::rename("`2050-2075`" = 2,
                  "`2075-2085`" = 3,
                  "`2085-2095`" = 4,
                  "`2095-2100`" = 5,
                  "`>2100`" = 6)
    write.csv(TableS3, "output/TableS3.csv", row.names = FALSE)
  
  