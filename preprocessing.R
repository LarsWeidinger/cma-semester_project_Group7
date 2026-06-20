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

# For our weather data we used a dataset by the city of Zurich that provides aggregated weather data (temperature [°C] and rain duration [min]) per day. The dataset is updated every day and we import the whole year and later only use the information that corresponds to our tracking data. 

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

# IMPORTANT: this step was added in manually after we realised that the station with the locationID "F2" had invalid coordinates in CH1903+/LV95 (268019381,125276801). 
# We therefore wrote an Email to Open Data Zürich and let them know about this error. As a quick fix we decided on simply filtering out entries that had more than 7 digits in the CH1903+/LV95 coordinate columns. 
# Since we access the stations via API, this short code snippet will become obsolete as soon as the have fixed the coordinates (Edit: they fixed it on 17.06.2026)
meteoblue_stations  <- meteoblue_stations |> 
  filter(
    nchar(as.character(EKoord)) <= 7,
    nchar(as.character(NKoord)) <= 7
  )

# Open Government Data, OpenDataZurich, "Stadtklima Zürich - bereinigte Temperaturmessungen Messnetz meteoblue"
# The following code is provided by the City of Zurich and can be found under this link: https://github.com/opendatazurich/starter-code/blob/main/01_r-markdown/ugz_stadtklima_zuerich_temperaturmessungen_messnetz_meteoblue_e8e7bfc7-d7c6-4ff2-aeb0-35b15a90b959.Rmd
# all dates are in UTC+0" 

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

# add 1h to make it comparable to the rest of the data which is in UTC+1
meteoblue_weather_data <- meteoblue_weather_data |>
  mutate(
    timestamp = timestamp + lubridate::hours(1)
  )

# city boundary layer
stadtgrenze <- read_sf("data/Gemeindegrenzen_OGD/Gemeindegrenzen_-OGD.gpkg", layer = "up_gemeinden_f") |> # take the polygon
  filter(gemeindename == "Zürich") |> # of the city of Zurich
  select(geom)

# To answer our RQ, we tracked ourselves with two different tracking tools. We used ArcGIS Earth, which saves a GPS fix every few seconds, independently of movement or non-movement, and saves it to a KML file to answer RQ I and II. We also used Google timeline, which mostly only measures your stop locations and saves it to a JSON file to answer RQ III and IV. 
# We let the Google timeline run in the background of our smartphone from 08.03.2026 until 26.04.2026. Since we had to manually start and stop the ArcGIS Earth tracking, we only generated 42 tracks of different length between 13.03.2026 and 25.04.2026. 

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

# import ArcGIS Earth trajectories
files <- list.files(
  "data/ArcGISEarth_Tracks",
  pattern = "\\.kmz$",
  full.names = TRUE
)

## read each trajectory including exact time
read_kmz_track <- function(f) {
  
  td <- tempfile()
  dir.create(td)
  
  unzip(f, exdir = td)
  
  kml <- file.path(td, "doc.kml")
  
  if (!file.exists(kml)) {
    unlink(td, recursive = TRUE)
    stop("No doc.kml in: ", f)
  }
  
  kml_text <- readLines(kml, warn = FALSE)
  
  when_vec <- stringr::str_extract(
    grep("<when>", kml_text, value = TRUE),
    "(?<=<when>).*?(?=</when>)"
  )
  
  coord_vec <- stringr::str_extract(
    grep("<gx:coord>", kml_text, value = TRUE),
    "(?<=<gx:coord>).*?(?=</gx:coord>)"
  )
  
  track_df <- tibble(
    timestamp = when_vec,
    coord = coord_vec
  ) |>
    tidyr::separate(
      coord,
      into = c("lon", "lat", "altitude"),
      sep = " "
    ) |>
    mutate(
      lon = as.numeric(lon),
      lat = as.numeric(lat),
      altitude = as.numeric(altitude),
      timestamp = lubridate::ymd_hms(timestamp, tz = "UTC"),
      source_file = basename(f)
    )
  
  track_sf <- st_as_sf(
    track_df,
    coords = c("lon", "lat"),
    crs = 4326
  )
  
  unlink(td, recursive = TRUE)
  
  track_sf
}

tracks_list <- map(files, read_kmz_track)

tracks <- list_rbind(tracks_list)

tracks_lv95 <- st_transform(tracks, crs_lv95)
