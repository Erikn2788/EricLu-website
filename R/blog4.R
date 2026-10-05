library(tidyverse)
library(fredr)
library(here)

fredr_set_key(Sys.getenv("FRED_API_KEY"))

minimum_wage <- fredr(
  series_id = "FEDMINNFRWG",
  observation_start = as.Date("1938-10-01")
)

cpi <- fredr(
  series_id = "CPIAUCNS",
  observation_start = as.Date("1938-10-01")
)

write_csv(
  minimum_wage,
  "data/raw/fred_federal_minimum_wage.csv"
)

write_csv(
  cpi,
  "data/raw/fred_cpi.csv"
)

cpi_2024 <- cpi |>
  filter(lubridate::year(date) == 2024) |>
  summarise(
    cpi_2024 = mean(value)
  ) |>
  pull(cpi_2024)

wage_data <- minimum_wage |>
  select(date, minimum_wage = value) |>
  left_join(
    cpi |> select(date, cpi = value),
    by = "date"
  ) |>
  mutate(
    real_wage = minimum_wage * cpi_2024 / cpi
  )

write_csv(
  wage_data,
  "data/derived/blog4_minimum_wage.csv"
)

peak_real_wage <- max(
  wage_data$real_wage,
  na.rm = TRUE
)

real_wage_2024 <- wage_data |>
  filter(lubridate::year(date) == 2024) |>
  summarise(
    value = mean(real_wage, na.rm = TRUE)
  ) |>
  pull(value)

percent_decline <- 100 * (
  peak_real_wage - real_wage_2024
) / peak_real_wage

fig1 <- ggplot(
  wage_data,
  aes(x = date, y = minimum_wage)
) +
  geom_step() +
  labs(
    title = "Federal Minimum Wage, 1938–2026",
    x = NULL,
    y = "Dollars per hour",
    caption = "Source: FRED"
  ) +
  theme_minimal()

fig1

ggsave(
  "images/figure1_federal_minimum_wage.png",
  plot = fig1,
  width = 10,
  height = 6,
  dpi = 300
)

peak_point <- wage_data |>
  filter(!is.na(real_wage)) |>
  slice_max(real_wage, n = 1)

latest_point <- wage_data |>
  filter(!is.na(real_wage)) |>
  slice_tail(n = 1)

fig2 <- wage_data |>
  filter(!is.na(real_wage)) |>
  ggplot(
    aes(x = date, y = real_wage)
  ) +
  geom_line() +
  geom_point(
    data = peak_point,
    size = 2
  ) +
  geom_point(
    data = latest_point,
    size = 2
  ) +
  annotate(
    "text",
    x = peak_point$date,
    y = peak_point$real_wage,
    label = paste0(
      lubridate::year(peak_point$date),
      " peak: $",
      round(peak_point$real_wage, 2)
    ),
    hjust = -0.05
  ) +
  annotate(
    "text",
    x = latest_point$date,
    y = latest_point$real_wage,
    label = paste0(
      lubridate::year(latest_point$date),
      ": $",
      round(latest_point$real_wage, 2)
    ),
    hjust = 1.1,
    vjust = -0.7
  ) +
  labs(
    title = "Real Federal Minimum Wage, 1938–2026",
    subtitle = "Adjusted to 2024 dollars",
    x = NULL,
    y = "2024 dollars per hour",
    caption = "Source: FRED"
  ) +
  theme_minimal()

fig2

ggsave(
  "images/figure2_real_minimum_wage.png",
  plot = fig2,
  width = 10,
  height = 6,
  dpi = 300
)

cpi_2009 <- wage_data |>
  filter(date == as.Date("2009-07-01")) |>
  pull(cpi)

since_2009 <- wage_data |>
  filter(date >= as.Date("2009-07-01")) |>
  mutate(
    inflation_adjusted_wage = 7.25 * cpi / cpi_2009
  )

fig3 <- since_2009 |>
  filter(!is.na(inflation_adjusted_wage)) |>
  select(
    date,
    minimum_wage,
    inflation_adjusted_wage
  ) |>
  pivot_longer(
    cols = c(
      minimum_wage,
      inflation_adjusted_wage
    ),
    names_to = "series",
    values_to = "wage"
  ) |>
  mutate(
    series = recode(
      series,
      minimum_wage = "Actual federal minimum wage",
      inflation_adjusted_wage = "July 2009 wage adjusted for inflation"
    )
  ) |>
  ggplot(
    aes(
      x = date,
      y = wage,
      linetype = series
    )
  ) +
  geom_line(linewidth = 1) +
  labs(
    title = "What If the Federal Minimum Wage Had Kept Up with Inflation?",
    subtitle = "Actual wage vs. a CPI-adjusted version of the 2009 minimum wage",
    x = NULL,
    y = "Dollars per hour",
    linetype = NULL,
    caption = "Source: FRED"
  ) +
  theme_minimal()

fig3

ggsave(
  "images/figure3_minimum_wage_vs_inflation_path.png",
  plot = fig3,
  width = 10,
  height = 6,
  dpi = 300
)

cat(
  "Peak real minimum wage:",
  round(peak_real_wage, 2),
  "\n"
)

cat(
  "2024 real minimum wage:",
  round(real_wage_2024, 2),
  "\n"
)

cat(
  "Percent decline from peak:",
  round(percent_decline, 1),
  "%\n"
)