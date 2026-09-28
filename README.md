# Computational Methods for Economists

This repository contains my course website, blog posts, code, data-processing files, and visualizations for **Computational Methods for Economists**.

The published website is built with Quarto and hosted through GitHub Pages.

## Blog Posts

| Post | Topic |
|---|---|
| Blog Post 2 | **What Skills Show Up Most in Data, AI, and ML Jobs?** |
| Blog Post 3 | **How Unequal Was the COVID-19 Unemployment Shock Across Education Groups?** |

Additional blog posts will be added to this repository throughout the course.

## Repository Structure

The repository uses the following general structure:

```text
.
├── blog/
│   └── posts/
│       ├── post2/
│       ├── post3/
│       └── ...
│
├── R/
│   └── analysis and data-processing scripts
│
├── data/
│   ├── raw/
│   │   └── original source data when redistribution is permitted
│   └── derived/
│       └── cleaned or summarized data created by the analysis
│
├── images/
│   └── figures used in blog posts
│
├── docs/
│   └── rendered website files for GitHub Pages
│
├── README.md
└── _quarto.yml
```

Files are given descriptive names so that the code, derived data, and figures associated with each blog post can be identified as additional posts are added.

## General Replication Instructions

Each blog post is designed so that the main analysis can be reproduced from the code included in this repository.

In general:

1. Clone or download this repository.
2. Open the RStudio project from the repository root.
3. Obtain any external raw data that cannot legally or practically be included in the repository.
4. Place those files in the location described for the relevant blog post.
5. Install any R packages required by the corresponding analysis script.
6. Run the relevant script in the `R/` folder.
7. Derived data and figures will be generated programmatically and saved in the repository folders used by the website.

Raw data are not manually modified. Data cleaning, aggregation, and figure creation are handled in code whenever possible.

---

## Blog Post 2

### What Skills Show Up Most in Data, AI, and ML Jobs?

Blog Post 2 analyzes job postings from the September 2026 Hacker News **"Who is hiring?"** thread to examine which technical skills appear most often in data, AI, and machine-learning jobs.

The analysis uses `rvest` to collect the job-posting text, cleans the postings, identifies data-related positions, and summarizes commonly requested skills.

### Data

The source data come from the Hacker News "Who is hiring?" thread.

The analysis workflow includes:

- collecting the job postings with `rvest`,
- saving the source content,
- cleaning and filtering the postings,
- identifying data, AI, and machine-learning jobs,
- counting selected technical skills,
- and generating the visualization used in the blog post.

### Replication

The R code for Blog Post 2 is stored in the `R/` folder.

Run the corresponding Blog Post 2 analysis script from the project root. The script reproduces the cleaned data and visualization used in the published post.

The Quarto source for the post is located in:

```text
blog/posts/post2/
```

---

## Blog Post 3

### How Unequal Was the COVID-19 Unemployment Shock Across Education Groups?

Blog Post 3 uses **IPUMS Current Population Survey (CPS)** microdata to examine how unemployment differed across education groups before, during, and after the COVID-19 labor-market shock.

The analysis focuses on U.S. adults ages 25–64 and uses CPS sampling weights when calculating population unemployment rates.

### Data

The analysis uses IPUMS CPS Basic Monthly Samples from **2015 through 2024**.

The main variables used are:

- `YEAR`
- `MONTH`
- `AGE`
- `EDUC`
- `EMPSTAT`
- `LABFORCE`
- `WTFINL`

Education is grouped into four categories:

- Less than high school
- High school
- Some college / Associate
- Bachelor's degree or higher

Population unemployment rates are calculated using the CPS final person weight, `WTFINL`.

### Raw CPS Data

Raw IPUMS CPS microdata are **not included in this public repository**.

To reproduce Blog Post 3, obtain the corresponding IPUMS CPS extract and place the downloaded `.xml` and `.dat.gz` files in:

```text
data/raw/
```

The extract should contain the 2015–2024 Basic Monthly CPS samples and the variables listed above.

### Replication

The analysis script is:

```text
R/blog_post3_analysis.R
```

From the project root, run:

```r
source("R/blog_post3_analysis.R")
```

The script:

- reads the IPUMS CPS extract,
- restricts the sample to adults ages 25–64,
- constructs the four education groups,
- identifies employed and unemployed members of the labor force,
- calculates CPS-weighted monthly and annual unemployment rates,
- creates the age-group comparison,
- and generates all three figures used in Blog Post 3.

The analysis produces the derived monthly data:

```text
data/derived/unemployment_monthly.csv
```

and the following figures:

```text
images/figure1_unemployment_education_2015_2024.png
images/figure2_covid_monthly_unemployment.png
images/figure3_age_education_unemployment.png
```

The Quarto source for the post is located in:

```text
blog/posts/post3/
```

---

## Adding Future Blog Posts

Future blog posts will follow the same general organization.

For each new post:

- the Quarto source will be placed under `blog/posts/`,
- analysis code will be stored in `R/`,
- original data will be stored in `data/raw/` when redistribution is permitted,
- cleaned or summarized data will be stored in `data/derived/`,
- and figures used on the website will be saved programmatically.

New posts can be added without changing the overall repository structure. Their titles and topics can simply be added to the **Blog Posts** table above, along with a short replication section when necessary.

## Reproducibility

The goal of this repository is to keep the published results connected to the code that generated them.

Whenever possible:

- data are obtained or processed programmatically,
- transformations are documented in R scripts,
- population statistics use the appropriate weights when required,
- figures are generated directly from the analysis,
- and derived outputs are saved rather than manually copied into the website.

Some external datasets may not be stored in the repository because of licensing, redistribution restrictions, or file-size limits. In those cases, the README documents how the data should be obtained and where they should be placed for replication.

## Website

The rendered website is stored in the `docs/` directory and published through GitHub Pages.