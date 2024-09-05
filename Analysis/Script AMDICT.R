# PACKAGES USED ---- ####
library(tidyverse)
library(fixest)
library(questionr)
library(Kendall)
library(reshape2)
library(dplyr)
library(psych)
library(dunn.test)
library(gtsummary)
library(broom)
library(purrr)
library(openxlsx)
library(ggplot2)

# 1 - DATASET WORKS ---- ####
#DATA = read.table("C:/Users/Gabriel Bayle/Documents/1 - Autres projets/AM DICTATEUR/DATA.csv",sep=",",header=T)
DATA = read.table("C:/Users/Gabriel Bayle/Documents/1 - Autres projets/AM DICTATEUR/DATA.csv",sep=",",header=T)

## 1.1 - Creation of variables ####

### Realized extraction ####
DATA$extcor = DATA$extraction_group
DATA$extcor[which(DATA$approbation_group == 0)] = DATA$extraction_group_applied[which(DATA$approbation_group == 0)]

### Sequences ####
DATA$seq = ifelse(DATA$round_number > 10, 1, 0)

### AM treated groups ####
DATA$am = ifelse(DATA$treatment == 0, 0, 1)

### Individual characteristics ####
tmpUnder = aggregate(DATA$understanding, by = list(DATA$participant), FUN = mean, na.rm = T)
colnames(tmpUnder) = c("participant","UNDERSTmean")
tmpPayoff = aggregate(DATA$payoff, by = list(DATA$participant), FUN = mean, na.rm = T)
colnames(tmpPayoff) = c("participant","PAYOFFmean")
tmpNLE = aggregate(DATA$NLE_payoff, by = list(DATA$participant), FUN = mean, na.rm = T)
colnames(tmpNLE) = c("participant","NLEmean")
tmpmerge1 = merge(DATA, tmpUnder, by ="participant")
tmpmerge2 = merge(tmpmerge1, tmpPayoff, by ="participant")
DATA = merge(tmpmerge2, tmpNLE, by ="participant")
rm("tmpUnder","tmpPayoff","tmpNLE","tmpmerge1","tmpmerge2")

### Rounds fixed effects ####
DATA$learn = DATA$round_number
DATA$learn[which(DATA$learn > 10)] = DATA$learn[which(DATA$learn > 10)] - 10

### Diverse variables ####
DATA$count = 1

## 1.2 - Creation of Dictators' choices dataset and variables ####
DATA_DC = filter(DATA, DATA$seq == 1 & DATA$am == 1)

### Ranks ####
tmpDATA_DC = DATA_DC %>%
  group_by(group_uid, round_number) %>%
  mutate(rank_tmp = if_else(all(min(extraction) == max(extraction)), "egalite", ""),
         rank_tmp2 = if_else(extraction == min(extraction), "min",
                             if_else(extraction == max(extraction), "max", "median"))) %>%
  mutate(rank = if_else(rank_tmp != "", rank_tmp, rank_tmp2)) %>%
  select(-rank_tmp, -rank_tmp2) %>%
  ungroup()
tmp <- pivot_wider(tmpDATA_DC, c(round_number, group_uid), values_from = extraction, names_from = rank, values_fn = unique)
tmpDATA_DC2 <- left_join(tmpDATA_DC, tmp, by = c("round_number", "group_uid"))
tmpDATA_DC3 = select(tmpDATA_DC2, -c(egalite, median))
DATA_DC = filter(tmpDATA_DC3, tmpDATA_DC3$approbation_group==0 & tmpDATA_DC3$dictator==1 & tmpDATA_DC3$rank != 'egalite')
DATA_DC$maxrank = ifelse(DATA_DC$rank == "max", 1, 0)
rm("tmp","tmpDATA_DC","tmpDATA_DC2","tmpDATA_DC3")

### Variables - optimum ####
DATA_DC$optimum = ifelse(DATA_DC$max>=4 & DATA_DC$min<=4, 12, 
                              ifelse(DATA_DC$max<4, DATA_DC$max*3, 
                                     DATA_DC$min*3))
### Variables - dictator's choice ####
DATA_DC$dict_opti = ifelse(DATA_DC$extraction_group_applied==DATA_DC$optimum, 1, 0)
DATA_DC$dict_overopti = ifelse(DATA_DC$extraction_group_applied>DATA_DC$optimum, 1, 0)
DATA_DC$dict_underopti = ifelse(DATA_DC$extraction_group_applied<DATA_DC$optimum, 1, 0)

### Variables - over-optimum dictator's choice ####
DATA_DC$dict_choice = ifelse(DATA_DC$dict_opti == 1, "Optimum", ifelse(DATA_DC$dict_overopti == 1, "Over optimum", "Under optimum"))
DATA_DC_OO = filter(DATA_DC, DATA_DC$dict_choice == "Over optimum")

                        # Does dictators choosing OO, chooses their own proposal ?

DATA_DC$ownchoice = ifelse(DATA_DC$dict_choice == "Over optimum" & DATA_DC$extcor == 3*DATA_DC$extraction, 1, 0)
sum(DATA_DC$ownchoice)

                        # Does dictators choosing OO, choosing the max ?

DATA_DC$maxchoice = ifelse(DATA_DC$dict_choice == "Over optimum" & DATA_DC$extcor == 3*DATA_DC$max, 1, 0)
sum(DATA_DC$maxchoice)

DATA_DC$OOchoice = ifelse(DATA_DC$dict_choice == "Over optimum" & DATA_DC$maxchoice == 1 & DATA_DC$ownchoice == 1, "maxown",
                          ifelse(DATA_DC$dict_choice == "Over optimum" & DATA_DC$maxchoice == 1 & DATA_DC$ownchoice == 0, "max",
                                 ifelse(DATA_DC$dict_choice == "Over optimum" & DATA_DC$maxchoice == 0 & DATA_DC$ownchoice == 1, "own",
                                        ifelse(DATA_DC$dict_choice == "Over optimum" & DATA_DC$maxchoice == 0 & DATA_DC$ownchoice == 0, "other", "NA"))))
freq(DATA_DC$OOchoice)

