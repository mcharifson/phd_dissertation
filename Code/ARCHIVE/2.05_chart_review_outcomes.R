## perform chart review for UF and Endo

library(tidyverse)
library(lubridate)
library(clipr)

## load files
#uf_chart_review <- read.csv('Data/Derived/uf_chart_review_cases.csv')
uf_chart_review <- read.csv('Data/Derived/uf_chart_review_complete.csv')
endo_chart_review <- read.csv('Data/Derived/endo_chart_review_cases.csv')

### REVIEW UF CASES ------------------------------------------------------------

# add new columns
uf_chart_review$dx_review_case <- NA
uf_chart_review$dx_review_incident <- NA
uf_chart_review$dx_review_date <- NA
uf_chart_review$dx_review_note <- NA

## pick up where we left off i=1
## perform chart review
for (i in 37:dim(uf_chart_review)[1]) {
  print(i)
  print(uf_chart_review[i, ])
  write_clip(uf_chart_review$pat_mrn_id[i])
  ## did you find the patient?
  x <- readline("Could you access this patient's EHR?: ");
  if (x=='N') next
  ## determine overall case status
  #df$dx_review_case[i] <- 
  a <- readline("Is this patient a true UF dx? Answer Y, N or unclear: ");
  uf_chart_review$dx_review_case[i] <- a
  ## determine incidence of case status
  if (a == 'Y') {
    b <- readline("Is this patient an incident UF dx? Answer Y, N or unclear: ");
    uf_chart_review$dx_review_incident[i] <- b
  }
  else b <- 'N'
  ## determine date if incident case
  c <- readline("If not incident or date does not match, what is the date of their first dx code?: ");
  uf_chart_review$dx_review_date[i] <- c
  ## other notes
  d <- readline("Any other notes on this case review?: ");
  uf_chart_review$dx_review_note[i] <- d
}

write.csv(uf_chart_review, 'Data/Derived/uf_chart_review_complete.csv', row.names = F)

### REVIEW ENDO CASES ------------------------------------------------------------

# add new columns
endo_chart_review$dx_review_case <- NA
endo_chart_review$dx_review_incident <- NA
endo_chart_review$dx_review_date <- NA
endo_chart_review$dx_review_note <- NA

i=1
## perform chart review
for (i in 1:dim(endo_chart_review)[1]) {
  print(i)
  print(endo_chart_review[i, ])
  write_clip(substr(endo_chart_review$pat_id[i], 2, 8))
  ## did you find the patient?
  x <- readline("Did you find the patient?: ");
  if (x=='N') next
  ## determine overall case status
  #df$dx_review_case[i] <- 
  a <- readline("Is this patient a true endo dx? Answer Y, N or unclear: ");
  endo_chart_review$dx_review_case[i] <- a
  ## determine incidence of case status
  if (a == 'Y') {
    b <- readline("Is this patient an incident endo dx? Answer Y, N or unclear: ");
    endo_chart_review$dx_review_date[i] <- b
  }
  ## determine date if incident case
  if (b == 'Y') {
    c <- readline("If so, what is the date of their first dx code?: ");
    endo_chart_review$dx_review_date[i] <- c
  }
  ## other notes
  d <- readline("Any other notes on this case review?: ");
  endo_chart_review$dx_review_note[i] <- d
} 
