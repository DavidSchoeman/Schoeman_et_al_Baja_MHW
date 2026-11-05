# Generic helpers for this project
  # Written by Dave Schoeman (david.schoeman@gmail.com)
    # September 2026


# Get end year from daily netCDF -----------------------------------------------
  get_yr_end <- function(x) {
    x %>% 
      str_remove(".nc") %>% 
      str_sub(-8)
  }

  
# Get start year from daily netCDF ---------------------------------------------
  
  get_yr_start <- function(x) {
    x %>% 
      str_remove(".nc") %>% 
      str_sub(-17) %>% 
      str_split_i("-", 1)
  }
  
  
# Get data from range of years -------------------------------------------------
  
  get_years <- function(nc_file, yr1, yr2, infold, outfold) {
    y1 <- nc_file %>% 
      get_yr_start() %>%
      str_sub(4)	
    y2 <- nc_file %>% 
      get_yr_end() %>%
      str_sub(4)
    if(y1 < yr1 | y2 > yr2) {
      new_name <- nc_file %>% 
        str_split(str_c("_", as.character(y1))) %>%
        map(1) %>% 
        unlist() %>%
        str_c(., "_", yr1, "0101-", yr2, "1231.nc")
      system(str_c("cdo selyear,", yr1, "/", yr2, " ", infold, "/", nc_file, " ", outfold, "/", new_name))
    } else {
      cat("Nothing to do!")
      cat("\n")
    }
  }
  

# Nature plotting theme ---------------------------------------------------

    theme_nature <- function(base_size = 8, base_family = "sans") {
    theme_classic(base_size = base_size, base_family = base_family) +
      theme(
        # Background and panel styling
        plot.background = element_rect(fill = "white", color = NA),
        panel.background = element_rect(fill = "white", color = NA),
        panel.border = element_rect(color = "black", fill = NA, linewidth = 0.5),
        
        # Axis lines and ticks
        axis.line = element_line(color = "black", linewidth = 0.4),
        axis.ticks = element_line(color = "black", linewidth = 0.4),
        axis.ticks.length = unit(3, "pt"),
        
        # Text elements (Nature requires Arial/Helvetica, 5-8pt scale)
        text = element_text(color = "black", family = base_family, size = base_size),
        axis.text = element_text(color = "black", size = base_size),
        axis.title = element_text(color = "black", size = base_size + 2, face = "plain"),
        plot.title = element_text(color = "black", size = base_size + 2, face = "bold", hjust = 0),
        
        # Legend formatting
        legend.background = element_blank(),
        legend.key = element_blank(),
        legend.text = element_text(size = base_size - 1),
        legend.title = element_text(size = base_size, face = "plain"),
        legend.position = "right",
        
        # Facet strip formatting (if applicable)
        strip.background = element_rect(fill = "white", color = "black", linewidth = 0.4),
        strip.text = element_text(color = "black", size = base_size, face = "bold")
      )
  }
  
  