DATA_DC$OOchoicesum = fct_recode(DATA_DC$OOchoice, "max" = "maxown", "other" = "own")
freq(DATA_DC$OOchoicesum)

DATA_DC$OOmax = ifelse(DATA_DC$OOchoicesum == "max", 1, 0)
DATA_DC$OOother = ifelse(DATA_DC$OOchoicesum == "other", 1, 0)

## 1.3 - Creation of figures' datasets ####

### Figures 1 & 2 : treatment effect ####
DATA_FIG = data.frame(extgrp = DATA$extraction_group,
                      round = DATA$round_number,
                      treat = DATA$treatment,
                      extcor = DATA$extcor)

### Figure 3 : Barplot dictator ####
DATA_DC$dict_choice = ifelse(DATA_DC$dict_opti == 1, "Optimum", ifelse(DATA_DC$dict_overopti == 1, "Over optimum", "Under optimum"))
DATA_BAR = data.frame(table(DATA_DC$dict_choice,DATA_DC$rank))
DATA_BAR$percent = DATA_BAR$Freq / sum(DATA_BAR$Freq) * 100 
colnames(DATA_BAR) = c("Choice", "Rank", "Frequency", "Percent")

# 2 - ANALYSIS ---- ####

## 2.1 - Descriptive statistics ####

### Balance table ####

DATA_balance <- DATA %>%
  filter(treatment %in% c(0, 1, 2)) %>%
  mutate(across(c(svo_score, NLEmean, crt_score, nep_score, year_of_birth), as.numeric),
         across(c(gender, student, study_level), as.factor))


aggregated_data <- DATA %>%
  group_by(participant) %>%  # Group data by participant
  summarise(
    treatment = first(treatment),       # Assuming you want the first entry of treatment for each participant
    svo_score = mean(svo_score, na.rm = TRUE),  # Average SVO score, ignoring NA values
    NLEmean = mean(NLEmean, na.rm = TRUE),      # Average NLEmean, ignoring NA values
    crt_score = mean(crt_score, na.rm = TRUE),  # Average CRT score, ignoring NA values
    nep_score = mean(nep_score, na.rm = TRUE),  # Average NEP score, ignoring NA values
    year_of_birth = first(year_of_birth),       # Assuming you want the first entry of year_of_birth for each participant
    gender = first(gender),                     # Assuming you want the first entry of gender for each participant
    student = first(student),                   # Assuming you want the first entry of student for each participant
    study_level = first(study_level)            # Assuming you want the first entry of study level for each participant
  )

# Print the aggregated data
print(aggregated_data)

# Non parametric for continuous variables
kruskal.test(svo_score ~ treatment, data = aggregated_data)
kruskal.test(NLEmean ~ treatment, data = aggregated_data)
kruskal.test(crt_score ~ treatment, data = aggregated_data)
kruskal.test(nep_score ~ treatment, data = aggregated_data)
kruskal.test(year_of_birth ~ treatment, data = aggregated_data)
kruskal.test(study_level ~ treatment, data = aggregated_data)
# Parametric for continuous variables
anova_svo_score <- aov(svo_score ~ treatment, data = aggregated_data)
summary(anova_svo_score)
anova_NLEmean <- aov(NLEmean ~ treatment, data = aggregated_data)
summary(anova_NLEmean)
anova_crt_score <- aov(crt_score ~ treatment, data = aggregated_data)
summary(anova_crt_score)
anova_nep_score <- aov(nep_score ~ treatment, data = aggregated_data)
summary(anova_nep_score)
anova_year_of_birth <- aov(year_of_birth ~ treatment, data = aggregated_data)
summary(anova_year_of_birth)
anova_study_level <- aov(study_level ~ treatment, data = aggregated_data)
summary(anova_study_level)
# Non parametric for continuous variables
table_data <- table(DATA$treatment, DATA$gender)
fisher.test(table_data)
table_data <- table(DATA$treatment, DATA$student)
fisher.test(table_data)
table_data <- table(DATA$treatment, DATA$study_level)
fisher.test(table_data)
# Parametric for continuous variables
table_data <- table(DATA$treatment, DATA$gender)
chisq.test(table_data)
table_data <- table(DATA$treatment, DATA$student)
chisq.test(table_data)
table_data <- table(DATA$treatment, DATA$study_level)
chisq.test(table_data)


### Extractions ####
mean(DATA$extraction_group[which(DATA$am == 0 & DATA$seq == 0)])                                      # Baseline S1 = 17.76
mean(DATA$extraction_group[which(DATA$am == 0 & DATA$seq == 1)])                                      # Baseline S2 = 18.44

mean(DATA$extraction_group[which(DATA$am == 1 & DATA$seq == 0)])                                      # AM S1 = 18.25
mean(DATA$extraction_group[which(DATA$am == 1 & DATA$seq == 1)])                                      # AM S2 proposed = 16.75
mean(DATA$extraction_group[which(DATA$am == 1 & DATA$seq == 1 & DATA$approbation_group == 1)])        # AM S2 approved = 15.80
mean(DATA$extraction_group[which(DATA$am == 1 & DATA$seq == 1 & DATA$approbation_group == 0)])        # AM S2 rejected = 17.56
mean(DATA$extcor[which(DATA$am == 1 & DATA$seq == 1)])                                                # AM S2 realized = 15.16

mean(DATA$extraction_group[which(DATA$treatment == 1 & DATA$seq == 0)])                               # Majority S1 = 18.09
mean(DATA$extraction_group[which(DATA$treatment == 1 & DATA$seq == 1)])                               # Majority S2 proposed = 17.52
mean(DATA$extraction_group[which(DATA$treatment == 1 & DATA$seq == 1 & DATA$approbation_group == 1)]) # Majority S2 approved = 16.49
mean(DATA$extraction_group[which(DATA$treatment == 1 & DATA$seq == 1 & DATA$approbation_group == 0)]) # Majority S2 rejected = 20.02
mean(DATA$extcor[which(DATA$treatment == 1 & DATA$seq == 1)])                                         # Majority S2 realized = 16.33

