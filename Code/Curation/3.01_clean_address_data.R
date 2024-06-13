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
pat_cohort <- read.csv('Data/Derived/pat_cohort_w_censoring.csv') 
nyc_counties <- read_excel('Data/External/NY_NJ_PA_CT_county_fips.xlsx', 1)
res_his1 <- read.csv('Data/Epic/table5_addr1.csv')
res_his2 <- read.csv('Data/Epic/table5_addr2.csv')

# join together the files 
res_his <- bind_rows(res_his1, res_his2) %>% distinct()
length(which(!pat_cohort$pat_id %in% res_his$pat_id)) # 33 patients have no address data

# subset to patients in the cohort
res_his <- res_his %>% 
  filter(pat_id %in% pat_cohort$pat_id) %>% 
  arrange(pat_id, eff_start_date, eff_end_date)
length(unique(res_his$pat_id)) # here we see the 36 patients with no address data missing

# select the correct GEOID for the year of the address
res_his <- res_his %>%
  mutate(across(where(is.character), ~na_if(., "NULL"))) %>%
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
                                     max_accuracy_score = max(as.numeric(accuracy_score))), 
                                 by = .(pat_id, census_tract_final, full_fips_tract_final, addr_group)]
head(res_his_unique)
summary(res_his_unique$max_accuracy_score)
length(which(res_his_unique$max_accuracy_score < 0.8))/dim(res_his_unique)[1] #5% are low accuracy
length(unique(res_his_unique$pat_id))

write.csv(res_his_unique, 'Data/Derived/Chapter 1/all_cohort_addresses.csv', row.names=FALSE)

## explore the distribution of census tracts
table(substr(res_his_unique$full_fips_tract_final, 1, 2))
# the most populous are NY, NJ, PA, CT and to a lesser extent CA, MA, MD, DC and GA
length(which(!substr(res_his_unique$full_fips_tract_final, 1, 2) %in% c(36, 34, 09, 42)))
length(unique(res_his_unique$pat_id[which(!substr(res_his_unique$full_fips_tract_final, 1, 2) %in% c(36, 34, 09, 42))]))
# look at only NYC counties
table(substr(res_his_unique$full_fips_tract_final, 1, 5))
# filter to only those with a nyc county fips
length(unique(res_his_unique$pat_id[which(substr(res_his_unique$full_fips_tract_final, 1, 5) %in% nyc_counties$`State County fips`)]))
# 74120 patients

################################################################################
# Look for baseline address #####################################################
################################################################################

res_his_unique <- left_join(res_his_unique, pat_cohort[c("pat_id", "index_enc_date")], by="pat_id")
# how many patients have an address prior to their index encounter
length(unique(res_his_unique$pat_id[which(res_his_unique$eff_start_date_min <= res_his_unique$index_enc_date)]))
# 81877

## define baseline address
res_his_baseline <- res_his_unique %>%
  mutate(baseline_addr = case_when(index_enc_date < eff_end_date_max & index_enc_date >= eff_start_date_min~TRUE, 
                                   # if they have one address that has no end date then baseline_addr is true
                                   index_enc_date >= eff_start_date_min & is.na(eff_end_date_max)~TRUE,
                                   TRUE~FALSE),
         addr_time_margin = case_when(baseline_addr~NA,
                                      index_enc_date < eff_start_date_min~difftime(index_enc_date, eff_start_date_min, units = 'day'),
                                      index_enc_date > eff_end_date_max~difftime(index_enc_date, eff_end_date_max, units = 'day')),
         length_residence = case_when(!is.na(eff_end_date_max)~as.numeric(difftime(eff_end_date_max, eff_start_date_min, units='day')),
                                      is.na(eff_end_date_max)~as.numeric(difftime("2023-08-01", eff_start_date_min, units='day'))))

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

summary(as.numeric(res_his_baseline$addr_time_margin[which(res_his_baseline$baseline_addr)]))

length(unique(res_his_baseline$pat_id[which(res_his_baseline$baseline_addr)])) ## 70 patients

################# FILTER TO BASELINE ADDRESS

# filter to baseline address for each patient
res_his_baseline_unique <- res_his_baseline %>% 
  filter(baseline_addr)

no_baseline_addr <- res_his %>% filter(!pat_id %in% res_his_baseline_unique$pat_id) %>% distinct(pat_id)
# check that all patients have only one baseline census tract
res_his_baseline_unique %>% group_by(pat_id) %>% filter(n()>1) %>% nrow()
res_his %>% 
  filter(pat_id %in% res_his_baseline_unique$pat_id[which(duplicated(res_his_baseline_unique$pat_id))]) %>% 
  View()
