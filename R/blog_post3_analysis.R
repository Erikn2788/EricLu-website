# ============================================================
# Blog Post 3 Analysis
# How Unequal Was the COVID-19 Unemployment Shock
# Across Education Groups?
#
# Data: IPUMS CPS, 2015–2024
# Population: U.S. adults ages 25–64
# ============================================================


# ------------------------------------------------------------
# 1. Load packages
# ------------------------------------------------------------

library(tidyverse)
library(ipumsr)


# ------------------------------------------------------------
# 2. Read IPUMS CPS data
# ------------------------------------------------------------

ddi <- read_ipums_ddi("data/raw/cps_00001.xml")

cps <- read_ipums_micro(ddi)


# ------------------------------------------------------------
# 3. Clean data
# ------------------------------------------------------------

cps_work <- cps |>
  select(
    YEAR,
    MONTH,
    AGE,
    EDUC,
    EMPSTAT,
    LABFORCE,
    WTFINL
  ) |>
  filter(
    AGE >= 25,
    AGE <= 64
  ) |>
  mutate(
    educ_label = haven::as_factor(EDUC),
    emp_label = haven::as_factor(EMPSTAT),
    
    education = case_when(
      educ_label %in% c(
        "None or preschool",
        "Grades 1, 2, 3, or 4",
        "Grades 5 or 6",
        "Grades 7 or 8",
        "Grade 9",
        "Grade 10",
        "Grade 11",
        "12th grade, no diploma"
      ) ~ "Less than high school",
      
      educ_label == "High school diploma or equivalent" ~
        "High school",
      
      educ_label %in% c(
        "Some college but no degree",
        "Associate's degree, occupational/vocational program",
        "Associate's degree, academic program"
      ) ~ "Some college / Associate",
      
      educ_label %in% c(
        "Bachelor's degree",
        "Master's degree",
        "Professional school degree",
        "Doctorate degree"
      ) ~ "Bachelor's or higher",
      
      TRUE ~ NA_character_
    ),
    
    unemployed = case_when(
      emp_label %in% c(
        "Unemployed, experienced worker",
        "Unemployed, new worker"
      ) ~ 1,
      
      emp_label %in% c(
        "At work",
        "Has job, not at work last week"
      ) ~ 0,
      
      TRUE ~ NA_real_
    )
  )


# ------------------------------------------------------------
# 4. Monthly weighted unemployment rates
# ------------------------------------------------------------