mean(DATA$extraction_group[which(DATA$treatment == 2 & DATA$seq == 0)])                               # Unanimity S1 = 18.37
mean(DATA$extraction_group[which(DATA$treatment == 2 & DATA$seq == 1)])                               # Unanimity S2 proposed = 16.14
mean(DATA$extraction_group[which(DATA$treatment == 2 & DATA$seq == 1 & DATA$approbation_group == 1)]) # Unanimity S2 approved = 14.43
mean(DATA$extraction_group[which(DATA$treatment == 2 & DATA$seq == 1 & DATA$approbation_group == 0)]) # Unanimity S2 rejected = 16.79
mean(DATA$extcor[which(DATA$treatment == 2 & DATA$seq == 1)])                                         # Unanimity S2 realized = 14.24

sd(DATA$extraction_group[which(DATA$am == 0 & DATA$seq == 0)])                                      # Baseline S1 = 3.32
sd(DATA$extraction_group[which(DATA$am == 0 & DATA$seq == 1)])                                      # Baseline S2 = 3.52

sd(DATA$extraction_group[which(DATA$am == 1 & DATA$seq == 0)])                                      # AM S1 = 3.79
sd(DATA$extraction_group[which(DATA$am == 1 & DATA$seq == 1)])                                      # AM S2 proposed = 3.52
sd(DATA$extraction_group[which(DATA$am == 1 & DATA$seq == 1 & DATA$approbation_group == 1)])        # AM S2 approved = 3.35
sd(DATA$extraction_group[which(DATA$am == 1 & DATA$seq == 1 & DATA$approbation_group == 0)])        # AM S2 rejected = 3.46
sd(DATA$extcor[which(DATA$am == 1 & DATA$seq == 1)])                                                # AM S2 realized = 4.03

sd(DATA$extraction_group[which(DATA$treatment == 1 & DATA$seq == 0)])                               # Majority S1 = 3.74
sd(DATA$extraction_group[which(DATA$treatment == 1 & DATA$seq == 1)])                               # Majority S2 proposed = 3.75
sd(DATA$extraction_group[which(DATA$treatment == 1 & DATA$seq == 1 & DATA$approbation_group == 1)]) # Majority S2 approved = 3.50
sd(DATA$extraction_group[which(DATA$treatment == 1 & DATA$seq == 1 & DATA$approbation_group == 0)]) # Majority S2 rejected = 3.11
sd(DATA$extcor[which(DATA$treatment == 1 & DATA$seq == 1)])                                         # Majority S2 realized = 3.97

sd(DATA$extraction_group[which(DATA$treatment == 2 & DATA$seq == 0)])                               # Unanimity S1 = 3.84
sd(DATA$extraction_group[which(DATA$treatment == 2 & DATA$seq == 1)])                               # Unanimity S2 proposed = 3.21
sd(DATA$extraction_group[which(DATA$treatment == 2 & DATA$seq == 1 & DATA$approbation_group == 1)]) # Unanimity S2 approved = 2.52
sd(DATA$extraction_group[which(DATA$treatment == 2 & DATA$seq == 1 & DATA$approbation_group == 0)]) # Unanimity S2 rejected = 2.20
sd(DATA$extcor[which(DATA$treatment == 2 & DATA$seq == 1)])                                         # Unanimity S2 realized = 3.84 

sd(DATA_gr$extcor[which(DATA_gr$am == 0 & DATA_gr$seq == 0)])                                      # Baseline S1 = 3.32
sd(DATA_gr$extcor[which(DATA_gr$am == 0 & DATA_gr$seq == 1)])                                      # Baseline S2 = 3.52

sd(DATA_gr$extcor[which(DATA_gr$am == 1 & DATA_gr$seq == 0)])                                      # AM S1 = 3.79
sd(DATA_gr$extcor[which(DATA_gr$am == 1 & DATA_gr$seq == 1)])                                      # AM S2 proposed = 3.52
sd(DATA_gr$extcor[which(DATA_gr$am == 1 & DATA_gr$seq == 1 & DATA_gr$approbation_group == 1)])        # AM S2 approved = 3.35
sd(DATA_gr$extcor[which(DATA_gr$am == 1 & DATA_gr$seq == 1 & DATA_gr$approbation_group == 0)])        # AM S2 rejected = 3.46
sd(DATA_gr$extcor[which(DATA_gr$am == 1 & DATA_gr$seq == 1)])                                                # AM S2 realized = 4.03

sd(DATA_gr$extcor[which(DATA_gr$treatment == 1 & DATA_gr$seq == 0)])                               # Majority S1 = 3.74
sd(DATA_gr$extcor[which(DATA_gr$treatment == 1 & DATA_gr$seq == 1)])                               # Majority S2 proposed = 3.75
sd(DATA_gr$extcor[which(DATA_gr$treatment == 1 & DATA_gr$seq == 1 & DATA_gr$approbation_group == 1)]) # Majority S2 approved = 3.50
sd(DATA_gr$extcor[which(DATA_gr$treatment == 1 & DATA_gr$seq == 1 & DATA_gr$approbation_group == 0)]) # Majority S2 rejected = 3.11
sd(DATA_gr$extcor[which(DATA_gr$treatment == 1 & DATA_gr$seq == 1)])                                         # Majority S2 realized = 3.97

sd(DATA_gr$extcor[which(DATA_gr$treatment == 2 & DATA_gr$seq == 0)])                               # Unanimity S1 = 3.84
sd(DATA_gr$extcor[which(DATA_gr$treatment == 2 & DATA_gr$seq == 1)])                               # Unanimity S2 proposed = 3.21
sd(DATA_gr$extcor[which(DATA_gr$treatment == 2 & DATA_gr$seq == 1 & DATA_gr$approbation_group == 1)]) # Unanimity S2 approved = 2.52
sd(DATA_gr$extcor[which(DATA_gr$treatment == 2 & DATA_gr$seq == 1 & DATA_gr$approbation_group == 0)]) # Unanimity S2 rejected = 2.20
sd(DATA_gr$extcor[which(DATA_gr$treatment == 2 & DATA_gr$seq == 1)])   

