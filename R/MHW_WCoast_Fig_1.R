# MHW Fig 1: Compute and plot MHW for Sept 2026 using OISST (cropped to unfilled mask)
	# Written by Dave Schoeman (david.schoeman@gmail.com)
		# October 2026


# Attach package libraries -----------------------------------------------------

  pacman::p_load(
    tidyverse,
    terra,
    sf,
    tidyterra,
    rnaturalearth,
    patchwork
    )


# Plot -------------------------------------------------------------------------

  source("R/MHW_WCoast_5_MUR_SST.R")
  source("R/MHW_WCoast_6_OISST_MHW.R")

  p <- (MUR_plot | oisst_plot) + plot_annotation(tag_levels = "a") &
    theme(
    plot.tag.position = "topleft",
    plot.tag.location = "plot", # Keeps it in the outer margin
    plot.tag = element_text(
      size = 12, 
      face = "bold", 
      hjust = 1.5, # Shifts the tag further to the left (increase value to push further)
      vjust = 0.5  # Fine-tune vertical alignment if needed
    )
  )
  p
  ggsave("figures/fig1.pdf",
         device = "pdf")
