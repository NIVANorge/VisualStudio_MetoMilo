# Load necessary libraries
library(dplyr)
library(sf)
library(terra)

source("function_rasterise_metomilo.R")

# Set locale
Sys.setlocale("LC_ALL", "en_US.UTF-8")

# Get user name
user <- Sys.getenv("USERNAME")
local_folder <- paste0("C:/Users/FEG/Downloads/TEST_Metomilo_Local/")
folder_base <- "C:/Users/FEG/NIVA/METOMILO - Prosjektgruppe - METOMILO - Prosjektgruppe - METOMILO/AP1 Kartlegge samlet påvirkning av menneskelige aktiviteter/Data collection/"
folder_area <- paste0(folder_base, "Focus areas/grid_v3/raster/")
folder_output_csv <- paste0(folder_base, "../Analyses/input_data/ecosystem_components/")
basefolder_od <- "C:/Users/FEG/OneDrive - NIVA/METOMILO_OneDrive/"

# Define the path to the shapefiles
file_path_gdb_salten <- "C:/Users/FEG/OneDrive - NIVA/METOMILO_OneDrive/GIS Data/Ecological components data/EUSeaMap_Europe_2023/EUSeaMap_2023_Salten/EUSeaMap_2023_Salten.shp"
#file_path_gdb_sar_hab <- "C:/Users/FEG/OneDrive - NIVA/METOMILO_OneDrive/GIS Data/Ecological components data/21. Marine grunnkart - Sårbare habitater/SaltvannssjobunntyperPredikert_FGDB.gdb"

# Load the 100m study area raster
r_area <- terra::rast(paste0(basefolder_od, "/Focus areas/grid_mask/Raster/Nord-Salten_1108_08.tif"))

# Load EUSeaMap_2023
db_layers <- sf::st_layers(file_path_gdb_salten)$name
shp_sea_map_23 <- purrr::map(
  db_layers, sf::st_read, dsn = file_path_gdb_salten, quiet = TRUE
) %>% 
  bind_rows() %>% 
  sf::st_make_valid()

# List all categories present in the column "All2019DL2"
categories <- shp_sea_map_23 %>%
  distinct(All2019DL2) %>%
  pull(All2019DL2) %>%
  as.character()

cat("Categories in 'All2019DL2':\n")
cat(paste(categories, collapse = "\n"))

# List of species to rasterize
species_list <- shp_sea_map_23 %>%
  filter(All2019DL2 %in% c("Upper bathyal seabed",
 "Offshore circalittoral seabed",
 "ME1: Upper bathyal rock",
 "Infralittoral seabed",
 "Circalittoral seabed",
 "MD1: Offshore circalittoral rock",
 "MB1: Infralittoral rock",
 "MC1: Circalittoral rock",
 "MD3: Offshore circalittoral coarse sediment",
 "MB3: Infralittoral coarse sediment",
 "ME6: Upper bathyal mud",
 "MD6: Offshore circalittoral mud",
 "MB6: Infralittoral mud")) %>%
           distinct(All2019DL2) %>%
           pull(All2019DL2) %>%
           as.character()


# Function to sanitize file names
sanitize_filename <- function(name) {
  gsub("[^[:alnum:]_]", "_", name)
}

# List of species to rasterize
for (i in seq_along(species_list)) {
    # Select current species
    habitat <- species_list[i]
    cat(paste0(habitat, ": "))

    # Filter shape for selected species
    shp <- shp_sea_map_23 %>% filter(All2019DL2 == habitat)

    # Check if shapefile data is empty
    if (nrow(shp) == 0) {
        cat("No data found for habitat: ", habitat, "\n")
        next
    }

    # Check if shapefile data falls within the raster extent
    if (is.null(terra::intersect(terra::ext(r_area), terra::ext(shp)))) {
        cat("Shapefile data falls outside the raster extent for habitat: ", habitat, "\n")
        next
    }
    
  # Define output CSV file name
  file_out <- paste0(local_folder, "14.10_", sanitize_filename(habitat), "_Salten.csv")
  

    # Rasterize and save CSV
    df <- rasterise_mm(r_area, shp, variable = "All2019DL2", return_df = TRUE, filecsv = file_out)
    cat(paste0(nrow(df), "\n"))

    # Save the data to a CSV file
    write.csv(df, file_out)
}
