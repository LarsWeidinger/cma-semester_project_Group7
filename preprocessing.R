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

# Open Government Data, OpenDataZurich, "Täglich aktualisierte Meteodaten, seit 1992"
# The following code is provided by the City of Zurich and can be found under this link: https://github.com/opendatazurich/starter-code/blob/main/01_r-markdown/ugz_meteodaten_tagesmittelwerte_141e649c-27de-412d-ba57-7491bc162dd2.Rmd
# all dates are in "Winterzeit (UTC+1)" 

# Identifies requests from this notebook in the OpenDataZurich access logs.
# Picked up by curl-based readers (readr, arrow) via base R's HTTPUserAgent option.
options(HTTPUserAgent = "OpenDataZurich-StarterCode-Notebook/1.0 (lang=r; +https://github.com/opendatazurich/starter-code)")

# Load the daily weather data
url <- "https://data.stadt-zuerich.ch/dataset/ugz_meteodaten_tagesmittelwerte/download/ugz_ogd_meteo_d1_2026.csv"

if (str_detect(url, ".csv")) {
  weather_daily_df <- readr::read_csv(url)
} else if (str_detect(url, ".parquet")) {
  weather_daily_df <- arrow::read_parquet(url)
} else {
  print("File format not recognised!")
}

# Open Government Data, OpenDataZurich, "Stündlich aktualisierte Meteodaten, seit 1992"
# The following code is provided by the City of Zurich and can be found under this link: https://github.com/opendatazurich/starter-code/blob/main/01_r-markdown/ugz_meteodaten_stundenmittelwerte_f9aa1373-404f-443b-b623-03ff02d2d0b7.Rmd
# all dates are in "Winterzeit (UTC+1)" 
options(HTTPUserAgent = "OpenDataZurich-StarterCode-Notebook/1.0 (lang=r; +https://github.com/opendatazurich/starter-code)")

url2 <- "https://data.stadt-zuerich.ch/dataset/ugz_meteodaten_stundenmittelwerte/download/ugz_ogd_meteo_h1_2026.csv"

if (str_detect(url2, ".csv")) {
  weather_hourly_df <- readr::read_csv(url2)
} else if (str_detect(url2, ".parquet")) {
  weather_hourly_df <- arrow::read_parquet(url2)
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

# Open Government Data, OpenDataZurich, "Stadtklima Zürich - Standorte Messstationen Messnetz meteoblue"
# The following code is provided by the City of Zurich and can be found under this link: https://github.com/opendatazurich/starter-code/blob/main/01_r-markdown/ugz_stadtklima_zuerich_messorte_messnetz_meteoblue_96e7a64b-1f93-4fc6-a9ef-44adfbb14ed8.Rmd
# all dates are in "Winterzeit (UTC+1)" 

# Identifies requests from this notebook in the OpenDataZurich access logs.
# Picked up by curl-based readers (readr, arrow) via base R's HTTPUserAgent option.
options(HTTPUserAgent = "OpenDataZurich-StarterCode-Notebook/1.0 (lang=r; +https://github.com/opendatazurich/starter-code)")

# Load the locations of the Messstationen
url3 <- "https://data.stadt-zuerich.ch/dataset/ugz_stadtklima_zuerich_messorte_messnetz_meteoblue/download/ugz_stadtklima_zuerich_messorte_messnetz_meteoblue.csv"

if (str_detect(url3, ".csv")) {
  meteoblue_stations <- readr::read_csv(url3)
} else if (str_detect(url3, ".parquet")) {
  meteoblue_stations <- arrow::read_parquet(url3)
} else {
  print("File format not recognised!")
}

# Open Government Data, OpenDataZurich, "Stadtklima Zürich - bereinigte Temperaturmessungen Messnetz meteoblue"
# The following code is provided by the City of Zurich and can be found under this link: https://github.com/opendatazurich/starter-code/blob/main/01_r-markdown/ugz_stadtklima_zuerich_temperaturmessungen_messnetz_meteoblue_e8e7bfc7-d7c6-4ff2-aeb0-35b15a90b959.Rmd
# all dates are in "Winterzeit (UTC+1)" 

# Identifies requests from this notebook in the OpenDataZurich access logs.
# Picked up by curl-based readers (readr, arrow) via base R's HTTPUserAgent option.
options(HTTPUserAgent = "OpenDataZurich-StarterCode-Notebook/1.0 (lang=r; +https://github.com/opendatazurich/starter-code)")

# Load the locations of the Messstationen
url4 <- "https://data.stadt-zuerich.ch/dataset/ugz_stadtklima_zuerich_temperaturmessungen_messnetz_meteoblue/download/ugz_stadtklima_zuerich_temperaturmessungen_messnetz_meteoblue_2026.csv"

if (str_detect(url4, ".csv")) {
  meteoblue_weather_data <- readr::read_csv(url4)
} else if (str_detect(url4, ".parquet")) {
  meteoblue_weather_data <- arrow::read_parquet(url4)
} else {
  print("File format not recognised!")
}

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