unemp_monthly <- cps_work |>
  filter(
    !is.na(education),
    !is.na(unemployed)
  ) |>
  group_by(
    YEAR,
    MONTH,
    education
  ) |>
  summarise(
    unemployment_rate =
      sum(WTFINL * unemployed, na.rm = TRUE) /
      sum(WTFINL, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(
    date = as.Date(
      paste(
        YEAR,
        as.integer(MONTH),
        1,
        sep = "-"
      )
    )
  )


# Save derived monthly data

write_csv(
  unemp_monthly,
  "data/derived/unemployment_monthly.csv"
)


# ------------------------------------------------------------
# 5. Annual weighted unemployment rates
# ------------------------------------------------------------

unemp_annual <- cps_work |>
  filter(
    !is.na(education),
    !is.na(unemployed)
  ) |>
  group_by(
    YEAR,
    education
  ) |>
  summarise(
    unemployment_rate =
      sum(WTFINL * unemployed, na.rm = TRUE) /
      sum(WTFINL, na.rm = TRUE),
    .groups = "drop"
  )


# ------------------------------------------------------------
# 6. Figure 1
# ------------------------------------------------------------

fig1 <- ggplot(
  unemp_annual,
  aes(
    x = YEAR,
    y = unemployment_rate,
    color = education
  )
) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_y_continuous(
    labels = scales::percent_format(accuracy = 1)
  ) +
  scale_x_continuous(
    breaks = 2015:2024
  ) +
  labs(
    title = "Unemployment Rates by Education, 2015–2024",
    subtitle = "U.S. adults ages 25–64; estimates weighted using CPS sampling weights",
    x = NULL,
    y = "Unemployment rate",
    color = "Education",
    caption = "Source: IPUMS CPS."
  ) +
  theme_minimal()

print(fig1)

ggsave(
  "images/figure1_unemployment_education_2015_2024.png",
  plot = fig1,
  width = 10,
  height = 6,
  dpi = 300
)


# ------------------------------------------------------------
# 7. Figure 2
# ------------------------------------------------------------

covid_monthly <- unemp_monthly |>
  filter(
    YEAR >= 2019,
    YEAR <= 2021
  )

fig2 <- ggplot(
  covid_monthly,
  aes(
    x = date,
    y = unemployment_rate,
    color = education
  )
) +
  geom_line(linewidth = 1) +
  scale_y_continuous(
    labels = scales::percent_format(accuracy = 1)
  ) +
  labs(
    title = "The COVID-19 Unemployment Shock by Education",
    subtitle = "Monthly unemployment rates, U.S. adults ages 25–64",
    x = NULL,
    y = "Unemployment rate",
    color = "Education",
    caption = "Source: IPUMS CPS. Estimates use CPS sampling weights."
  ) +
  theme_minimal()

print(fig2)

ggsave(
  "images/figure2_covid_monthly_unemployment.png",
  plot = fig2,
  width = 10,
  height = 6,
  dpi = 300
)


# ------------------------------------------------------------
# 8. Create age groups
# ------------------------------------------------------------

cps_age <- cps_work |>
  mutate(
    age_group = case_when(
      AGE >= 25 & AGE <= 34 ~ "25–34",
      AGE >= 35 & AGE <= 44 ~ "35–44",
      AGE >= 45 & AGE <= 54 ~ "45–54",
      AGE >= 55 & AGE <= 64 ~ "55–64"
    )
  )


# ------------------------------------------------------------
# 9. April 2019 unemployment rates
# ------------------------------------------------------------

april_2019 <- cps_age |>
  filter(
    YEAR == 2019,
    as.integer(MONTH) == 4,
    !is.na(education),
    !is.na(unemployed)
  ) |>
  group_by(
    age_group,
    education
  ) |>
  summarise(
    rate_april2019 =
      sum(WTFINL * unemployed, na.rm = TRUE) /
      sum(WTFINL, na.rm = TRUE),
    .groups = "drop"
  )


# ------------------------------------------------------------
# 10. April 2020 unemployment rates
# ------------------------------------------------------------

april_2020 <- cps_age |>
  filter(
    YEAR == 2020,
    as.integer(MONTH) == 4,
    !is.na(education),
    !is.na(unemployed)
  ) |>
  group_by(
    age_group,
    education
  ) |>
  summarise(
    rate_april2020 =
      sum(WTFINL * unemployed, na.rm = TRUE) /
      sum(WTFINL, na.rm = TRUE),
    .groups = "drop"
  )


# ------------------------------------------------------------
# 11. Calculate COVID unemployment shock
# ------------------------------------------------------------

shock_by_age <- april_2019 |>
  left_join(
    april_2020,
    by = c("age_group", "education")
  ) |>
  mutate(
    increase = rate_april2020 - rate_april2019,
    
    age_group = factor(
      age_group,
      levels = c(
        "25–34",
        "35–44",
        "45–54",
        "55–64"
      )
    )
  )


# ------------------------------------------------------------
# 12. Figure 3
# ------------------------------------------------------------

fig3 <- ggplot(
  shock_by_age,
  aes(
    x = age_group,
    y = increase,
    color = education,
    group = education
  )
) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 3) +
  scale_y_continuous(
    labels = function(x) {
      paste0(round(x * 100, 1), " pp")
    }
  ) +
  labs(
    title = "The COVID-19 Unemployment Shock Across Age Groups",
    subtitle = "Change in unemployment rates from April 2019 to April 2020",
    x = "Age group",
    y = "Increase in unemployment rate",
    color = "Education",
    caption = "Source: IPUMS CPS. Estimates use CPS sampling weights."
  ) +
  theme_minimal()

print(fig3)

ggsave(
  "images/figure3_age_education_unemployment.png",
  plot = fig3,
  width = 10,
  height = 6,
  dpi = 300
)