### Disapprovals ####
                              # A minor correction has been done on 3 line which showed "egalite" and a value in 
                              # approbation_group causing a variation of 3 between approved and rejected 
count_OA = sum(DATA$count[which(DATA$seq == 1 & DATA$am == 1)]) # 960
Appr_OA = sum(DATA$count[which(DATA$seq == 1 & DATA$am == 1 & DATA$approbation_group == 1)]) # 444 => 447
Desapp_OA = sum(DATA$count[which(DATA$seq == 1 & DATA$am == 1 & DATA$approbation_group == 0)]) # 516 => 513
447 / count_OA * 100 # 46.25% => correction 46.56% of approval
513 / count_OA * 100 # 53.75% => correction 53.44% of approval

count_M = sum(DATA$count[which(DATA$seq == 1 & DATA$treatment == 1)]) # 420
Appr_M = sum(DATA$count[which(DATA$seq == 1 & DATA$treatment == 1 & DATA$approbation_group == 1)]) # 297 => 300
Desapp_M = sum(DATA$count[which(DATA$seq == 1 & DATA$treatment == 1 & DATA$approbation_group == 0)]) # 123 => 120
300 / count_M * 100 # 70.71% => correction 71.43% of approval
120 / count_M * 100 # 29.29% => correction 28.57% of approval

count_U = sum(DATA$count[which(DATA$seq == 1 & DATA$treatment == 2)]) # 420
Appr_U = sum(DATA$count[which(DATA$seq == 1 & DATA$treatment == 2 & DATA$approbation_group == 1)]) # 297
Desapp_U = sum(DATA$count[which(DATA$seq == 1 & DATA$treatment == 2 & DATA$approbation_group == 0)]) # 123
Appr_U / count_U * 100 # 27.22% of approval
Desapp_U / count_U * 100 # 72.78% of approval

### Optimality of dictators' choices ####
sum(DATA_DC$dict_opti) / sum(DATA_DC$dictator) * 100  # 80.7% of dictators do the OC
sum(DATA_DC$dict_overopti) / sum(DATA_DC$dictator) * 100  # 16.96% of dictators do over the OC
sum(DATA_DC$dict_underopti) / sum(DATA_DC$dictator) * 100  # 2.34% of dictators do under the OC

### Dictators' efficiency by rank ####
describeBy(DATA_DC$extcor, group = list(DATA_DC$rank), mat = T)
mean(DATA_DC$extcor)                                                 # Dictator's choice Overall = 14.54
mean(DATA_DC$extcor[which(DATA_DC$rank == "max")])                   # Maxrank Dictator's choice Overall = 15.87
mean(DATA_DC$extcor[which(DATA_DC$rank == "median")])                # Medianrank Dictator's choice Overall = 14.92
mean(DATA_DC$extcor[which(DATA_DC$rank == "min")])                   # Minrank Dictator's choice Overall = 13.23
sd(DATA_DC$extcor)                                                 # Dictator's choice Overall = 4.43
sd(DATA_DC$extcor[which(DATA_DC$rank == "max")])                   # Maxrank Dictator's choice Overall = 5.60
sd(DATA_DC$extcor[which(DATA_DC$rank == "median")])                # Medianrank Dictator's choice Overall = 4.09
sd(DATA_DC$extcor[which(DATA_DC$rank == "min")])                   # Minrank Dictator's choice Overall = 2.87

DATA_DC_M = filter(DATA_DC, DATA_DC$treatment == 1)
describeBy(DATA_DC_M$extcor, group = list(DATA_DC_M$rank), mat = T)
mean(DATA_DC_M$extcor)                                               # Dictator's choice under Majority = 15.75
mean(DATA_DC_M$extcor[which(DATA_DC_M$rank == "max")])               # Maxrank Dictator's choice under Majority = 15.2
mean(DATA_DC_M$extcor[which(DATA_DC_M$rank == "median")])            # Medianrank Dictator's choice under Majority = 17.4
mean(DATA_DC_M$extcor[which(DATA_DC_M$rank == "min")])               # Minrank Dictator's choice under Majority = 15.2
sd(DATA_DC_M$extcor)                                               # Dictator's choice under Majority = 4.84
sd(DATA_DC_M$extcor[which(DATA_DC_M$rank == "max")])               # Maxrank Dictator's choice under Majority = 4.31
sd(DATA_DC_M$extcor[which(DATA_DC_M$rank == "median")])            # Medianrank Dictator's choice under Majority = 5.44
sd(DATA_DC_M$extcor[which(DATA_DC_M$rank == "min")])               # Minrank Dictator's choice under Majority = 5.00

DATA_DC_U = filter(DATA_DC, DATA_DC$treatment == 2)
describeBy(DATA_DC_U$extcor, group = list(DATA_DC_U$rank), mat = T)
mean(DATA_DC_U$extcor)                                               # Dictator's choice under Unanimity = 14.18
mean(DATA_DC_U$extcor[which(DATA_DC_U$rank == "max")])               # Maxrank Dictator's choice under Unanimity = 16.09
mean(DATA_DC_U$extcor[which(DATA_DC_U$rank == "median")])            # Medianrank Dictator's choice under Unanimity = 13.96
mean(DATA_DC_U$extcor[which(DATA_DC_U$rank == "min")])               # Minrank Dictator's choice under Unanimity = 12.72
sd(DATA_DC_U$extcor)                                               # Dictator's choice under Unanimity = 4.24
sd(DATA_DC_U$extcor[which(DATA_DC_U$rank == "max")])               # Maxrank Dictator's choice under Unanimity = 5.98
sd(DATA_DC_U$extcor[which(DATA_DC_U$rank == "median")])            # Medianrank Dictator's choice under Unanimity = 3.05
sd(DATA_DC_U$extcor[which(DATA_DC_U$rank == "min")])               # Minrank Dictator's choice under Unanimity = 1.71

### Dictators' efficiency by optimality ####
mean(DATA_DC$extraction_group_applied
     [which(DATA_DC$dict_opti==1)])        # 13.35 in the 81%
