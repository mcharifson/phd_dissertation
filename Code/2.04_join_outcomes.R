## this code selects the chart review cases for validation study
library(tidyverse)
library(dplyr)
library(lubridate)

## load data-----
uf_cohort <- read.csv('Data/Derived/uf_all_hints.csv')
endo_cohort <- read.csv('Data/Derived/endo_all_hints.csv')
false_negatives <- read.csv('Data/Derived/putative_false_negatives.csv')
pat_cohort <- read.csv('Data/Derived/pat_cohort_w_censoring.csv')
template <- read.csv('Data/Derived/Chart review/template_data_import.csv')

## join outcomes together-----
pat_cohort_new <- pat_cohort %>%
  left_join(uf_cohort %>%
              filter(confident_incident) %>%
              select(pat_id, first_dx_date, first_confirm_date, 
                     first_confirm_type, first_location_date) %>%
              rename_all(~paste0("uf_", .)),
            by=c('pat_id' = 'uf_pat_id')) %>%
  left_join(endo_cohort %>%
              filter(confident_incident) %>%
              select(pat_id, first_dx_date, first_confirm_date, 
                     first_confirm_type, first_location_date) %>%
              rename_all(~paste0("endo_", .)),
            by=c('pat_id' = 'endo_pat_id')) %>%
  mutate(uf_dx = case_when(!is.na(uf_first_dx_date)~TRUE, TRUE~FALSE),
         endo_dx = case_when(!is.na(endo_first_dx_date)~TRUE, TRUE~FALSE),
         uf_first_dx_date = as.Date(uf_first_dx_date), 
         endo_first_dx_date = as.Date(endo_first_dx_date), 
         final_outcome_status = case_when((uf_dx & endo_dx) & uf_first_dx_date < endo_first_dx_date~'Both, UF first',
                                          (uf_dx & endo_dx) & uf_first_dx_date > endo_first_dx_date~'Both, Endo first',
                                          (uf_dx & endo_dx) & uf_first_dx_date == endo_first_dx_date~'Both, same day',
                                          uf_dx & !endo_dx~'UF only',
                                          !uf_dx & endo_dx~'Endo only',
                                          !uf_dx & !endo_dx~'Control'),
         first_outcome_dx_date = case_when(final_outcome_status %in% c('UF only', 'Both, UF first', 'Both, same day')~uf_first_dx_date,
                                           final_outcome_status %in% c('Endo only', 'Both, Endo first')~endo_first_dx_date),
         outcome_before_censor = case_when(final_outcome_status == 'Control'~NA,
                                           #is.na(final_censor_date)~TRUE,
                                           first_outcome_dx_date <= final_censor_date~TRUE,
                                           TRUE~FALSE),
         final_censor_type_outcome = case_when(final_outcome_status != 'Control' & outcome_before_censor~'Case',
                                               final_outcome_status %in% c('UF only', 'Both, UF first', 'Both, same day') &
                                                 final_censor_type==uf_first_confirm_type~'Case',
                                               final_outcome_status %in% c('Endo only', 'Both, Endo first') &
                                                 final_censor_type==endo_first_confirm_type~'Case',
                                               TRUE~final_censor_type),
         final_censor_date_outcome = case_when(final_censor_type_outcome=='Case'~first_outcome_dx_date,
                                               TRUE~as.Date(final_censor_date)))

## checks
table(pat_cohort_new$final_outcome_status)
length(which(grepl('Both', pat_cohort_new$final_outcome_status) & pat_cohort_new$first_outcome_dx_date == pat_cohort_new$uf_first_dx_date))
# 126 + 385 = 511, pass
length(which(grepl('Both', pat_cohort_new$final_outcome_status) & pat_cohort_new$first_outcome_dx_date == pat_cohort_new$endo_first_dx_date))
# 126 + 135 = 261, pass

## produce chart review list
set.seed(2024)
## keep putative case status [condition], MRN [mrn], first date if available [first_dx_date], first date buffer [first_dx_date_buffer]

## NOTE: BUFFER IS CURRENLTY SET TO 2 MONTHS BUT WILL DECIDE IF I NEED TO CHANGE AFTER DISCUSSING WITH ONCHEE

