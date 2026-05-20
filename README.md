# Financial Scars and Household Risk-Taking Behavior

## Abstract
This project examines whether prior financial distress is associated with more conservative financial behavior among U.S. households. Using data from the 2024 Survey of Consumer Finances (SCF), the analysis investigates how experiences such as bankruptcy, foreclosure, and late payments influence stock market participation and household risk-taking behavior.

The study applies survey-weighted logistic regression models to account for the SCF’s complex survey design and produces nationally representative estimates of household financial behavior.

## Research Question
Does prior financial distress predict more conservative household investment behavior?

## Key Contribution
This project focuses on **revealed financial behavior** (actual investment and portfolio choices) rather than self-reported risk preferences, using nationally representative SCF microdata and survey-weighted econometric methods.

## Data

The analysis uses the **2024 Survey of Consumer Finances (SCF)**, a nationally representative dataset produced by the U.S. Federal Reserve.

The SCF includes detailed information on:
- Household income, debt, and net worth
- Stock and equity ownership
- Credit constraints and financial distress indicators
- Demographic and socioeconomic characteristics

A composite **financial distress proxy (“prior-loss indicator”)** is constructed using:
- Negative net worth
- Late payments
- Bankruptcy (past 5 years)
- Foreclosure (past 5 years)

The dataset is publicly available via the Federal Reserve SCF website.

## Methodology

The empirical analysis uses **survey-weighted logistic regression models** implemented in R using the `survey` package.

### Outcome Variables
- Stock market participation
- Equity ownership
- Willingness to take financial risk

### Key Independent Variable
- Financial distress proxy (composite indicator of prior financial shocks)

### Controls
- Income (log transformation)
- Net worth (IHS transformation)
- Debt (log transformation)
- Age and age squared
- Education, marital status, race, labor force status, number of children

### Estimation Strategy
- Survey-weighted logistic regression (`svyglm`)
- Odds ratio interpretation
- Predicted probability comparisons between distressed and non-distressed households

## Key Findings (to be updated with final results)

- Households experiencing financial distress are less likely to participate in stock markets  
- Financial shocks are associated with more conservative investment behavior  
- Effects persist after controlling for income, wealth, and demographic characteristics  

## Software & Tools

- R
- tidyverse (data manipulation)
- survey (complex survey estimation)
- ggplot2 (visualization)
- broom (model output processing)
- kableExtra (publication-quality tables)

## Reproducibility

This project is fully reproducible. The analysis script:

- installs required packages automatically
- processes raw SCF data
- constructs financial distress measures
- estimates econometric models
- generates tables, figures, and output files

All outputs are saved in the `/output/` directory.

To replicate:
1. Download SCF 2024 data from the Federal Reserve
2. Place dataset in the project folder
3. Run `analysis.R` from top to bottom in RStudio

## Repository Structure
financial-scars-household-risk/
│
├── data/
│ └── Survey of Consumer Finances.csv
├── scripts/
│ └── analysis.R
├── output/
│ ├── figures/
│ ├── tables/
│ └── datasets/
├── README.md
└── financial-scars.Rproj

## References

- Kahneman, D. & Tversky, A. (1979)
- Guiso, Sapienza, & Zingales (2008)
- Lusardi & Mitchell (2014)
- Mian, Sufi, & Trebbi (2015)

Full bibliography available in `references.bib`.

## Author

**Todvwa Dlamini**  
University of Oklahoma  
M.A. Economics & B.S. Information Science and Technology