mean(DATA_DC$extraction_group_applied[
  which(DATA_DC$dict_overopti==1)])        # 21.21 in the 17%
mean(DATA_DC$extraction_group_applied[
  which(DATA_DC$dict_opti==1 
        & DATA_DC$treatment == 1)])        # 15.10 in the 81%
mean(DATA_DC$extraction_group_applied[
  which(DATA_DC$dict_overopti==1 
        & DATA_DC$treatment == 1)])        # 21.43 in the 17%
mean(DATA_DC$extraction_group_applied[
  which(DATA_DC$dict_opti==1 
        & DATA_DC$treatment == 2)])        # 12.84 in the 81%
mean(DATA_DC$extraction_group_applied
     [which(DATA_DC$dict_overopti==1 
            & DATA_DC$treatment == 2)])    # 21.14 in the 17%

### Over-optimum Dicators' choices ####

                  # We want to identify if there is a difference between those who chose the max 
                  # possible and those who chose another over-optimum choice

OOmaxreg = glm(OOmax ~ UNDERSTmean + NLEmean + factor(rank), family=binomial(link=logit), data = DATA_DC)
summary(OOmaxreg) # Being median or min rank reduces significantly the probability of choosing the max proposal as dictator
OOmaxreg = glm(OOother ~ UNDERSTmean + NLEmean + factor(rank), family=binomial(link=logit), data = DATA_DC)
summary(OOmaxreg) # Doing understanding faults increase the probability of doing other Over-optimal choices while NLE reduces it

mean(DATA_DC$UNDERSTmean[which(DATA_DC$OOmax == 1)]) # 0.29
mean(DATA_DC$UNDERSTmean[which(DATA_DC$OOother == 1)]) # 0.50
mean(DATA_DC$NLEmean[which(DATA_DC$OOmax == 1)]) # 2.64
mean(DATA_DC$NLEmean[which(DATA_DC$OOother == 1)]) # 2.53

### Round 8 anomalies ####

DATA_R8 = filter(DATA, DATA$round_number > 5 & DATA$round_number < 10)
DATA_R8_agg = aggregate(DATA_R8$extraction_group, by = list(DATA_R8$round_number, DATA_R8$treatment, DATA_R8$group_uid), FUN = min)
DATA_R8_agg = DATA_R8_agg %>%
  rename(round_number = Group.1,
         treatment = Group.2,
         group_id = Group.3)

DATA_R8_agg$round_number = as.character(DATA_R8_agg$round_number)
class(DATA_R8_agg$round_number)
DATA_R8_agg$round_number[DATA_R8_agg$round_number==6] = "Round_6"
DATA_R8_agg$round_number[DATA_R8_agg$round_number==7] = "Round_7"
DATA_R8_agg$round_number[DATA_R8_agg$round_number==8] = "Round_8"
DATA_R8_agg$round_number[DATA_R8_agg$round_number==9] = "Round_9"

DATA_R8_agg = dcast(DATA_R8_agg, DATA_R8_agg$group_id + DATA_R8_agg$treatment ~ DATA_R8_agg$round_number, value.var = "x")

DATA_R8_agg = as.data.frame(DATA_R8_agg)
DATA_R8_agg$delta8 = DATA_R8_agg$Round_8 - DATA_R8_agg$Round_7
DATA_R8_agg$delta9 = DATA_R8_agg$Round_9 - DATA_R8_agg$Round_8

                              #### The anomalies are due to 4 groups extremely decreasing their extractions: 
                              #### 9t9fizkf_2, 9t9fizkf_6, lrgx3tnx_1 and lxcnsptj_4 including two of them 
                              #### coming back to the nash level following round

## 2.2 - Non-parametrical tests ####

### Difference between treatments S1 ####
DATA_PRE = filter(DATA, DATA$seq == 0)
#dunn.test(formula = extcor ~ treatment, p.adjust.method = "bonferroni", data = DATA) # ns p < 0.01

CTS1 = DATA$extcor[which(DATA$seq == 0 & DATA$am == 0)]
T1S2 = DATA$extcor[which(DATA$seq == 1 & DATA$treatment == 1)]
T2S2 = DATA$extcor[which(DATA$seq == 1 & DATA$treatment == 2)]
MannKendall(CTS1)
MannKendall(T1S2)
MannKendall(T2S2) # No significant trend for all three treatments

### Evolution between sequences ####
CTS2 = DATA$extcor[which(DATA$seq == 1 & DATA$am == 0)]
AMS1 = DATA$extcor[which(DATA$seq == 0 & DATA$am == 1)]
AMS2 = DATA$extcor[which(DATA$seq == 1 & DATA$am == 1)]
wilcox.test(CTS1, CTS2, paired = T) # ***   The difference could be explained by a starting effect in round 1 and 2 we can see on all treatments
wilcox.test(AMS1, AMS2, paired = T) # ***

### Starting effect ####

START = DATA$extcor[which(DATA$round < 3)]
S1_woSTART = DATA$extcor[which(DATA$round > 2 & DATA$seq == 0)]
ks.test(START, S1_woSTART) # ***
wilcox.test(START, S1_woSTART) # ***

### S1 versus Nash Equilibrium ####
S1 = DATA$extcor[which(DATA$seq == 0)]
wilcox.test(S1, mu = 18, paired = F, alternative = "t") # ns

### Unanimity versus Majority ####

ks.test(T1S2, T2S2) # ***
wilcox.test(T1S2, T2S2) # ***

### Proposals S2 versus Realized S1 ####
T1S2_prop_app = DATA$extraction_group[which(DATA$seq == 1 & DATA$treatment == 1 & DATA$approbation_group == 1)]
T1S2_prop_rej = DATA$extraction_group[which(DATA$seq == 1 & DATA$treatment == 1 & DATA$approbation_group == 0)]
T2S2_prop_app = DATA$extraction_group[which(DATA$seq == 1 & DATA$treatment == 2 & DATA$approbation_group == 1)]
T2S2_prop_rej = DATA$extraction_group[which(DATA$seq == 1 & DATA$treatment == 2 & DATA$approbation_group == 0)]
ks.test(T1S2_prop_app, S1) # ***
ks.test(T1S2_prop_rej, S1) # ***
ks.test(T2S2_prop_app, S1) # ***
ks.test(T2S2_prop_rej, S1) # ***
wilcox.test(T1S2_prop_app, S1) # ***
wilcox.test(T1S2_prop_rej, S1) # ***
wilcox.test(T2S2_prop_app, S1) # ***
wilcox.test(T2S2_prop_rej, S1) # ***

