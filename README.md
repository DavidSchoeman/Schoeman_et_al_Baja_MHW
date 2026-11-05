# Processing ESM data from CMIP6 and computing MHW intensity

## Initial warnings
This code is provided "as is". It runs start-to-end on my machine, but I cannot guarantee the same for others, as I have not tested it in an external environment.
Much of the code requires system calls to `CDO` (Climate Data Operators), described here: https://code.mpimet.mpg.de/projects/cdo/wiki. These system calls work well on MacOS, *but I have not tested them in the Windows environment*.
I have done my best to avoid use of `R` packages nearing deprecation, but  this might need final checks.
*NOTE* This code is written for daily SST (`tos_Oday`). Make your own modifications if you want other variables and frequencies.


## Dependencies
The user will need to install `CDO` (Climate Data Operators: https://code.mpimet.mpg.de/projects/cdo/wiki), `NCO` (netCDF Operarors: https://nco.sourceforge.net) and `wget` (https://www.gnu.org/software/wget) on their machine for this code to work. 

## Sequence of scripts
### Utilities

- `Helpers.R`: A brief compilation of utility functions that are used sporadically across several code chunks. This file is sourced at the start of each code chunk that might use these functions.


### Process ESM outputs

- `CMIP_0_Run_wget_scripts.R`: Once `wget` scripts have been downloaded from ESGF (https://aims2.llnl.gov/search) and saved in a given folder, this script will reach out to ESGF to download the corresponding netCDFs and place them in a specified folder.

- `CMIP_1_Merge_and_trim_CMIP_netCDFs.R`: Takes the downloaded netCDFs, merges them into historical and projected periods for each variable, discarding any files that fall outside of a specified period

- `CMIP_2_Standardise_netCDF_years_and_calendars.R`: Trims the merged CMIP6 netCDFs (projections and historical) to exact periods specified, standardises calendars (after deleting leap days for daily data).

- `CMIP_3_Merge_Historical_and_Projections_and_Regrid.R`: For each model-variable combination, merge the historical and projected data, then regrid (bilinear interpolation) to 0.25º, filling missing cells using inverse distance-weighted means


### Get and process OISST data

- `OISST_1_Get_OISST.R`: Download OISST daily files and combine them into a single netCDF

### Compute marine heatwave intensity for main analysis and plot

- `MHW_1_WCoast_Run_MHW_scripts_automatically.R`: For each global netCDF, crop to the study area, then compute MHW intensity

- `MHW_WCoast_2_Run_Get_monthly_sums.R`: Sums daily MHW time series for the US West coast by month 

- `MHW_WCoast_3_Run_MHW_scripts_OISST.R`: Get MHW time series for the US West coast from OISST

- `MHW_WCoast_4_Compare_OISST_vs_projections.R`: Compare monthly projections with OISST cumulative MHW intensity for September 2026 and search for year of exceedance

- `MHW_WCoast_5_MUR_SST.R`: Download MUR SST and make a plot for Fig.1

- `MHW_WCoast_6_OISST_MHW.R`: Build a plot of MHW intensity from OISST for Fig.1

- `MHW_WCoast_Fig_1.R`: Build and output Fig.1

- `MHW_WCoast_Fig_2.R`: Build and output Fig.2

### Compute marine heatwave intensity for sensitivity analysis and plot

- `MHW_1deg_WCoast_1_Run_MHW_scripts_automatically.R`: For each global netCDF at 1-deg resolution, crop to the study area, then compute MHW intensity

- `MHW_1deg_WCoast_2_Run_Get_monthly_sums.R`: Sums daily MHW time series for the US West coast by month

- `MHW_1deg_WCoast_3_Compare_OISST_vs_projections.R`: Compare monthly projections with OISST cumulative MHW intensity for September 2026 and search for year of exceedance

### Stand-alone helper functions

- `MHW_FUN_Compute_mhw_intensity_WCoast.R`: A stand-alone helper function for computing MHW intensity


## Data used in testing
### ESMs used in testing
  Selected monthly data (tas, tasmax, tasmin, pr) from ESGF for 11 ESMs from the slection generally considered not-too-hot:
  
    - ACCESS-CM2
    
    - ACCESS-ESM1-5
    
    - CanESM5
    
    - CESM2-WACCM
    
    - CMCC-ESM2
    
    - GFDL-ESM4
    
    - IPSL-CM6A-LR
    
    - MIROC
    
    - MPI-ESM1-2-HR
    
    - MRI-ESM2-0
    
    - NorESM2-LM
    
    - NorESM2-MM

### Scenarios
  For each ESM, I downloaded historical and SSP1-2.6, SSP2-4.5, SSP3-7.0 and SSP5-8.5 data

### Variables
  `tos_Oday`...any other format will require some tinkering

## Caveats and warnings

Note that the folders/directories named in this code pertain to my own setup, and these paths will need to be edited to suit the user's own machine.

Note that this code is intended for use with CMIP6 netCDFs downloaded from the ESGF that have only one vertical layer. I have not tested it on multi-layer data — it might well work, but it might not.

The code works with daily data. To work with other frequencies, some user-driven data munging will be required.

Note that the warning during ensembling `cdo    ensmedian (Warning): Input parameters have different levels!` is just a warning. The ensemble is produced, anyway, discarding levels, as needed.

Raw and processed data files (mainly in netCDF format) require significant storage space (especially if daily data are used). Some routines are also memory intensive, so adjustments to arguments might be needed in the calls to set up parallel processes. Finally, depending on processor speed and number of ESMs/scenarios considered, this workflow can take >1 week to run (daily data). Do not attempt the workflow before provisioning your machine accordingly.
