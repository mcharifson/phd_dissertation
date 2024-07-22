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
library(lubridate)
library(tigris)

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
census_vars %>% filter(str_detect(name, 'B02001')) %>% View() 
census_vars %>% filter(str_detect(name, 'B03003')) %>% View() 

# define states 
states <- lst('NY', 'PA', 'CT', 'NJ')

# which census variables?
my_vars <- c(
  total_pop='B02001_001',
  race_White='B02001_002', 
  race_Black='B02001_003', 
  race_native='B02001_004', 
  race_Asian='B02001_005', 
  race_NHPI='B02001_006', 
  race_other='B02001_007', 
  race_multiple='B02001_008',
  hispanic='B03003_003'
)

# get data
acs_race_2016 <- get_acs(
    geography = "tract",
    variables = my_vars,
    state = states,
    year = 2016,
    survey = "acs5",
    geometry = FALSE)

# summarise by tract
tract_race_2016 <- acs_race_2016 %>%
  filter(variable != 'total_pop') %>%
  select(GEOID, variable, estimate) %>%
  left_join(acs_race_2016 %>% 
              filter(variable== 'total_pop') %>% 
              select(GEOID, estimate) %>%
              rename(total_pop=estimate), by='GEOID') %>%
  mutate(prop = estimate/total_pop) %>%
  pivot_wider(id_cols = GEOID, names_from = variable, values_from = prop, names_prefix="CT_")

# map to our cohort
df_all <- read.csv('Data/Derived/all_data_noImpute_20240626.csv')
cohort_race_2016 <- tract_race_2016 %>% filter(GEOID %in% unique(as.character(df_all$GEOID)))

# look at overall distribution 
summary(cohort_race_2016)

# write out data
write.csv(cohort_race_2016, "Data/External/ACS_CT_race_2016.csv", row.names=FALSE)