### Rejected versus Dictators' decisions ####
T1S2_dict = DATA$extcor[which(DATA$seq == 1 & DATA$treatment == 1 & DATA$approbation_group == 0)]
wilcox.test(T1S2_dict, T1S2_prop_rej, paired = T)
T2S2_dict = DATA$extcor[which(DATA$seq == 1 & DATA$treatment == 2 & DATA$approbation_group == 0)]
wilcox.test(T2S2_dict, T2S2_prop_rej, paired = T)

##### Approved versus Dictators' decisions ####
ks.test(T1S2_dict, T1S2_prop_app) #***
ks.test(T2S2_dict, T2S2_prop_app) #***
wilcox.test(T1S2_dict, T1S2_prop_app) #*    - Strong difference between rank-sum and distribution tests
wilcox.test(T2S2_dict, T2S2_prop_app) #***

## 2.3 - Difference-in-differences estimation ####
                                              # Fixed effects on Groups, Rounds and Sequence
                                              # Standard error clustered on Groups

### AM dictator effect ####
reg_AM = feols(extcor ~ seq*am | group_uid + learn + seq, data = DATA, vcov = ~group_uid)
etable(reg_AM, signifCode = c("***"=0.005, "**"=0.01, "*"=0.05))
### AM MAJ dictator effect ####
DATA_MAJ = filter(DATA, DATA$treatment != 2)
reg_MAJ = feols(extcor ~ seq*am | group_uid + learn + seq, data = DATA_MAJ, vcov = ~group_uid)
etable(reg_MAJ, signifCode = c("***"=0.01, "**"=0.05, "*"=0.10))
### AM UNA dictator effect ####
DATA_UNA = filter(DATA, DATA$treatment != 1)
reg_UNA = feols(extcor ~ seq*am | group_uid + learn + seq, data = DATA_UNA, vcov = ~group_uid)
etable(reg_UNA, signifCode = c("***"=0.01, "**"=0.05, "*"=0.10))
### DiD synthesis ####
etable(reg_AM, reg_MAJ, reg_UNA, signifCode = c("***"=0.01, "**"=0.05, "*"=0.10))

## 2.3B - WORK IN PROGRESS - DiD si mod?le Yrg ####

reshaped_data <- DATA %>%
  # Assuming DATA has the following relevant columns: round_number, group_uid, participant, extraction
  group_by(round_number, group_uid) %>%
  mutate(participant_id = paste("Participant", row_number(), sep = "_")) %>%
  ungroup() %>%
  pivot_wider(
    id_cols = c(round_number, group_uid), # Identifying columns
    names_from = participant_id,          # Column to spread
    values_from = extraction,            # Values to fill with
    values_fill = list(extraction = NA)  # Fill missing extractions with NA
  )

analysis_results <- reshaped_data %>%
  # Calculate the sum of extractions for each row
  mutate(total_extraction = Participant_1 + Participant_2 + Participant_3,
         # Check if all extractions are below 4
         all_below_4 = Participant_1 < 4 & Participant_2 < 4 & Participant_3 < 4) %>%
  # Summarise the count of how many times conditions are met
  summarise(
    count_total_below_12 = sum(total_extraction < 12, na.rm = TRUE),
    count_all_below_4 = sum(all_below_4, na.rm = TRUE)
  )

# Print the results
print(analysis_results)




DATA_gr_stage1 = aggregate(DATA$extraction_group, by = list(DATA$round_number, DATA$group_uid, DATA$treatment), FUN = mean)
colnames(DATA_gr_stage1) = c("round_number", "group_uid", "treatment", "extraction_stage1")

# Histogram of extraction_stage1
ggplot(DATA_gr_stage1, aes(x = extraction_stage1)) +
  geom_histogram(binwidth = 1, fill = "blue", color = "black") +
  ggtitle("Histogram of extraction_stage1") +
  xlab("extraction_stage1") +
  ylab("Frequency")
total_count = nrow(DATA_gr_stage1[DATA_gr_stage1$extraction_stage1 < 12, ])
total_count
nrow(DATA_gr_stage1)
# Group by group_uid and count instances where extraction_stage1 < 10
group_analysis = DATA_gr_stage1 %>%
  filter(extraction_stage1 < 12) %>%
  group_by(group_uid) %>%
  summarise(count = n(), .groups = 'drop')
# Viewing the results
print(group_analysis)


DATA_gr = aggregate(DATA$extcor, by = list(DATA$round_number, DATA$group_uid, DATA$treatment), FUN = mean)
colnames(DATA_gr) = c("round_number", "group_uid", "treatment", "extraction_stage1")
DATA_gr$seq = ifelse(DATA_gr$round_number > 10, 1, 0)
DATA_gr$learn = DATA_gr$round_number
DATA_gr$learn[which(DATA_gr$learn > 10)] = DATA_gr$learn[which(DATA_gr$learn > 10)] - 10
DATA_gr$am = ifelse(DATA_gr$treatment == 0, 0, 1)

### AM dictator effect ####
reg_AM_gr = feols(extcor ~ seq*am | group_uid + learn + seq, data = DATA_gr, vcov = ~group_uid)
etable(reg_AM_gr, signifCode = c("***"=0.01, "**"=0.05, "*"=0.10))
### AM MAJ dictator effect ####
DATA_MAJ_gr = filter(DATA_gr, DATA_gr$treatment != 2)
reg_MAJ_gr = feols(extcor ~ seq*am | group_uid + learn + seq, data = DATA_MAJ_gr, vcov = ~group_uid)
etable(reg_MAJ_gr, signifCode = c("***"=0.01, "**"=0.05, "*"=0.10))
### AM UNA dictator effect ####
DATA_UNA_gr = filter(DATA_gr, DATA_gr$treatment != 1)
reg_UNA_gr = feols(extcor ~ seq*am | group_uid + learn + seq, data = DATA_UNA_gr, vcov = ~group_uid)
etable(reg_UNA_gr, signifCode = c("***"=0.01, "**"=0.05, "*"=0.10))
### DiD synthesis ####
etable(reg_AM_gr, reg_MAJ_gr, reg_UNA_gr, signifCode = c("***"=0.01, "**"=0.05, "*"=0.10))


