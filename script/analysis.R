############################################################
# # Final Project: Financial Distress and Household Risk-Taking Behavior
#
# Research question:
# Does prior financial distress predict more conservative
# household investment behavior?
#
# Main contribution:
# This paper studies revealed financial behavior rather than
# self-reported risk preferences.
############################################################


############
# 0. Setup
############

rm(list = ls())
set.seed(123)

required_packages <- c(
  "tidyverse", "janitor", "skimr", "survey", "broom",
  "ggplot2", "scales", "knitr", "kableExtra"
)

missing_packages <- required_packages[
  !(required_packages %in% installed.packages()[, "Package"])
]

if (length(missing_packages) > 0) {
  install.packages(missing_packages)
}

library(tidyverse)
library(janitor)
library(skimr)
library(survey)
library(broom)
library(ggplot2)
library(scales)
library(knitr)
library(kableExtra)

options(scipen = 999)
options(survey.lonely.psu = "adjust")

dir.create("output", showWarnings = FALSE, recursive = TRUE)


##################
# 1. Load data
###################

scf_raw <- read_csv("Survey of Consumer Finances.csv", show_col_types = FALSE)

# Inspect raw data
print(glimpse(scf_raw))
write_csv(tibble(variable_name = names(scf_raw)), "output/scf_variable_names.csv")


###############################
# 2. Select project variables
###############################

scf <- scf_raw %>%
  select(
    Y1, YY1, WGT,
    HSTOCKS, STOCKS, HEQUITY, EQUITY, YESFINRISK, NOFINRISK,
    NETWORTH, INCOME, DEBT, LEVRATIO, DEBT2INC,
    LATE, LATE60, BNKRUPLAST5, FORECLLAST5,
    AGE, EDUC, EDCL, MARRIED, KIDS, LF, RACECL
  )


########################################
# 3. Clean data and construct variables
########################################

analysis_df <- scf %>%
  mutate(
    # Outcomes
    stock_participation = if_else(HSTOCKS == 1, 1, 0),
    equity_participation = if_else(HEQUITY == 1, 1, 0),
    willing_fin_risk = if_else(YESFINRISK == 1, 1, 0),
    no_fin_risk = if_else(NOFINRISK == 1, 1, 0),

    # Prior-loss / financial distress proxies
    negative_networth = if_else(NETWORTH < 0, 1, 0),
    low_networth = if_else(NETWORTH < median(NETWORTH, na.rm = TRUE), 1, 0),
    late_payment = if_else(LATE == 1, 1, 0),
    late60_payment = if_else(LATE60 == 1, 1, 0),
    bankruptcy5 = if_else(BNKRUPLAST5 == 1, 1, 0),
    foreclosure5 = if_else(FORECLLAST5 == 1, 1, 0),

    # Main composite prior-loss proxy
    prior_loss_proxy = if_else(
      negative_networth == 1 |
        late_payment == 1 |
        late60_payment == 1 |
        bankruptcy5 == 1 |
        foreclosure5 == 1,
      1, 0
    ),

    # Financial controls
    ln_income = log1p(pmax(INCOME, 0)),
    ln_debt = log1p(pmax(DEBT, 0)),
    ihs_networth = asinh(NETWORTH),

    # Demographic controls
    age = AGE,
    age_sq = AGE^2,
    education_cat = factor(EDCL),
    married_cat = factor(MARRIED),
    race_cat = factor(RACECL),
    labor_force = factor(LF)
  ) %>%
  drop_na(
    stock_participation,
    equity_participation,
    willing_fin_risk,
    prior_loss_proxy,
    negative_networth,
    late_payment,
    bankruptcy5,
    foreclosure5,
    ln_income,
    ln_debt,
    ihs_networth,
    age,
    age_sq,
    education_cat,
    married_cat,
    KIDS,
    labor_force,
    race_cat,
    WGT
  )

print(glimpse(analysis_df))
skim(analysis_df)


##############################
# 4. Descriptive statistics
##############################

