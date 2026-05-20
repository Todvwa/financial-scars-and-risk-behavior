# Financial Distress and Household Risk-Taking Behavior

## Abstract
This project investigates how prior financial distress influences household risk-taking behavior using the 2024 Survey of Consumer Finances (SCF). The analysis examines whether households experiencing financial shocks—such as negative net worth, late payments, bankruptcy, or foreclosure—exhibit systematically more conservative investment behavior.

The study applies survey-weighted econometric methods to estimate the relationship between financial distress and stock market participation, equity ownership, and self-reported risk tolerance.

---

## Research Question
Does prior financial distress predict more conservative household investment behavior?

---

## Key Contribution
This project focuses on **revealed financial behavior** rather than self-reported risk preferences, using SCF microdata and survey-weighted logistic regression models to analyze real investment decisions.

---

## Data
The analysis uses the **2024 Survey of Consumer Finances (SCF)**, a nationally representative dataset from the U.S. Federal Reserve.

The SCF contains detailed information on:
- Household income and net worth  
- Debt and leverage measures  
- Stock and equity ownership  
- Financial distress indicators (bankruptcy, foreclosure, late payments)

A composite **financial distress proxy** is constructed using:
- Negative net worth  
- Late payments  
- Bankruptcy (past 5 years)  
- Foreclosure (past 5 years)

---

## Methodology
The empirical strategy uses survey-weighted logistic regression models (`svyglm`) to estimate the relationship between financial distress and household financial behavior.

### Outcome variables:
- Stock market participation
- Equity ownership
- Willingness to take financial risk

### Key explanatory variable:
- Financial distress (composite “prior-loss proxy”)

### Controls:
- Income and debt (log transformations)
- Net worth (inverse hyperbolic sine transformation)
- Age and age squared
- Education, marital status, race, labor force status, number of children

### Estimation approach:
- Survey-weighted logistic regression
- Odds ratio interpretation
- Predicted probability comparisons across groups

---

## Key Findings (to be updated with results)
- Households experiencing financial distress are less likely to participate in stock markets  
- Financial shocks are associated with more conservative investment behavior  
- Effects persist even after controlling for income, wealth, and demographics  

---

## Tools & Technologies
- R
- tidyverse (data wrangling)
- survey (complex survey design estimation)
- ggplot2 (visualization)
- broom (model output cleaning)
- kableExtra (publication-ready tables)

---

## Outputs
The project generates:
- Descriptive statistics tables
- Regression tables (odds ratios with significance levels)
- Predicted probability comparisons
- Visualizations of investment behavior by distress status
- Clean analysis dataset for reproducibility

---

## Project Structure
financial-scars-household-risk/
│
├── data/
│ └── Survey of Consumer Finances.csv
│
├── scripts/
│ └── analysis.R
│
├── output/
│ ├── figures/
│ ├── tables/
│ ├── regression_results.tex
│ └── datasets/
│
├── README.md
└── financial-scars-household-risk.Rproj

---

## Limitations
- Financial distress is proxied using observable indicators rather than longitudinal shock tracking  
- Cross-sectional analysis limits causal interpretation  
- Results are conditional on available SCF survey variables  

---

## Author
**Todvwa Dlamini**  
University of Oklahoma  
Economics (M.A.) & Information Science and Technology (B.S.)

---

## License
MIT Licenser.