## 2.4. Logit estimation on dictator's choices optimality ####
myreg=glm(dict_overopti ~ UNDERSTmean + extraction_group + maxrank + factor(group_uid) + factor(learn), family=binomial(link=logit), data = DATA_DC)
summary(myreg)

# 3 - FIGURES ---- ####

## 3.1 - Figure 1 ####

windows(600,600)
DATA_FIG$am = ifelse(DATA_FIG$treat == 2, 1, ifelse(DATA_FIG$treat == 1, 1, 0))
DF = aggregate(DATA_FIG$extcor,by=list(DATA_FIG$round,DATA_FIG$am),function(x){mean(x,na.rm=T)})
DFsd = aggregate(DATA_FIG$extcor,by=list(DATA_FIG$round,DATA_FIG$am),function(x){sd(x,na.rm=T)})
colnames(DF)=c("SEQ","GRP","EXTR");colnames(DFsd)=c("SEQ","GRP","EXTR")

plot(y=DF$EXTR[which(DF$GRP==0)],x=DF$SEQ[which(DF$GRP==0)],xlim=c(1,20), lwd=2,
     main=expression(Effect ~ of ~ delegation ~ AM ~ on ~ extractions),ylim=c(10,25),
     xaxs="i",col="firebrick1",type="o",pch=16,xlab="Rounds",ylab="Realized extractions by group", cex.axis = 1.3, cex.lab = 1.5, cex.main = 1.5)
#polygon(x = c(DF$SEQ[which(DF$GRP==0)], rev(DF$SEQ[which(DF$GRP==0)])), 
        #y=c(DF$EXTR[which(DF$GRP==0)] - DFsd$EXTR[which(DFsd$GRP==0)],rev(DF$EXTR[which(DF$GRP==0)] + DFsd$EXTR[which(DFsd$GRP==0)])),
        #col=adjustcolor("firebrick1",alpha.f = 0.08),border = NA)

points(y=DF$EXTR[which(DF$GRP==1)],x=DF$SEQ[which(DF$GRP==1)],ylim=c(0,10),col="orange",type="o",pch=17, lwd=2)
#polygon(x = c(DF$SEQ[which(DF$GRP==1)], rev(DF$SEQ[which(DF$GRP==1)])), 
        #y=c(DF$EXTR[which(DF$GRP==1)] - DFsd$EXTR[which(DFsd$GRP==1)],rev(DF$EXTR[which(DF$GRP==1)] + DFsd$EXTR[which(DFsd$GRP==1)])),
        #col=adjustcolor("orange",alpha.f = 0.08),border = NA)

abline(v=10.5,lty=3,col="black", lwd=3)
abline(h=18,lty=3,col="black")
abline(h=12,lty=3,col="black")
text(1.78,18.3, "Nash", col="black", cex = 1.20)
text(2.08,12.3, "Optimum", col="black", cex = 1.20)
legend("topright",legend = c("Unregulated","Delegation mechanism"),lty=c(1,1),col=c("firebrick1","orange"),bty = "n",pch=c(16,17), cex=1.3)
text(5.6,10,"Phase 1",col="black",adj=0.5,cex=1.5)
#text(5.6,10,"WITHOUT TREATEMENT",col="black",adj=0.5,cex=1.5)
text(15.4,10,"Phase 2",col="black",adj=0.5,cex=1.5)
#text(15.4,10,"WITH TREATEMENT",col="black",adj=0.5,cex=1.5)


## 3.2 - Figure 2 ####

windows(600,600)
DF = aggregate(DATA_FIG$extcor,by=list(DATA_FIG$round,DATA_FIG$treat),function(x){mean(x,na.rm=T)})
DFsd = aggregate(DATA_FIG$extcor,by=list(DATA_FIG$round,DATA_FIG$treat),function(x){sd(x,na.rm=T)})
colnames(DF)=c("SEQ","GRP","EXTR");colnames(DFsd)=c("SEQ","GRP","EXTR")

plot(y=DF$EXTR[which(DF$GRP==0)],x=DF$SEQ[which(DF$GRP==0)],xlim=c(1,20),ylim=c(10,25), lwd=2,
     main=expression(Effect ~ of ~ delegation ~ AM ~ by ~ voting ~ rule),
     col="firebrick1",type="o",pch=16,xaxs="i",xlab="Rounds",ylab="Realized extractions by group", cex.axis = 1.3, cex.lab = 1.5, cex.main = 1.5)
#polygon(x = c(DF$SEQ[which(DF$GRP==0)], rev(DF$SEQ[which(DF$GRP==0)])), 
       # y=c(DF$EXTR[which(DF$GRP==0)] - DFsd$EXTR[which(DFsd$GRP==0)],rev(DF$EXTR[which(DF$GRP==0)] + DFsd$EXTR[which(DFsd$GRP==0)])),
       # col=adjustcolor("firebrick1",alpha.f = 0.08),border = NA)

points(y=DF$EXTR[which(DF$GRP==1)],x=DF$SEQ[which(DF$GRP==1)],ylim=c(0,10),col="royalblue",type="o",pch=17, lwd=2)
#polygon(x = c(DF$SEQ[which(DF$GRP==1)], rev(DF$SEQ[which(DF$GRP==1)])), 
       # y=c(DF$EXTR[which(DF$GRP==1)] - DFsd$EXTR[which(DFsd$GRP==1)],rev(DF$EXTR[which(DF$GRP==1)] + DFsd$EXTR[which(DFsd$GRP==1)])),
       # col=adjustcolor("darkblue",alpha.f = 0.08),border = NA)

