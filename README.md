# Computational Methods for Economists

This repository contains my course website, blog posts, code, data-processing files, and visualizations for **Computational Methods for Economists**.

The website is built with Quarto and published through GitHub Pages.

## Blog Posts

| Post | Topic |
|---|---|
| Blog Post 1 | **What Does a p-Value Really Mean?** |
| Blog Post 2 | **What Skills Show Up Most in Data, AI, and ML Jobs?** |
| Blog Post 3 | **How Unequal Was the COVID-19 Unemployment Shock Across Education Groups?** |
| Blog Post 4 | **How Much Has the Federal Minimum Wage Lost in Purchasing Power?** |
| Blog Post 5 | *To be added* |
| Blog Post 6 | *To be added* |
| Blog Post 7 | *To be added* |
| Blog Post 8 | *To be added* |
| Blog Post 9 | *To be added* |
| Blog Post 10 | *To be added* |
| Blog Post 11 | *To be added* |

## Repository Structure

```text
.
├── blog/
│   └── posts/
│       ├── post1/
│       ├── post2/
│       ├── post3/
│       ├── post4/
│       ├── ...
│       └── post11/
│
├── R/
│   └── analysis and data-processing scripts
│
├── data/
│   ├── raw/
│   │   └── original source data
│   └── derived/
│       └── cleaned or summarized data
│
├── images/
│   └── figures used in blog posts
│
├── results/
│   └── additional analysis outputs
│
├── docs/
│   └── rendered website files for GitHub Pages
│
├── README.md
└── _quarto.yml
```

The goal is to keep the code, data, and figures for each blog post organized and reproducible.

## General Replication Instructions

In general, each blog post can be reproduced by:

1. Clone or download this repository.
2. Open the RStudio project from the repository root.
3. Install the R packages required by the relevant analysis script.
4. Obtain any external data that cannot be included directly in the repository.
5. Place raw data in `data/raw/` when required.
6. Run the corresponding script in the `R/` folder.
7. Render the Quarto website.

Derived datasets and figures are generated programmatically whenever possible.

---

## Blog Post 1

### What Does a p-Value Really Mean?

This post explains the interpretation of a p-value and some common misunderstandings surrounding statistical significance.

### Quarto Source

```text
blog/posts/post1/
```

---

## Blog Post 2

### What Skills Show Up Most in Data, AI, and ML Jobs?

Blog Post 2 analyzes job postings from the September 2026 Hacker News **"Who is hiring?"** thread to examine which technical skills appear most often in data, AI, and machine-learning jobs.

The analysis uses `rvest` to collect job-posting text, identifies Data, AI, and ML-related positions, and counts commonly mentioned technical skills.

### Data

The source data come from the September 2026 Hacker News **"Who is hiring?"** thread.

Raw webpage content is saved in:

```text
data/raw/
```

Cleaned job-posting data are stored in:

```text
data/derived/
```

### Replication

The main analysis script is:

```text
R/scrape_hn_jobs.R
```

From the project root, run:

```r
source("R/scrape_hn_jobs.R")
```

The script downloads the webpage, saves the raw HTML, filters relevant hiring posts, calculates skill frequencies, and generates the visualization used in the blog post.

### Quarto Source

```text
blog/posts/post2/
```

---

## Blog Post 3

### How Unequal Was the COVID-19 Unemployment Shock Across Education Groups?

Blog Post 3 uses **IPUMS Current Population Survey (CPS)** microdata to examine how unemployment changed across education groups before, during, and after the COVID-19 shock.

The analysis focuses on U.S. adults ages 25–64 and uses CPS sampling weights when calculating unemployment rates.

### Data

The analysis uses IPUMS CPS Basic Monthly Samples from **2015 through 2024**.

The main variables are:

```text
YEAR
MONTH
AGE
EDUC
EMPSTAT
LABFORCE
WTFINL
```

Raw IPUMS CPS microdata are not included in this public repository.

To reproduce the analysis, place the corresponding IPUMS `.xml` and `.dat.gz` files in:

```text
data/raw/
```

### Replication

The analysis script is:

