# Proposal for Semester Project


<!-- 
Please render a pdf version of this Markdown document with the command below (in your bash terminal) and push this file to Github. 
Please do not Rename this file (Readme.md has a special meaning on GitHub).

quarto render Readme.md --to pdf
-->

**Patterns & Trends in Environmental Data / Computational Movement Analysis / Geo 880**

| Semester:      | FS26                                     |
|:---------------|:---------------------------------------- |
| **Data:**      | Weather Data                             |
| **Title:**     | Weather Conditions and their Influence on human Mobility Patterns               |
| **Student 1:** | Lars Weidinger                           |
| **Student 2:** | Javier Feller                            |

## Abstract 
<!-- (50-60 words) -->
This project investigates how weather conditions influence human mobility patterns in Zürich. We will be using personal GPS tracking trajectories and meteorological data. We analyse movement characteristics such as travel distance, activity spaces (area), speed, sinousity and temporal mobility patterns under different environmental conditions. We aim to identify relationships between weather and everyday movement behavior using R

## Research Questions
<!-- (50-60 words) -->
I) How do temperature and precipitation affect daily travel distance, speed, sinuousity and acceleration?  
II) How do temperature and precipitation affect the spatial extent of activity spaces?  
III) Does travel speed increase with more precipitation?  
IV) How does precipitation affect the number of stops?  

## Results / products
<!-- (50-100 words) -->
<!-- What do you expect, anticipate? -->
We want to generate: 
- trajectory maps  
- weather-mobility (correlation) analysis  
- activity-space visualisations
- statistical summaries of movement behavior under different weather conditions  

With higher temperature or more precipitation, we expect higher speed, more acceleration and lower travel distance.

## Data
<!-- (100-150 words) -->
<!-- What data will you use? Will you require additional context data? Where do you get this data from? Do you already have all the data? -->
We will use the tracking data of the two group members. We tracked our movement using Google Timeline and ArcGIS Earth simultaniously on our Smartphones. Google Timeline generates a JSON file with the stops while ArcGIS Earth generates accurate trajectories with a high temporal sampling interval (ca. 10 sec). We will anonymise our data through deleting the first and last e.g. 50 meters of our trajectories.
Additionally, we will use weather data from the city of Zürich: https://data.stadt-zuerich.ch/dataset/ugz_meteodaten_tagesmittelwerte. We will focus on the variables of temperature, precipitation, precipitation length and maybe steepness. 

## Analytical concepts
<!-- (100-200 words) -->
<!-- Which analytical concepts will you use? What conceptual movement spaces and respective modelling approaches of trajectories will you be using? What additional spatial analysis methods will you be using? -->

As conceptual movement space, we select a constrained movement, using a network approach with movement along edges and nodes, since most of the time we have been moving in public transport and fixed routes.
Therefore, to adhere to the network structure, we first need to match the trajectories to existing routes (map matching) using a buffer around streets and public transport lines and analyze abrupt speed changes within a moving window. 

After removing artifacts and reducing noice, we segment our trajectories into stops and moves using a moving window and parameter threshold. Since we will integrate movement data from Google Timeline and ArcGIS Earth, we are required to match stops of Google Timeline with the segmented stops of ArcGIS Earth.
We will then cluster trajectories based on the Dynamic Time Warping (DTW) algorithm, by defining the frame of reference (respectively clarify what should be compared), choosing a distance metric and computing a similarity matrix. We will also derive then movement spaces and temporal patters from these trajectories (or segments). 
When deriving speed and sinousity, we are thinking of varying the temporal scale (10 sec and 30 sec) to account for the effect of scale selection (cross-scale movement analysis).
If possible, we will include a monte-carlo simulation to quantify the related uncertainty.

## R concepts
<!-- (50-100 words) -->
<!-- Which R concepts, functions, packages will you mainly use. What additional spatial analysis methods will you be using? -->
We will primarily use R packages such as sf, tidyverse and ggplot2 for spatial trajectory analysis and visualisation. Additional packages such as lubridate, dbscan, and leaflet may be used for temporal analysis (lubridate), clustering (DBSCAN) and the creation of interactive maps (Leaflet). 

## Risk analysis
<!-- (100-150 words) -->
<!-- What could be the biggest challenges/problems you might face? What is your plan B? -->
Risks/Challenges:  
- insufficient trajectory duration  
- low sample size (only 2 people)  
- weak weather effects  
- data privacy issues  

Our plan B is to focus more on the descriptive movement analysis if we do not have enough data for statistical analysis. We might include the data of other students to increase our sample size. If the weather effects are not very signifcant, we might increase the temporal resolution, so instead of looking at the movement of a single day we look at single trips or only take days with strong differences in the weather (more proof of concept than statisctically relevant).

## Questions? 
<!-- (100-150 words) -->
<!-- Which questions would you like to discuss at the coaching session? -->
Is this scope appropriate?  
Could/Should we include other datasets?  
Does the selection scale and order of procedure make sense?
