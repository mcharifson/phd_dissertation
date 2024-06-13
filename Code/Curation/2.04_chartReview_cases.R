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
set.seed(2024)

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
# 108 + 358 = 466, pass
length(which(grepl('Both', pat_cohort_new$final_outcome_status) & pat_cohort_new$first_outcome_dx_date == pat_cohort_new$endo_first_dx_date))
# 108 + 127 = 235, pass

## produce chart review list
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
  mutate(type = 'putative true control', 
         condition = NA, 
         first_dx_date = NA, 
         first_dx_date_buffer = NA) %>%
  select(pat_id, pat_mrn_id, type, condition, first_dx_date, first_dx_date_buffer) %>% 
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
  mutate(type = 'putative false positive',
         condition = NA, 
         first_dx_date = NA, 
         first_dx_date_buffer = NA) %>%
  select(pat_id, mrn, type, condition, first_dx_date, first_dx_date_buffer)

## write to chart review folder----
all_chart_info <- rbind(uf_RAN, endo_RAN, both_RAN, controls_RAN, uf_FP, endo_FP, controls_FN)

all_chart_cases <- data.frame(record_id = c(31:781), 
                             redcap_event_name = rep('chart_review_arm_1', 750),
                             mrn_v2 = all_chart_info$mrn)

write.csv(all_chart_info, 'Data/Derived/Chart Review/all_chart_cases_w_info.csv', row.names = FALSE)
write.csv(all_chart_cases, 'Data/Derived/Chart Review/all_chart_cases_import.csv', row.names = FALSE)


## edit cases for chart review------
all_chart_cases <- read.csv('Data/Derived/Chart Review/all_chart_cases_import.csv')

set.seed(2024)
all_chart_cases <- all_chart_cases[sample(1:nrow(all_chart_cases)), ]
all_chart_cases$record_id <- 1:nrow(all_chart_cases)+30
all_chart_cases$redcap_event_name = c(rep('mia_arm_3', 195), 
                                      rep('india_arm_4', 185),
                                      rep('robyn_arm_5', 185), 
                                      rep('geidily_arm_6', 185))
table(all_chart_cases$redcap_event_name)

write.csv(all_chart_cases, 'Data/Derived/Chart Review/review_cases_import_final.csv', row.names = FALSE)

## sample from above for the training set #1------
training_ids <- rbind(sample_n(uf_RAN, 5), sample_n(endo_RAN, 5), sample_n(controls_RAN, 5), sample_n(both_RAN, 5)) %>%
  arrange(pat_id) %>% 
  select(mrn)

training_ids <- as.vector(training_ids$mrn)

training_chart_cases <- data.frame(record_id = rep(1:20, 4), 
                                   redcap_event_name = rep(c('mia_arm_1', 'india_arm_1', 'robyn_arm_1', 'geidily_arm_1'), each=20),
                                   mrn = rep(training_ids, 4))

write.csv(training_chart_cases, 'Data/Derived/Chart Review/training_cases_import.csv', row.names = FALSE)

# to extract for training set comparison
training_set %>%
  left_join(pat_cohort_new %>% select(pat_mrn_id, final_outcome_status, first_outcome_dx_date),
            by = c('mrn'='pat_mrn_id')) %>%
  #select(record_id, final_outcome_status, first_outcome_dx_date ) %>%
  View()

## sample from above for the training set #2------
training_ids_v2 <- rbind(sample_n(uf_RAN, 2), sample_n(endo_RAN, 3), sample_n(controls_RAN, 2), sample_n(both_RAN, 3)) %>%
  arrange(pat_id) %>% 
  select(mrn)

training_ids_v2 <- as.vector(training_ids_v2$mrn)

training_chart_cases_v2 <- data.frame(record_id = rep(1:10, 4), 
                                   redcap_event_name = rep(c('mia_arm_2', 'india_arm_2', 'robyn_arm_2', 'geidily_arm_2'), each=10),
                                   mrn = rep(training_ids_v2, 4))

write.csv(training_chart_cases_v2, 'Data/Derived/Chart Review/training_cases_import_v2.csv', row.names = FALSE)

# to extract for training set comparison
training_chart_cases_v2 <- read.csv('Data/Derived/Chart Review/training_cases_import_v2.csv')

training_chart_cases_v2 %>%
  left_join(pat_cohort_new %>% select(pat_mrn_id, final_outcome_status, first_outcome_dx_date),
            by = c('mrn_v2'='pat_mrn_id')) %>%
  #select(record_id, final_outcome_status, first_outcome_dx_date ) %>%
  View()