```text
R/blog_post3_analysis.R
```

Run:

```r
source("R/blog_post3_analysis.R")
```

The script creates the education groups, calculates weighted unemployment rates, produces the derived monthly data, and generates all three figures used in the post.

Derived data:

```text
data/derived/unemployment_monthly.csv
```

Figures:

```text
images/figure1_unemployment_education_2015_2024.png
images/figure2_covid_monthly_unemployment.png
images/figure3_age_education_unemployment.png
```

### Quarto Source

```text
blog/posts/post3/
```

---

## Blog Post 4

### How Much Has the Federal Minimum Wage Lost in Purchasing Power?

Blog Post 4 uses FRED data to examine how the purchasing power of the U.S. federal minimum wage has changed over time.

The analysis compares the nominal federal minimum wage with an inflation-adjusted version expressed in 2024 dollars. It also calculates what the July 2009 minimum wage of $7.25 would be if it had continued to increase with CPI.

### Data

The analysis uses two monthly FRED series:

```text
FEDMINNFRWG
CPIAUCNS
```

The data are downloaded directly in R using the `fredr` package and the FRED API.

Raw data are saved as:

```text
data/raw/fred_federal_minimum_wage.csv
data/raw/fred_cpi.csv
```

The derived dataset is:

```text
data/derived/blog4_minimum_wage.csv
```

### Replication

The analysis script is:

```text
R/blog_post4_analysis.R
```

A FRED API key is required. It should be stored in the user's `.Renviron` file:

```text
FRED_API_KEY=YOUR_API_KEY
```

Then run:

```r
source("R/blog_post4_analysis.R")
```

The script downloads the FRED data, adjusts the minimum wage for inflation, calculates the July 2009 CPI counterfactual, and generates the three figures used in the post.

Figures:

```text
images/figure1_federal_minimum_wage.png
images/figure2_real_minimum_wage.png
images/figure3_minimum_wage_vs_inflation_path.png
```

### Quarto Source

```text
blog/posts/post4/
```

---

## Blog Post 5

### Topic

*To be added.*

### Data

*To be added.*

### Replication

Analysis script:

```text
R/blog_post5_analysis.R
```

Quarto source:

```text
blog/posts/post5/
```

---

## Blog Post 6

### Topic

*To be added.*

### Data

*To be added.*

### Replication

Analysis script:

```text
R/blog_post6_analysis.R
```

Quarto source:

```text
blog/posts/post6/
```

---

## Blog Post 7

### Topic

*To be added.*

### Data

*To be added.*

### Replication

Analysis script:

```text
R/blog_post7_analysis.R
```

Quarto source:

```text
blog/posts/post7/
```

---

## Blog Post 8

### Topic

*To be added.*

### Data

*To be added.*

### Replication

Analysis script:

```text
R/blog_post8_analysis.R
```

Quarto source:

```text
blog/posts/post8/
```

---

## Blog Post 9

### Topic

*To be added.*

### Data

*To be added.*

### Replication

Analysis script:

```text
R/blog_post9_analysis.R
```

Quarto source:

```text
blog/posts/post9/
```

---

## Blog Post 10

### Topic

*To be added.*

### Data

*To be added.*

### Replication

Analysis script:

```text
R/blog_post10_analysis.R
```

Quarto source:

```text
blog/posts/post10/
```

---

## Blog Post 11

### Topic

*To be added.*

### Data

*To be added.*

### Replication

Analysis script:

```text
R/blog_post11_analysis.R
```

Quarto source:

```text
blog/posts/post11/
```

---

## Reproducibility

The main goal of the repository is to keep the published results connected to the code that generated them.

Whenever possible:

- data are obtained or processed programmatically,
- raw data are kept separate from derived data,
- transformations are documented in R scripts,
- sampling weights are used when required,
- figures are generated directly from the analysis,
- and output files are saved rather than manually copied into the website.

Some external datasets may not be stored in the repository because of licensing, redistribution restrictions, or file-size limits. In those cases, the relevant blog-post section explains how to obtain the data.

## Website

The rendered website is stored in:

```text
docs/
```

and published through GitHub Pages.