## duplicates to remove are duplicates who have no end date
res_his_baseline_unique <- res_his_baseline_unique %>% 
  group_by(pat_id) %>% 
  filter(n()==1 | (length_residence!=0)) %>%
  ungroup()
res_his_baseline_unique %>% group_by(pat_id) %>% filter(n()>1) %>% nrow()

################# FILTER TO NYC METRO AREA ADDRESSES

## explore the distribution of census tracts
table(substr(res_his_baseline_unique$full_fips_tract_final, 1, 2))
# the most populous are NY, NJ, PA, CT and to a lesser extent CA, MA, MD, DC and GA
length(which(!substr(res_his_baseline_unique$full_fips_tract_final, 1, 2) %in% c(36, 09, 34, 42)))
length(unique(res_his_baseline_unique$pat_id[which(!substr(res_his_baseline_unique$full_fips_tract_final, 1, 2) %in% c(36, 09, 34, 42))]))
# around 495 are not from NY
# look at only NYC counties
table(substr(res_his_baseline_unique$full_fips_tract_final, 1, 5))
# filter to only those with a nyc county fips
length(unique(res_his_baseline_unique$pat_id[which(!substr(res_his_baseline_unique$full_fips_tract_final, 1, 5) %in% nyc_counties$`State County fips`)]))
## look at ages of those who do not live in NYC
res_his_baseline_unique %>%
  left_join(pat_cohort, by = 'pat_id') %>%
  filter(!substr(res_his_baseline_unique$full_fips_tract_final, 1, 5) %in% nyc_counties$`State County fips`) %>%
  ggplot(data=., aes(x=age_20160801)) +
  geom_histogram(bins=20)
# they are generally young on average (under 25 years), confirming Linda's suspicion
# filter them out and move on
non_nyc_ids <- res_his_baseline_unique %>% 
  filter(!substr(res_his_baseline_unique$full_fips_tract_final, 1, 5) %in% nyc_counties$`State County fips`)
res_his_baseline_unique <- res_his_baseline_unique %>% 
  filter(substr(res_his_baseline_unique$full_fips_tract_final, 1, 5) %in% nyc_counties$`State County fips`)

################# FILTER TO ADDRESSES WITH SUFFICIENT ACCURACY SCORE

# look at accuracy score of patients with baseline census tracts
length(which(res_his_baseline_unique$max_accuracy_score < 0.6)) #1788
# for those with low accuracy look at their other address
res_his %>%
  filter(pat_id %in% unique(res_his_baseline_unique$pat_id[which(res_his_baseline_unique$max_accuracy_score < 0.6)])) %>%
  left_join(res_his_baseline_unique, by='pat_id') %>%
  select(pat_id, index_enc_date, eff_start_date, eff_end_date, full_fips_tract_final.x, contains('accuracy')) %>%
  View()
# some of these patients have an address directly prior which has an accuracy score of 1
res_his_baseline %>%
  filter(pat_id %in% unique(res_his_baseline_unique$pat_id[which(res_his_baseline_unique$max_accuracy_score < 0.6)])) %>%
  select(pat_id, index_enc_date, eff_start_date_min, eff_end_date_max, full_fips_tract_final, contains('accuracy'), addr_time_margin) %>%
  View()
## how many could be filled in by another baseline_address with a better accuracy score
res_his_baseline %>%
  filter(pat_id %in% unique(res_his_baseline_unique$pat_id[which(res_his_baseline_unique$max_accuracy_score < 0.6)])) %>%
  group_by(pat_id) %>%
  mutate(better_accuracy_baseline = ifelse(lead(baseline_addr) & max_accuracy_score >= 0.6 & addr_time_margin <= 180,
                                           TRUE, FALSE)) %>%
  filter(better_accuracy_baseline) %>%
  nrow()
## this recoups 173 patients out of 1813 -- doesn't seem worth it
## explore those with low accuracy
low_accuracy_ids <- res_his_baseline_unique %>% 
  filter(max_accuracy_score < 0.6) %>% 
  left_join(res_his %>% select(pat_id, census_tract_final, accuracy_type, source), by=c('pat_id', 'census_tract_final')) %>%
  distinct()