desc_table_clean <- tibble(
  Statistic = c(
    "Observations",
    "Stock participation",
    "Equity participation",
    "Willing to take financial risk",
    "Prior-loss proxy",
    "Negative net worth",
    "Late payment",
    "Bankruptcy in past 5 years",
    "Foreclosure in past 5 years",
    "Mean income",
    "Median income",
    "Mean net worth",
    "Median net worth",
    "Mean age"
  ),
  Value = c(
    nrow(analysis_df),
    mean(analysis_df$stock_participation, na.rm = TRUE),
    mean(analysis_df$equity_participation, na.rm = TRUE),
    mean(analysis_df$willing_fin_risk, na.rm = TRUE),
    mean(analysis_df$prior_loss_proxy, na.rm = TRUE),
    mean(analysis_df$negative_networth, na.rm = TRUE),
    mean(analysis_df$late_payment, na.rm = TRUE),
    mean(analysis_df$bankruptcy5, na.rm = TRUE),
    mean(analysis_df$foreclosure5, na.rm = TRUE),
    mean(analysis_df$INCOME, na.rm = TRUE),
    median(analysis_df$INCOME, na.rm = TRUE),
    mean(analysis_df$NETWORTH, na.rm = TRUE),
    median(analysis_df$NETWORTH, na.rm = TRUE),
    mean(analysis_df$age, na.rm = TRUE)
  )
) %>%
  mutate(
    Value = case_when(
      Statistic == "Observations" ~ comma(Value, accuracy = 1),
      Statistic %in% c(
        "Stock participation", "Equity participation",
        "Willing to take financial risk", "Prior-loss proxy",
        "Negative net worth", "Late payment",
        "Bankruptcy in past 5 years", "Foreclosure in past 5 years"
      ) ~ percent(Value, accuracy = 0.1),
      Statistic %in% c("Mean income", "Median income", "Mean net worth", "Median net worth") ~
        dollar(Value, accuracy = 1),
      TRUE ~ number(Value, accuracy = 0.01)
    )
  )

write_csv(desc_table_clean, "output/descriptive_statistics.csv")

desc_table_clean %>%
  kable(
    format = "latex",
    booktabs = TRUE,
    caption = "Descriptive Statistics",
    align = c("l", "r"),
    escape = TRUE
  ) %>%
  kable_styling(
    latex_options = c("hold_position"),
    full_width = FALSE,
    font_size = 10
  ) %>%
  save_kable("output/descriptive_statistics.tex")


################################################
# 5. Risk-taking by prior-loss proxy and figure
################################################

