# 10/31/2023
# Author: Mia Charifson, adapted by code from Teresa Herrera
# Script Description: R code for generating the number of total women of reproductive age (15-44 yo) 
# for each state for each year between 2010-2021 for the project looking at acute climate events and 
# fertility rates. 
# Please note part of this code was built off of the public health geocoding project https://www.hsph.harvard.edu/thegeocodingproject/covid-19-resources/

# load packages

library(tidyverse)
library(tidycensus)
library(sf)
library(tigris)
library(lubridate)

# set options

options(tigris_use_cache = TRUE)

# add tidycensus API key to securely load in census data

census_api_key("76346286dbe229b606299e9e6d31e0eda25a95d6", overwrite = TRUE)

# you can get an API Key here:
# https://api.census.gov/data/key_signup.html

### name states of interest
my_states <- c("NY")

# generate list of variables according this data dictionary
# https://www.socialexplorer.com/data/ACS2016_5yr/metadata/?ds=ACS16_5yr&table=B01001
my_vars <- c('B19001A_014', 'B19001A_015', 'B19001A_016', 'B19001A_017', 'B19001B_002',
             'B19001B_003E', 'B19001B_004', 'B19001B_005', 'B19001_001')

# call all years from 2009-2019
years <- lst(2016, 2017, 2018, 2019, 2020, 2021, 2022)

# perform multi-year call
multi_year <-
  map(
    years,
    ~ get_acs(
      geography = "tract",
      state = my_states,
      variables = my_vars,
      year = .x,
      survey='acs5',
      geometry = FALSE)) %>%
  map2(years, ~ mutate(.x, id = .y))

# combine into single dataframe
all_years <- reduce(multi_year, rbind)

# summarise by state and year and then repeat for each month
df <- all_years %>%
  group_by(NAME, id) %>%
  summarise(Total_WRA_Pop = sum(estimate), .groups='drop') %>%
  rename(State = NAME, Year = id)

##here we only select the variables we need for the merge, here those are the GEOID, B19001_001E = total population per tract
# variables B19001A_014E through B19001A_017E are the number of white households with incomes greater than or equal to $100,000 per year in a tract (this represents the privileged group in the ICE metric)
# variables B19001B_002E through B19001B_005E are the number of Black households with incomes less than or equal to $24,999 per year in a tract (this represents the less privileged group)
race.inc <- merge %>%
  ## create more privileged group
  mutate(above80.white = B19001A_014E + B19001A_015E + B19001A_016E + B19001A_017E) %>%
  ## create less privileged group
  mutate(below20.black = B19001B_002E + B19001B_003E + B19001B_004E + B19001B_005E) %>%
  ## total for the tract
  rename(total.n = B19001_001E) %>%
  select(GEOID, above80.white, below20.black, total.n)

race.inc <- race.inc %>% 
  mutate(ICEwbinc=(above80.white-below20.black)/total.n) # this creates the ice metric 

hist(race.inc$ICEwbinc)

write.csv(df, "../Data/wra_2009-2021.csv")







