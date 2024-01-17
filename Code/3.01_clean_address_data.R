## Cleaning address data
# 1/10/2024
# Author: Mia Charifson

## The document follows the following steps: 

### 1. join the two halves of the data (remove overlap)
### 2. collapse the same addresses across multiple dates
### 3. identify the baseline address (closest to index encounter)

# load packages
library(tidyverse)
library(lubridate)
library(readxl)
library(data.table)

# load files
pat_cohort <- read.csv('Data/Derived/pat_cohort_w_censoring.csv') %>% select(-X)
res_his1 <- read.csv('Data/Epic/table5_addr_top.csv')
res_his2 <- read.csv('Data/Epic/table5_addr_bottom.csv')

# join together the files 
res_his <- bind_rows(res_his1, res_his2) %>% distinct()
length(which(!pat_cohort$pat_id %in% res_his$pat_id)) # 4 patients have no address data

# subset to patients in the cohort
res_his <- res_his %>% filter(pat_id %in% pat_cohort$pat_id) %>% arrange(pat_id, eff_start_date, eff_end_date)
length(unique(res_his$pat_id)) # here we see the 4 patients with no address data

# select the correct GEOID for the year of the address
res_his <- res_his %>%
  mutate(eff_start_date = as.Date(eff_start_date), 
         eff_end_date = as.Date(eff_end_date), 
         census_tract_final = ifelse(year(eff_start_date)<2020, 
                                     census_tract_code_2010, census_tract_code_2020),
         full_fips_tract_final = ifelse(year(eff_start_date)<2020, 
                                        full_fips_tract_2010, full_fips_tract_2020)) %>%
  select(pat_id, geo_addr_id, eff_start_date, eff_end_date, census_tract_final, 
         full_fips_tract_final, source, accuracy_type, accuracy_score)
  

# collapse the same address across multiple dates
res_his_unique <- data.table(res_his)
# remove rows that start and end on the same day (these seem to be errors)
#res_his_unique <- res_his_unique[eff_start_date == eff_end_date, ]
# make address groups
z <-  rle(paste0(res_his_unique$pat_id, res_his_unique$full_fips_tract_final))
res_his_unique$addr_group <- rep(1:length(z$lengths),z$lengths)
# summarise info for a given address group
res_his_unique <- res_his_unique[, .(eff_start_date_min = min(as.Date(eff_start_date)), 
                                     eff_end_date_max = max(as.Date(eff_end_date)),
                                     mean_accuracy_score = mean(as.numeric(accuracy_score))), 
                                 by = .(pat_id, census_tract_final, full_fips_tract_final, addr_group)]
head(res_his_unique)
summary(res_his_unique$mean_accuracy_score)
length(which(res_his_unique$mean_accuracy_score < 0.8))/dim(res_his_unique)[1] #5% are low accuracy
length(unique(res_his_unique$pat_id))

write.csv(res_his_unique, 'Data/Derived/all_cohort_addresses.csv')

## explore the distribution of census tracts
table(substr(res_his_unique$full_fips_tract_final, 1, 2))
# the most populous are NY, NJ, PA, CT and to a lesser extent CA, MA, MD, DC and GA
length(which(substr(res_his_unique$full_fips_tract_final, 1, 2)!=36))
length(unique(res_his_unique$pat_id[which(substr(res_his_unique$full_fips_tract_final, 1, 2)!=36)]))
# look at only NYC counties
nyc_counties <- c(36005, 36047, 36061, 36081, 36085)
table(substr(res_his_unique$full_fips_tract_final, 1, 5))
# filter to only those with a nyc county fips
length(unique(res_his_unique$pat_id[which(substr(res_his_unique$full_fips_tract_final, 1, 5) %in% nyc_counties)]))
# 84979 patients

################################################################################
# Look for baseline address #####################################################
################################################################################

res_his_unique <- left_join(res_his_unique, pat_cohort[c("pat_id", "index_enc_date")], by="pat_id")
res_his_baseline <- res_his_unique %>%
  mutate(baseline_addr = case_when(index_enc_date < eff_end_date_max & index_enc_date >= eff_start_date_min~TRUE, 
                                   # if they have one address that has no end date then baseline_addr is true
                                   index_enc_date >= eff_start_date_min & is.na(eff_end_date_max)~TRUE,
                                   TRUE~FALSE),
         addr_time_margin = case_when(baseline_addr~NA,
                                      index_enc_date < eff_start_date_min~difftime(index_enc_date, eff_start_date_min, units = 'day'),
                                      index_enc_date > eff_end_date_max~difftime(index_enc_date, eff_end_date_max, units = 'day'),))

# check who has an exact baseline address
table(res_his_baseline$baseline_addr) ## seems pretty good
length(unique(res_his_baseline$pat_id[which(res_his_baseline$baseline_addr)])) 
## almost everyone has a baseline address