## randomly select 150 putative incident UF cases (only)----
uf_RAN <- sample_n(pat_cohort_new %>% filter(final_outcome_status == 'UF only' & final_censor_type_outcome == 'Case'), 150) %>%
  select(pat_id, pat_mrn_id, first_outcome_dx_date) %>%
  mutate(condition = 'UF', 
         type = 'incident case',
         first_dx_date_buffer = first_outcome_dx_date %m+% months(2)) %>%
  rename(mrn = pat_mrn_id, first_dx_date = first_outcome_dx_date) %>%
  select(pat_id, mrn, type, condition, first_dx_date, first_dx_date_buffer)

## randomly select 150 putative incident Endo cases (only)----
endo_RAN <- sample_n(pat_cohort_new %>% filter(final_outcome_status == 'Endo only' & final_censor_type_outcome == 'Case'), 150) %>% #View()
  select(pat_id, pat_mrn_id, first_outcome_dx_date) %>%
  mutate(condition = 'Endo', 
         type = 'incident case',
         first_dx_date_buffer = first_outcome_dx_date %m+% months(2)) %>%
  rename(mrn = pat_mrn_id, first_dx_date = first_outcome_dx_date) %>%
  select(pat_id, mrn, type, condition, first_dx_date, first_dx_date_buffer)

## randomly select 75 putative incident UF + Endo cases----
both_RAN <- sample_n(pat_cohort_new %>% filter(grepl('Both', final_outcome_status) & final_censor_type_outcome == 'Case'), 75)  %>% #View()
  select(pat_id, pat_mrn_id, first_outcome_dx_date) %>%
  mutate(condition = 'Both', 
         type = 'incident case',
         first_dx_date_buffer = first_outcome_dx_date %m+% months(2)) %>%
  rename(mrn = pat_mrn_id, first_dx_date = first_outcome_dx_date) %>%
  select(pat_id, mrn, type, condition, first_dx_date, first_dx_date_buffer)

## randomly select 150 putative controls----
controls_RAN <- sample_n(pat_cohort_new %>% filter(final_outcome_status == 'Control'), 150) %>%
  mutate(type = 'putative true control') %>%
  select(pat_id, pat_mrn_id, type) %>% 
  rename(mrn = pat_mrn_id)

## randomly select 75 putative prevalent UF cases (only)----
uf_FP <- sample_n(uf_cohort %>% filter(!confident_incident), 75)  %>%
  select(pat_id, first_dx_date) %>%
  left_join(pat_cohort %>% select(pat_id, pat_mrn_id) %>% rename(mrn = pat_mrn_id), 
            by='pat_id') %>%
  mutate(condition = 'UF', 
         type = 'putative prevalent/false positive',
         first_dx_date_buffer = as.Date(first_dx_date) %m+% months(2)) %>%
  select(pat_id, mrn, type, condition, first_dx_date, first_dx_date_buffer)

## randomly select 75 putative prevalent UF cases (only)----
endo_FP <- sample_n(endo_cohort %>% filter(!confident_incident), 75)  %>%
  select(pat_id, first_dx_date) %>%
  left_join(pat_cohort %>% select(pat_id, pat_mrn_id) %>% rename(mrn = pat_mrn_id), 
            by='pat_id') %>%
  mutate(condition = 'Endo', 
         type = 'putative prevalent/false positive',
         first_dx_date_buffer = as.Date(first_dx_date) %m+% months(2)) %>%
  select(pat_id, mrn, type, condition, first_dx_date, first_dx_date_buffer)

## randomly select 75 putative false negative controls----
controls_FN <- sample_n(false_negatives, 75) %>%
  select(pat_id) %>%
  left_join(pat_cohort %>% select(pat_id, pat_mrn_id) %>% rename(mrn = pat_mrn_id), 
            by='pat_id') %>%
  mutate(type = 'putative false positive') %>%
  select(pat_id, mrn, type)

## write to chart review folder----
uf_all_RAN <- rbind(uf_RAN, uf_FP)
endo_all_RAN <- rbind(endo_RAN, endo_FP)
controls_all_RAN <- rbind(controls_RAN, controls_FN)

write.csv(, row.names = FALSE)