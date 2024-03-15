# 10/31/2023
# Author: Mia Charifson, adapted by code from Teresa Herrera
# Script Description: R code for generating the ICE-RI for census tracts in NYC
# for each year between 2016-2023 for chapter one of my dissertation.
# Please note part of this code was built off of the public health geocoding project https://www.hsph.harvard.edu/thegeocodingproject/covid-19-resources/

## The document follows the following steps: 

## 1: generate ICE value for all NY census tracts for 2016-2022
## 2: link this to the residential history table
## 3: link gentrification index to the above

# load packages
library(tidyverse)
library(tidycensus)
library(sf)
library(tigris)
library(lubridate)
library(scales)
library(readxl)

###################################################################################
## STEP 1: generate ICE value for all NY census tracts for 2016-2022 ##############
###################################################################################

# set options
options(tigris_use_cache = TRUE)
 
# add tidycensus API key to securely load in census data
census_api_key("3ef931e71aefa00abd570dcc13b0b144347e3c3d", overwrite = TRUE, install=TRUE)
readRenviron("~/.Renviron")

# # you can get an API Key here:
# # https://api.census.gov/data/key_signup.html

# check the variable names
census_vars <- load_variables(2016, "acs5", cache = TRUE)
census_vars %>% filter(str_detect(name, 'B19001')) %>% View() 
census_vars %>% filter(str_detect(name, 'B19001B'))

# define states 
states <- lst('NY', 'PA', 'CT', 'NJ')

# define years using purrr::lst to automatically creates a named list
# which will help later when we combine the results in a single tibble
years <- lst(2016, 2017, 2018, 2019, 2020, 2021, 2022)

# which census variables?
my_vars <- c(
  total_white_hh='B19001A_001', 
  #white100_125='B19001A_014', 
  #white125_150='B19001A_015', 
  white150_200='B19001A_016', 
  white_above200='B19001A_017', 
  black_less10='B19001B_002',
  black10_15='B19001B_003', 
  black15_20='B19001B_004', 
  black20_25='B19001B_005', 
  total_black_hh='B19001B_001'
)

# loop over list of years and get 1 year acs estimates
nyc_metro_multi_year <- map_dfr(
  years,
  ~ get_acs(
    geography = "tract",
    variables = my_vars,
    state = states,
    year = .x,
    survey = "acs5",
    geometry = FALSE), 
  .id = "year") %>%
  select(-moe) %>%
  arrange(variable, NAME)

# pivot by tract and year and then summarise
nyc_metro_multi_year_wide <- nyc_metro_multi_year %>% 
  pivot_wider(
    id_cols=c(year, GEOID, NAME),
    names_from=variable,
    values_from=estimate
  ) %>%
  mutate(
    A = white150_200+white_above200,
    P = black_less10+black10_15+black15_20+black20_25,
    T = total_white_hh + total_black_hh,
    ICE_RI = (A-P)/T
  )

# there are some CTs for whom there is a 0 in every value
# this seems unlikely so if rowSum = 0, then set to NA???

# look at overall distribution by year
nyc_metro_multi_year_wide %>%
  ggplot(data=., aes(x=ICE_RI)) +
  geom_histogram(fill='purple', color='black', binwidth=0.1) +
  facet_wrap(~year) +
  theme_bw()

# write out data
write.csv(nyc_metro_multi_year_wide, "Data/External/ACS_ICE_RI_2016_2022.csv", row.names=FALSE)

# to plot the data
# loop over year list and get acs estimates with sf geometry
nyc_metro_multi_year_list <- map(
  years,
  ~ get_acs(
    geography = "tract",
    variables = my_vars,
    state = states,
    year = .x,
    survey = "acs5",
    geometry = TRUE,
    cb = TRUE
  ),
) %>%
  map2(years, ~ mutate(.x, year = .y))  # add year as id variable

nyc_metro_geo <- reduce(nyc_metro_multi_year_list, rbind)

# write out data
save(nyc_metro_geo, file = "Data/External/ACS_ICE_RI_2016_2022_w_geography.RData")




