library(pacman)

# Load and if not found in the library will attempt to install the package
pacman::p_load(here,
               sf,
               readr,
               tmap,
               dplyr,
               ggplot2,
               tidyr,
               jsonlite,
               lubridate, # temporal import from JSON file
               tidyverse,
               install = TRUE)

# set CRS
crs_lv95  <- 2056
crs_wgs84 <- 4326

# Open Government Data, OpenDataZurich, *Täglich aktualisierte Meteodaten, seit 1992"
# The following code is provided by the City of Zurich and can be found under this link: https://github.com/opendatazurich/starter-code/blob/main/01_r-markdown/ugz_meteodaten_tagesmittelwerte_141e649c-27de-412d-ba57-7491bc162dd2.Rmd
# all dates are in "Winterzeit (UTC+1)" 

# Identifies requests from this notebook in the OpenDataZurich access logs.
# Picked up by curl-based readers (readr, arrow) via base R's HTTPUserAgent option.
options(HTTPUserAgent = "OpenDataZurich-StarterCode-Notebook/1.0 (lang=r; +https://github.com/opendatazurich/starter-code)")

# Load the data
url <- "https://data.stadt-zuerich.ch/dataset/ugz_meteodaten_tagesmittelwerte/download/ugz_ogd_meteo_d1_2026.csv"

if (str_detect(url, ".csv")) {
  weather_daily_df <- readr::read_csv(url)
} else if (str_detect(url, ".parquet")) {
  weather_daily_df <- arrow::read_parquet(url)
} else {
  print("File format not recognised!")
}

# filter weather_daily_df to our timeframe --> tbd

# import weather station information from the metadata JSON file provided by the city of Zurich
weather_stations <- fromJSON("data/weather_stations_metadata.json")

weather_stations_sf <-  bind_rows(weather_stations)|> 
  filter(!is.na(Koordinaten_LV95_X)) |>
  select(ID, Koordinaten_LV95_X, Koordinaten_LV95_Y) |>
  st_as_sf(coords = c("Koordinaten_LV95_X", "Koordinaten_LV95_Y"),
  crs = crs_lv95)

# city boundary layer
stadtgrenze <- read_sf("data/Gemeindegrenzen_OGD/Gemeindegrenzen_-OGD.gpkg", layer = "up_gemeinden_f") |> # take the polygon
  filter(gemeindename == "Zürich") |> # of the city of Zurich
  select(geom)

# import Google Timeline data
google_timeline <- fromJSON("data/Google_timeline.json", simplifyVector = FALSE) # to keep the nested structure

segments <- google_timeline$semanticSegments

path_segments <- segments[sapply(segments, function(x) !is.null(x$timelinePath))]

google_timeline_df <- lapply(path_segments, function(seg) {
  do.call(rbind, lapply(seg$timelinePath, function(p) {
    data.frame(
      time = p$time,
      point = p$point
    )
  }))
}) |> bind_rows()

google_timeline_df <- google_timeline_df |>
  separate(point, into = c("lat", "lon"), sep = ",") |>
  mutate(
    lat = as.numeric(gsub("°", "", lat)),
    lon = as.numeric(gsub("°", "", lon)),
    time = ymd_hms(time)
  )

# convert to a spatial object
google_timeline_sf <- st_as_sf(google_timeline_df, coords = c("lon", "lat"), crs = crs_wgs84)

# convert to local CRS
google_timeline_sf_lv95 <- st_transform(google_timeline_sf, crs = crs_lv95)
