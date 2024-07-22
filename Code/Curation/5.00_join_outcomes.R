### Join all outcomes together into one dataframe for all patients

# load data
uf_cohort <- read.csv('Data/Derived/uf_all_hints.csv')
endo_cohort <- read.csv('Data/Derived/endo_all_hints.csv')
false_negatives <- read.csv('Data/Derived/putative_false_negatives.csv')
adeno <- read.csv('Data/Derived/clean_covariates.csv') %>% select(pat_id, contains('adeno'))
pat_cohort <- read.csv('Data/Derived/pat_cohort_w_censoring.csv')
address <- read.csv('Data/Derived/Chapter 1/pat_cohort_w_address.csv', 
                    colClasses = c(census_tract_final = "character",
                                   full_fips_tract_final = "character"))

## make necessary changes to UF data
uf_final <- uf_cohort %>% 
  # rework UF definition without referral & prevalent dx
  mutate(confident_incident = case_when(confident_prevalent~FALSE,
                                        ever_confirmed_6months | any_location |
                                          ever_pregnancy_related | dx_after_partial_LTFU~TRUE,
                                        TRUE~FALSE)) %>%
  select(pat_id, confident_incident, confident_prevalent, first_dx_date, first_confirm_date, 
         first_confirm_type, first_location_date, imaging_confirmed, surgery_confirmed) %>%
  mutate(icd_confirmed = TRUE,
         algorithm = case_when(confident_incident~'Incident', !confident_incident~'Prevalent')) %>%
  rename_at(vars(confident_incident:algorithm), ~paste0("uf_", .))

## make necessary changes to Endo data
endo_final <- endo_cohort %>% 
  # add Adeno information to try to identify false positives
  left_join(adeno, by='pat_id') %>%
  # redo endo definition without referral & prevalent dx, & false positive if <2 billing & have Adeno
  mutate(false_positive = (first_dx_type == 'Hospital Account Diagnosis' & dx_count <= 2 & adeno_final=='Yes'),
         confident_incident = case_when(false_positive | confident_prevalent~FALSE,
                                        ever_confirmed_6months | any_location |
                                          dx_via_laparoscopy | dx_after_partial_LTFU~TRUE,
                                        TRUE~FALSE)) %>%
  select(pat_id, confident_incident, confident_prevalent, first_dx_date, first_confirm_date, 
         first_confirm_type, first_location_date, imaging_confirmed, surgery_confirmed, false_positive) %>%
  mutate(icd_confirmed = TRUE,
         algorithm = case_when(false_positive~'No Dx',
                               confident_incident~'Incident', 
                               !confident_incident~'Prevalent')) %>%
  rename_at(vars(confident_incident:algorithm), ~paste0("endo_", .))

## join all together
df_final <- pat_cohort %>% 
  select(pat_mrn_id, pat_id, index_enc_date) %>% 
  left_join(uf_final, by='pat_id') %>%
  left_join(endo_final, by='pat_id') %>%
  # fill in NA for rest of cohort
  mutate_at(vars(uf_confident_incident, uf_imaging_confirmed:uf_icd_confirmed), ~ifelse(is.na(.), FALSE, .)) %>%
  mutate_at(vars(endo_confident_incident, endo_imaging_confirmed:endo_icd_confirmed), ~ifelse(is.na(.), FALSE, .)) %>%
  # make those missing outcome to NA and make final outcome
  mutate(uf_algorithm = case_when(is.na(uf_algorithm)~'No Dx', TRUE~uf_algorithm),
         endo_algorithm = case_when(is.na(endo_algorithm)~'No Dx', TRUE~endo_algorithm),
         uf_first_dx_date = as.Date(uf_first_dx_date), 
         endo_first_dx_date = as.Date(endo_first_dx_date), 
         final_outcome_status = case_when(uf_algorithm=='Prevalent' & endo_algorithm != 'Incident'~'Unconfirmed',
                                          endo_algorithm=='Prevalent' & uf_algorithm != 'Incident'~'Unconfirmed',
                                          uf_algorithm=='Incident' & endo_algorithm=='Incident' ~'Both Incident',
                                          uf_algorithm=='Incident' & endo_algorithm!='Incident'~'Incident UF only',
                                          uf_algorithm!='Incident' & endo_algorithm=='Incident'~'Incident Endo only',
                                          TRUE~'Neither')) 

pat_w_outcome <- df_final %>%
  left_join(address %>% 
              select(pat_id, censor_address_date, censor_address_type) %>%
              rename(final_censor_date = censor_address_date,
                     final_censor_type = censor_address_type), by='pat_id') %>%
  mutate(uf_dx = case_when(uf_confident_incident~TRUE, TRUE~FALSE),
         endo_dx = case_when(endo_confident_incident~TRUE, TRUE~FALSE),
         outcome_order = case_when(final_outcome_status == 'Both, Incident' & 
                                     uf_first_dx_date < endo_first_dx_date~'UF first',
                                   final_outcome_status == 'Both, Incident' & 
                                     uf_first_dx_date > endo_first_dx_date~'Endo first',
                                   final_outcome_status == 'Both, Incident' & 
                                     uf_first_dx_date == endo_first_dx_date~'Same day'),
         first_outcome_dx_date = case_when(final_outcome_status == 'Incident UF only'~uf_first_dx_date,
                                           final_outcome_status == 'Incident Endo only'~endo_first_dx_date,
                                           final_outcome_status %in% c('Both, Incident') &
                                             outcome_order %in% c('UF first', 'Same day')~uf_first_dx_date,
                                           final_outcome_status== 'Both, Incident' &
                                             outcome_order == 'Endo first'~endo_first_dx_date),
         outcome_before_censor = case_when(final_outcome_status == 'Neither'~NA,
                                           first_outcome_dx_date <= final_censor_date~TRUE,
                                           TRUE~FALSE),
         final_censor_type_outcome = case_when(final_outcome_status != 'Neither' & outcome_before_censor~'Case',
                                               (final_outcome_status == 'Incident UF only' |
                                                 outcome_order %in% c('UF first', 'Same day')) &
                                                 final_censor_type==uf_first_confirm_type~'Case',
                                               (final_outcome_status == 'Incident Endo only' |
                                                 outcome_order  == 'Endo first') &
                                                 final_censor_type==endo_first_confirm_type~'Case',
                                               TRUE~final_censor_type),
         final_censor_date_outcome = case_when(final_censor_type_outcome=='Case'~first_outcome_dx_date,
                                               TRUE~as.Date(final_censor_date))) %>%
  select(-final_censor_date, -final_censor_type, -outcome_before_censor) %>%
  rename(final_censor_date = final_censor_date_outcome, final_censor_type = final_censor_type_outcome)

# checks
table(pat_w_outcome$uf_confident_incident)
table(pat_w_outcome$endo_confident_incident)
table(pat_w_outcome$final_censor_type)
length(which(is.na(pat_w_outcome$final_censor_type)))

write.csv(pat_w_outcome, 'Data/Derived/final_cohort_w_outcome.csv', row.names = FALSE)