risk_by_loss <- analysis_df %>%
  group_by(prior_loss_proxy) %>%
  summarise(
    Observations = n(),
    stock_rate = mean(stock_participation, na.rm = TRUE),
    equity_rate = mean(equity_participation, na.rm = TRUE),
    willing_fin_risk_rate = mean(willing_fin_risk, na.rm = TRUE),
    median_income = median(INCOME, na.rm = TRUE),
    median_networth = median(NETWORTH, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    loss_group = if_else(prior_loss_proxy == 1, "Prior-loss proxy", "No prior-loss proxy")
  )

risk_by_loss_clean <- risk_by_loss %>%
  transmute(
    `Prior-loss proxy` = loss_group,
    Observations = comma(Observations),
    `Stock participation` = percent(stock_rate, accuracy = 0.1),
    `Equity participation` = percent(equity_rate, accuracy = 0.1),
    `Willing to take financial risk` = percent(willing_fin_risk_rate, accuracy = 0.1),
    `Median income` = dollar(median_income, accuracy = 1),
    `Median net worth` = dollar(median_networth, accuracy = 1)
  )

write_csv(risk_by_loss_clean, "output/risk_by_loss_proxy.csv")

risk_by_loss_clean %>%
  kable(
    format = "latex",
    booktabs = TRUE,
    caption = "Risk-Taking Outcomes by Prior-Loss Proxy",
    align = c("l", "r", "r", "r", "r", "r", "r"),
    escape = TRUE
  ) %>%
  kable_styling(
    latex_options = c("hold_position", "scale_down"),
    full_width = FALSE,
    font_size = 9
  ) %>%
  save_kable("output/risk_by_loss_proxy.tex")

plot_stock_loss <- ggplot(
  risk_by_loss,
  aes(x = loss_group, y = stock_rate)
) +
  geom_col() +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(
    title = "Stock Participation by Prior-Loss Proxy",
    x = "",
    y = "Share owning stocks",
    caption = "Source: Survey of Consumer Finances. Prior-loss proxy includes negative net worth, late payment, bankruptcy, or foreclosure."
  ) +
  theme_minimal()

ggsave(
  "output/stock_participation_by_loss_proxy.png",
  plot_stock_loss,
  width = 7,
  height = 5,
  dpi = 300
)


#######################
# 6. Survey design
#######################

scf_design <- svydesign(
  ids = ~1,
  weights = ~WGT,
  data = analysis_df
)


##########################
# 7. Econometric models
##########################

# Model 1: simple relationship
model_stock_1 <- svyglm(
  stock_participation ~ prior_loss_proxy,
  design = scf_design,
  family = quasibinomial()
)

# Model 2: demographic controls
model_stock_2 <- svyglm(
  stock_participation ~ prior_loss_proxy +
    age + age_sq + education_cat + married_cat + KIDS + labor_force + race_cat,
  design = scf_design,
  family = quasibinomial()
)

# Model 3: preferred full model
model_stock_3 <- svyglm(
  stock_participation ~ prior_loss_proxy +
    ln_income + ihs_networth + ln_debt +
    age + age_sq + education_cat + married_cat + KIDS + labor_force + race_cat,
  design = scf_design,
  family = quasibinomial()
)

# Model 4: mechanism model with distress components
# Negative net worth is not included because ihs_networth already controls for net worth.
model_stock_4_fixed <- svyglm(
  stock_participation ~ late_payment + bankruptcy5 + foreclosure5 +
    ln_income + ihs_networth + ln_debt +
    age + age_sq + education_cat + married_cat + KIDS + labor_force + race_cat,
  design = scf_design,
  family = quasibinomial()
)

# Alternative outcome 1: broad equity participation
model_equity <- svyglm(
  equity_participation ~ prior_loss_proxy +
    ln_income + ihs_networth + ln_debt +
    age + age_sq + education_cat + married_cat + KIDS + labor_force + race_cat,
  design = scf_design,
  family = quasibinomial()
)

# Alternative outcome 2: self-reported willingness to take financial risk
model_risktol <- svyglm(
  willing_fin_risk ~ prior_loss_proxy +
    ln_income + ihs_networth + ln_debt +
    age + age_sq + education_cat + married_cat + KIDS + labor_force + race_cat,
  design = scf_design,
  family = quasibinomial()
)

summary(model_stock_1)
summary(model_stock_2)
summary(model_stock_3)
summary(model_stock_4_fixed)
summary(model_equity)
summary(model_risktol)


##################################################
# 8. Predicted probabilities from preferred model
##################################################

pred_data_no_loss <- analysis_df %>%
  mutate(prior_loss_proxy = 0)

pred_data_loss <- analysis_df %>%
  mutate(prior_loss_proxy = 1)

pred_no_loss <- predict(model_stock_3, newdata = pred_data_no_loss, type = "response")
pred_loss <- predict(model_stock_3, newdata = pred_data_loss, type = "response")

predicted_prob_table <- tibble(
  Group = c("No prior-loss proxy", "Prior-loss proxy"),
  `Predicted probability of stock ownership` = c(
    mean(pred_no_loss, na.rm = TRUE),
    mean(pred_loss, na.rm = TRUE)
  )
) %>%
  mutate(
    `Predicted probability of stock ownership` =
      percent(`Predicted probability of stock ownership`, accuracy = 0.1)
  )

write_csv(predicted_prob_table, "output/predicted_probabilities_stock.csv")

predicted_prob_table %>%
  kable(
    format = "latex",
    booktabs = TRUE,
    caption = "Predicted Probability of Stock Ownership",
    align = c("l", "r"),
    escape = TRUE
  ) %>%
  kable_styling(
    latex_options = c("hold_position"),
    full_width = FALSE,
    font_size = 10
  ) %>%
  save_kable("output/predicted_probabilities_stock.tex")


#############################################
# 9. Main coefficient interpretation table
#############################################

main_coef <- tidy(model_stock_3) %>%
  filter(term == "prior_loss_proxy") %>%
  transmute(
    Variable = "Prior-loss proxy",
    Estimate = round(estimate, 3),
    `Std. Error` = round(std.error, 3),
    `p-value` = round(p.value, 3),
    `Odds Ratio` = round(exp(estimate), 3),
    Interpretation = if_else(
      exp(estimate) < 1,
      "Associated with lower odds of stock ownership",
      "Associated with higher odds of stock ownership"
    )
  )

write_csv(main_coef, "output/main_coefficient_interpretation.csv")

main_coef %>%
  kable(
    format = "latex",
    booktabs = TRUE,
    caption = "Main Coefficient Interpretation",
    align = c("l", "r", "r", "r", "r", "l"),
    escape = TRUE
  ) %>%
  kable_styling(
    latex_options = c("hold_position", "scale_down"),
    full_width = FALSE,
    font_size = 9
  ) %>%
  save_kable("output/main_coefficient_interpretation.tex")


###################################################
# 10. Export regression table from model results
###################################################

library(broom)
library(dplyr)
library(tidyr)
library(stringr)
library(knitr)
library(kableExtra)

# Function to add significance stars
stars <- function(p) {
  case_when(
    p < 0.001 ~ "***",
    p < 0.01  ~ "**",
    p < 0.05  ~ "*",
    p < 0.10  ~ "+",
    TRUE ~ ""
  )
}

# Function to extract odds ratios and standard errors
tidy_or <- function(model, model_name) {
  broom::tidy(model) %>%
    mutate(
      odds_ratio = exp(estimate),
      stars = stars(p.value),
      estimate_display = paste0(sprintf("%.3f", odds_ratio), stars),
      se_display = paste0("(", sprintf("%.3f", std.error), ")"),
      model = model_name
    ) %>%
    select(model, term, estimate_display, se_display)
}

# Extract model results
reg_results <- bind_rows(
  tidy_or(model_stock_1, "Stock: Simple"),
  tidy_or(model_stock_2, "Stock: Controls"),
  tidy_or(model_stock_3, "Stock: Full"),
  tidy_or(model_stock_4_fixed, "Distress Components")
)

# Keep only terms needed in the final table
term_order <- c(
  "prior_loss_proxy",
  "late_payment",
  "bankruptcy5",
  "foreclosure5",
  "ln_income",
  "ihs_networth",
  "ln_debt",
  "age",
  "age_sq",
  "education_cat2",
  "education_cat3",
  "education_cat4",
  "married_cat2",
  "KIDS",
  "labor_force1",
  "race_cat2"
)

term_labels <- c(
  prior_loss_proxy = "Prior-loss proxy",
  late_payment = "Late payment",
  bankruptcy5 = "Bankruptcy, past 5 years",
  foreclosure5 = "Foreclosure, past 5 years",
  ln_income = "Log income",
  ihs_networth = "IHS net worth",
  ln_debt = "Log debt",
  age = "Age",
  age_sq = "Age squared",
  education_cat2 = "Education category 2",
  education_cat3 = "Education category 3",
  education_cat4 = "Education category 4",
  married_cat2 = "Married category 2",
  KIDS = "Children",
  labor_force1 = "Labor force",
  race_cat2 = "Race category 2"
)

reg_table <- reg_results %>%
  filter(term %in% term_order) %>%
  mutate(
    term = factor(term, levels = term_order),
    Variable = term_labels[as.character(term)]
  ) %>%
  arrange(term) %>%
  pivot_longer(
    cols = c(estimate_display, se_display),
    names_to = "row_type",
    values_to = "value"
  ) %>%
  mutate(
    Variable = if_else(row_type == "se_display", "", Variable)
  ) %>%
  select(Variable, model, value) %>%
  pivot_wider(
    names_from = model,
    values_from = value,
    values_fn = \(x) x[1]   # fixes list-column issue
  ) %>%
  mutate(across(everything(), as.character))

# Add model information rows
model_info <- tibble(
  Variable = c(
    "Demographic controls",
    "Financial controls",
    "Observations"
  ),
  `Stock: Simple` = c("No", "No", format(nobs(model_stock_1), big.mark = ",")),
  `Stock: Controls` = c("Yes", "No", format(nobs(model_stock_2), big.mark = ",")),
  `Stock: Full` = c("Yes", "Yes", format(nobs(model_stock_3), big.mark = ",")),
  `Distress Components` = c("Yes", "Yes", format(nobs(model_stock_4_fixed), big.mark = ","))
)

reg_table_final <- bind_rows(reg_table, model_info)


# Export as LaTeX-ready table
reg_table_final %>%
  kable(
    format = "latex",
    booktabs = TRUE,
    caption = "Main Econometric Results",
    label = "tab:main_results",
    align = c("l", "c", "c", "c", "c"),
    escape = TRUE
  ) %>%
  kable_styling(
    latex_options = c("hold_position", "scale_down"),
    full_width = FALSE,
    font_size = 8
  ) %>%
  footnote(
    general = "Entries are odds ratios from survey-weighted logistic regressions. Standard errors are reported in parentheses. The dependent variable is stock ownership. + p < 0.10, * p < 0.05, ** p < 0.01, *** p < 0.001.",
    general_title = "Notes: ",
    footnote_as_chunk = TRUE,
    escape = TRUE
  ) %>%
  save_kable("output/econometric_results.tex")

#######################################
# 12. Save clean analysis dataset
########################################

write_csv(analysis_df, "output/analysis_dataset_clean.csv")

cat("\nAll outputs created successfully in the output folder.\n")