# look at those without an exact baseline address
summary(as.numeric(res_his_baseline$addr_time_margin))

# look at these patients
res_his_baseline %>% group_by(pat_id) %>% filter(sum(baseline_addr) == 0) %>% View()

# this is very few patients and most of them are very close except a handful of patients
res_his_baseline <- res_his_baseline %>%
  group_by(pat_id) %>%
  mutate(baseline_addr = case_when(abs(addr_time_margin)==min(abs(addr_time_margin))~TRUE,
                                   TRUE~baseline_addr)) %>%
  ungroup()

length(unique(res_his_baseline$pat_id[which(res_his_baseline$baseline_addr)])) ## all but 4 patients

# filter to baseline address for each patient
res_his_baseline_unique <- res_his_baseline %>% filter(baseline_addr)
# look at all patients with more than one baseline census tract
res_his_baseline_unique %>% group_by(pat_id) %>% filter(n()>1) %>% arrange(pat_id, eff_start_date_min) %>% View()
# look at all patients with different baseline census tracts
res_his_baseline_unique %>% group_by(pat_id) %>% filter(n()>1 & n_distinct(census_tract_final)>1) %>% arrange(pat_id, eff_start_date_min) %>% View()
length(which(res_his_baseline_unique$mean_accuracy_score < 0.8))/dim(res_his_baseline_unique)[1] #3% are low accuracy

## explore the distribution of census tracts
table(substr(res_his_baseline_unique$full_fips_tract_final, 1, 2))
# the most populous are NY, NJ, PA, CT and to a lesser extent CA, MA, MD, DC and GA
length(which(substr(res_his_baseline_unique$full_fips_tract_final, 1, 2)!=36))
length(unique(res_his_baseline_unique$pat_id[which(substr(res_his_baseline_unique$full_fips_tract_final, 1, 2)!=36)]))
# around 14911 are not from NY
# look at only NYC counties
table(substr(res_his_baseline_unique$full_fips_tract_final, 1, 5))
# filter to only those with a nyc county fips
length(unique(res_his_baseline_unique$pat_id[which(substr(res_his_baseline_unique$full_fips_tract_final, 1, 5) %in% nyc_counties)]))
# 81256 patients
ids_nyc <- unique(res_his_baseline_unique$pat_id[which(substr(res_his_baseline_unique$full_fips_tract_final, 1, 5) %in% nyc_counties)])

## for those who do not have a baseline address in NYC but have any address in NYC look at them
not_nyc_baseline <- res_his_baseline %>%
  filter(!pat_id %in% ids_nyc) %>%
  mutate(nyc_addr = ifelse(substr(full_fips_tract_final, 1, 5) %in% nyc_counties, TRUE, FALSE)) %>%
  arrange(pat_id, eff_start_date_min, eff_end_date_max) %>%
  group_by(pat_id) %>%
  mutate(ever_nyc = ifelse(sum(nyc_addr)>=1, TRUE, FALSE))
# how many are not a nyc patient
length(unique(not_nyc_baseline$pat_id)) #22997
# how many have at least one nyc address
length(unique(not_nyc_baseline$pat_id[which(not_nyc_baseline$ever_nyc)])) #3723
# look at these patients and determine if any of them might be eligible (i.e. mostly NYC but edge case)
not_nyc_baseline %>% 
  filter(ever_nyc) %>% 
  select(pat_id, index_enc_date, baseline_addr, nyc_addr, contains('eff'), full_fips_tract_final) %>% 
  View()

# look for instances where their nyc address is before the index encounter and the margin to index encounter
nyc_before_baseline <- not_nyc_baseline %>%
  group_by(pat_id) %>%
  filter(nyc_addr & eff_end_date_max <= index_enc_date) 
summary(as.numeric(nyc_before_baseline$addr_time_margin))
length(which(as.numeric(nyc_before_baseline$addr_time_margin)<30)) #363 are less than a month
## how long were they at this NYC address
nyc_before_baseline %>%
  filter(addr_time_margin<30) %>%
  mutate(length_residence = as.numeric(difftime(eff_end_date_max, eff_start_date_min, unit='days'))) %>%
  summary()
# the shortest length of residence is 0 days, the longest 8 years
# lets look at the short ones
nyc_before_baseline %>%
  filter(addr_time_margin<30) %>%
  mutate(length_residence = as.numeric(difftime(eff_end_date_max, eff_start_date_min, unit='days'))) %>%
  filter(length_residence < 365) %>%
  View()
# I might want to look at the average length of residence up until index encounter for those who are in NYC addresses

# write out the file
write.csv(res_his_baseline_unique, 'Data/Derived/baseline_cohort_addresses.csv')