points(y=DF$EXTR[which(DF$GRP==2)],x=DF$SEQ[which(DF$GRP==2)],ylim=c(0,10),col="forestgreen",type="o",pch=15, lwd=2)
#polygon(x = c(DF$SEQ[which(DF$GRP==2)], rev(DF$SEQ[which(DF$GRP==2)])), 
       # y=c(DF$EXTR[which(DF$GRP==2)] - DFsd$EXTR[which(DFsd$GRP==2)],rev(DF$EXTR[which(DF$GRP==2)] + DFsd$EXTR[which(DFsd$GRP==2)])),
       # col=adjustcolor("forestgreen",alpha.f = 0.08),border = NA)

abline(v=10.5,lty=3,col="black", lwd=3)
abline(h=18,lty=3,col="black")
abline(h=12,lty=3,col="black")
text(1.78,18.3, "Nash", col="black", cex = 1.20)
text(2.08,12.3, "Optimum", col="black", cex = 1.20)
legend("topright",legend = c("Unregulated","Majority","Unanimity"),lty=c(1,1,1),col=c("firebrick1","royalblue","forestgreen"),bty = "n",pch=c(16,17,15),cex=1.3)
text(5.6,10,"Phase 1",col="black",adj=0.5,cex=1.5)
#text(5.6,10,"WITHOUT TREATEMENT",col="black",adj=0.5,cex=1.5)
text(15.4,10,"Phase 2",col="black",adj=0.5,cex=1.5)
#text(15.4,10,"WITH TREATEMENT",col="black",adj=0.5,cex=1.5)

## 3.3 - Figure X ####

#Frequency of dictators' implementations

DATA_DICT = DATA %>%
  filter(DATA$seq == 1 & DATA$am == 1)

Approval_grp = aggregate(DATA_DICT$approbation_group, by = list(DATA_DICT$treatment, DATA_DICT$group_uid), FUN = sum)
colnames(Approval_grp) = c("treatment", "group_uid", "nb_approval")
Approval_grp$nb_approval = Approval_grp$nb_approval / 3
freq(Approval_grp$nb_approval)

windows(500, 300)
par(mfrow=c(1,2))
hist(Approval_grp$nb_approval[which(Approval_grp$treatment == 1)], breaks = seq(0, 10, 1), 
     include.lowest = T, main = "", xlab = "",  ylab = "",
     col="lightblue", ylim=c(0,10), cex.axis = 1.5, cex.lab = 1.5, cex.main = 2)
polygon(x = c(5,5,10,10), y = c(0,50,50,0), col="grey95", border = NA)
polygon(x = c(9,9,10,10), y = c(0,50,50,0), col="grey85", border = NA)
par(new=T)
hist(Approval_grp$nb_approval[which(Approval_grp$treatment == 1)], breaks = seq(0, 10, 1), 
     include.lowest = T, main = "", xlab = "Frequency of approval",  ylab = "Number of groups",
     col="lightblue", ylim=c(0,10), cex.axis = 1.5, cex.lab = 1.5, cex.main = 2)
text(5.3,9.2, "71 % of groups", col="black", cex = 1.3, srt = 90)
text(9.3,9.2, "43 % of groups", col="black", cex = 1.3, srt = 90)
clip(x1 = 0, x2 = 10, y1 = 0, y2 = 11)
abline(v=5,lty=2,col="grey")
abline(v=9,lty=2,col="black")
box()
hist(Approval_grp$nb_approval[which(Approval_grp$treatment == 2)], breaks = seq(0, 10, 1), 
     include.lowest = T, main = "", xlab = "", ylab = "", 
     col="lightgreen", ylim=c(0,10), cex.axis = 1.5, cex.lab = 1.5, cex.main = 1.5)
polygon(x = c(5,5,0,0), y = c(0,50,50,0), col="grey95", border = NA)
polygon(x = c(1,1,0,0), y = c(0,50,50,0), col="grey85", border = NA)
par(new=T)
hist(Approval_grp$nb_approval[which(Approval_grp$treatment == 2)], breaks = seq(0, 10, 1), 
     include.lowest = T, main = "", xlab = "Frequency of approval", ylab = "", 
     col="lightgreen", ylim=c(0,10), cex.axis = 1.5, cex.lab = 1.5, cex.main = 1.5)
text(4.7,9.2, "83 % of groups", col="black", cex = 1.3, srt = 90)
text(0.7,9.2, "44 % of groups", col="black", cex = 1.3, srt = 90)
legend("topright", c("Majority", "Unanimity"), fill=c("lightblue", "lightgreen"), 
       bty="n", cex = 1.6)
clip(x1 = 0, x2 = 10, y1 = 0, y2 = 11)
abline(v=1,lty=2,col="black")
abline(v=5,lty=2,col="grey")
box()
# Unanimity : 44.4% of groups never approved / 83.3% of groups approved less or equal to 50% of the time
# Majority : 42.9% of groups never disapproved / 71.4% of groups approved more or equal to 50% of the time


## 3.4 - Figure 3 ####

windows(500,700)
COL = c(adjustcolor("forestgreen",alpha.f = 1),adjustcolor("orange",alpha.f = 1),adjustcolor("firebrick",alpha.f = 1))
BP = DATA_BAR[,c(1,2,4)]
BP1 = reshape2::dcast(BP,Rank~Choice)
BP1 = as.matrix(BP1)
BP2 = BP1[c(3,2,1),]
colnames(BP2) = c("Rank","Optimal choice (OC)","Above the OC","Below the OC")
barplot(as.matrix(BP2)[,-1],ylim=c(0,100),col=COL,ylab="Percent of delegates (%)", xlab = "Delegates' choice",yaxt = "n", cex.lab = 1.5)
legend("topright",c("Proposed the Min","Intermediate","Proposed the Max"),col=COL,bty="n",cex=1.5,pch=15)
abline(h=seq(0,100,20),col="grey",lty=2)
barplot(as.matrix(BP2)[,-1],ylim=c(0,100),col=COL,ylab="", add=T, cex.axis = 1.3)
title(main = "")
box()