table(low_accuracy_ids$source) # predominantly US Census
table(low_accuracy_ids$accuracy_type) # predominantly place (zipcode or city centroid)
table(low_accuracy_ids$max_accuracy_score) # predominantly 0.5
table(low_accuracy_ids$full_fips_tract_final) 
## subset to those with high accuracy
res_his_baseline_unique <- res_his_baseline_unique %>% filter(max_accuracy_score >= 0.6)

## make final patient file with address indicated
pat_cohort_w_address <- pat_cohort %>% 
  select(pat_id) %>%
  left_join(res_his_baseline_unique %>% 
              select(pat_id, census_tract_final, full_fips_tract_final, max_accuracy_score),
            by='pat_id') %>%
  mutate(addr_NA_reason = case_when(!is.na(census_tract_final)~NA,
                                    !pat_id %in% res_his$pat_id~'No address data', 
                                    pat_id %in% no_baseline_addr$pat_id~'No baseline address',
                                    pat_id %in% non_nyc_ids$pat_id~'Outside of NY-Newark CSA',
                                    pat_id %in% low_accuracy_ids$pat_id~'Low accuracy score'))

# write out the file
write.csv(res_his_baseline_unique, 'Data/Derived/Chapter 1/baseline_cohort_addresses.csv', row.names=FALSE)
write.csv(pat_cohort_w_address, 'Data/Derived/Chapter 1/pat_cohort_w_address,csv', row.names=FALSE)

#########################################################################################
### Group length of residence by relativity to baseline address #########################
#########################################################################################

res_his_weights <- res_his_baseline %>%
  filter(pat_id %in% res_his_baseline_unique$pat_id) %>%
  mutate(res_his_type = case_when(baseline_addr~'baseline',
                                  eff_start_date_min >= index_enc_date~'during follow-up',
                                  eff_end_date_max <= index_enc_date~'before baseline')) %>%
  group_by(pat_id, res_his_type, full_fips_tract_final) %>%
  summarise(length_residence_months = sum(length_residence, na.rm=TRUE)/30,
            .groups='drop') %>%
  group_by(pat_id, res_his_type) %>%
  mutate(total_length_per_type = sum(length_residence_months, na.rm=TRUE)) %>%
  ungroup() %>%
  group_by(pat_id) %>%
  mutate(total_length_res_his = sum(length_residence_months, na.rm=TRUE)) %>%
  ungroup() %>%
  mutate(weight_res_his = length_residence_months/total_length_res_his,
         weight_res_type = length_residence_months/total_length_per_type)

res_his_weights %>%
  group_by(res_his_type) %>%
  summarise(count=n(), .groups='drop')

# write out the file
write.csv(res_his_weights, 'Data/Derived/Chapter 1/cohort_addresses_weights.csv', row.names=FALSE)

### ARCHIVE CODE ########################################################################

## look at length at that address compared to the address directly prior to it
hist(res_his_baseline$length_residence[which(res_his_baseline$baseline_addr)], breaks=10)
res_his_baseline %>%
  group_by(pat_id) %>%
  mutate(prior_length_residence = ifelse(baseline_addr, lag(length_residence), NA)) %>%
  filter(baseline_addr) %>%
  ggplot(data=., aes(x=length_residence, y=prior_length_residence)) +
  geom_point() + 
  geom_abline(slope=1, intercept=0, color='red') +
  theme_bw()

# the good news is that most participants lived at their baseline address longer than the address
# directly prior to that one
res_his_baseline %>%
  group_by(pat_id) %>%
  mutate(prior_length_residence = ifelse(baseline_addr, lag(length_residence), NA)) %>%
  filter(baseline_addr & length_residence < prior_length_residence) %>%
  nrow()
## there are 3061 patients for whom their address directly prior to their baseline one is the
## longer length of residence than their baseline one
res_his_baseline %>%
  group_by(pat_id) %>%
  mutate(prior_length_residence = ifelse(baseline_addr, lag(length_residence), NA)) %>%
  filter(baseline_addr & length_residence < prior_length_residence) %>%
  ggplot(data=., aes(x=length_residence)) +
  geom_histogram() +
  geom_vline(xintercept=365, color='red') +
  theme_bw()
# of these patients, a portion lived at that address for less than a year
res_his_baseline %>%
  group_by(pat_id) %>%
  mutate(prior_length_residence = ifelse(baseline_addr, lag(length_residence), NA)) %>%
  filter(baseline_addr & length_residence < prior_length_residence) %>%
  nrow()

## for those who do not have a baseline address in NYC but have any address in NYC look at them
not_nyc_baseline <- res_his_baseline %>%
  #filter(!pat_id %in% ids_nyc) %>%
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



