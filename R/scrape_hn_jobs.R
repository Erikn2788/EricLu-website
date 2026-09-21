# ============================================================
# Blog Post 2
# Web Scraping for Actionable Insights
#
# Research Question:
# What technical skills appear most often in Hacker News
# hiring posts advertising Data, AI, or Machine Learning roles?
# ============================================================


# ------------------------------------------------------------
# 0. Load packages
# ------------------------------------------------------------

library(tidyverse)
library(rvest)
library(here)
library(xml2)


# ------------------------------------------------------------
# 1. Create project folders
# ------------------------------------------------------------

dir.create(
  here("data", "raw"),
  recursive = TRUE,
  showWarnings = FALSE
)

dir.create(
  here("data", "derived"),
  recursive = TRUE,
  showWarnings = FALSE
)

dir.create(
  here("results"),
  recursive = TRUE,
  showWarnings = FALSE
)


# ------------------------------------------------------------
# 2. Define source and output paths
# ------------------------------------------------------------

hn_url <- "https://news.ycombinator.com/item?id=49522897"

raw_html_file <- here(
  "data",
  "raw",
  "hn_who_is_hiring_sep2026.html"
)

metadata_file <- here(
  "data",
  "raw",
  "hn_source_metadata.csv"
)

top_level_file <- here(
  "data",
  "derived",
  "hn_jobs_top_level.csv"
)

data_jobs_file <- here(
  "data",
  "derived",
  "hn_data_jobs.csv"
)

skill_file <- here(
  "data",
  "derived",
  "hn_skill_frequency.csv"
)

plot_file <- here(
  "results",
  "hn_data_job_skills.png"
)


# ------------------------------------------------------------
# 3. Acquire webpage
#
# Only download the page if the raw HTML snapshot does not
# already exist.
# ------------------------------------------------------------

if (!file.exists(raw_html_file)) {
  
  page_live <- read_html(hn_url)
  
  xml2::write_html(
    page_live,
    raw_html_file
  )
  
  message(
    "Downloaded and saved a new HTML snapshot."
  )
  
} else {
  
  message(
    "Raw HTML already exists. Using saved snapshot."
  )
  
}


# ------------------------------------------------------------
# 4. Read saved raw HTML
# ------------------------------------------------------------

page <- read_html(
  raw_html_file
)


# ------------------------------------------------------------
# 5. Save source metadata
# ------------------------------------------------------------

metadata <- tibble(
  source = "Hacker News",
  thread = "Ask HN: Who is hiring? (September 2026)",
  source_url = hn_url,
  accessed_at = file.info(raw_html_file)$mtime
)

write_csv(
  metadata,
  metadata_file
)


# ------------------------------------------------------------
# 6. Extract all comment rows
# ------------------------------------------------------------

comment_rows <- page |>
  html_elements(
    "tr.athing.comtr"
  )

message(
  "Total comments found: ",
  length(comment_rows)
)


# ------------------------------------------------------------
# 7. Extract indentation level
#
# indent = 0 means a top-level hiring post.
# Higher values represent replies.
# ------------------------------------------------------------

indent <- comment_rows |>
  html_element("td.ind") |>
  html_attr("indent") |>
  as.integer()


# ------------------------------------------------------------
# 8. Extract comment IDs
# ------------------------------------------------------------

comment_id <- comment_rows |>
  html_attr("id")


# ------------------------------------------------------------
# 9. Extract comment text
# ------------------------------------------------------------

comment_text <- comment_rows |>
  html_element(".commtext") |>
  html_text2()


# ------------------------------------------------------------
# 10. Build complete comment dataset
# ------------------------------------------------------------

comments <- tibble(
  comment_id = comment_id,
  indent = indent,
  text = comment_text
)


# ------------------------------------------------------------
# 11. Keep only top-level hiring posts
# ------------------------------------------------------------

jobs_raw <- comments |>
  filter(
    indent == 0,
    !is.na(text),
    text != ""
  )


message(
  "Top-level hiring posts: ",
  nrow(jobs_raw)
)


# ------------------------------------------------------------
# 12. Create a short header
#
# Most Hacker News hiring posts begin with company name,
# job titles, location, and remote/on-site information.
# ------------------------------------------------------------

jobs_raw <- jobs_raw |>
  mutate(
    header = str_split_i(
      text,
      "\n",
      1
    )
  ) |>
  select(
    comment_id,
    header,
    text
  )


# ------------------------------------------------------------
# 13. Save all top-level hiring posts
# ------------------------------------------------------------

write_csv(
  jobs_raw,
  top_level_file
)


# ------------------------------------------------------------
# 14. Create a "role zone"
#
# We only use the first 350 characters of each hiring post
# to classify whether it advertises Data / AI / ML roles.
#
# This reduces false positives from company descriptions
# later in the post.
# ------------------------------------------------------------

jobs_raw <- jobs_raw |>
  mutate(
    role_zone = str_sub(
      text,
      1,
      350
    )
  )


# ------------------------------------------------------------
# 15. Define explicit Data / AI / ML role patterns
# ------------------------------------------------------------

data_role_pattern <- regex(
  paste(
    c(
      
      # Data science
      "\\bdata scientist\\b",
      "\\bdata science\\b",
      
      # Data engineering
      "\\bdata engineer\\b",
      "\\bdata engineering\\b",
      "\\banalytics engineer\\b",
      "\\bdata platform engineer\\b",
      "\\bdata infrastructure engineer\\b",
      
      # Data analysis
      "\\bdata analyst\\b",
      "\\banalytics analyst\\b",
      
      # Machine learning
      "\\bmachine learning engineer\\b",
      "\\bmachine learning scientist\\b",
      "\\bml engineer\\b",
      "\\bml scientist\\b",
      "\\bmlops engineer\\b",
      
      # Artificial intelligence
      "\\bai engineer\\b",
      "\\bai/ml engineer\\b",
      "\\bml/ai engineer\\b",
      "\\bapplied ai engineer\\b",
      "\\bapplied ai\\b",
      "\\bagentic ai engineer\\b",
      "\\bagent builder\\b",
      
      # Research roles
      "\\bresearch scientist\\b",
      "\\bresearch engineer\\b",
      "\\bapplied scientist\\b",
      
      # Software roles explicitly tied to data, ML, or AI
      "\\bsoftware engineer[^|\\n]{0,50}\\bdata\\b",
      "\\bsoftware engineer[^|\\n]{0,50}\\bml\\b",
      "\\bsoftware engineer[^|\\n]{0,50}\\bmachine learning\\b",
      "\\bsoftware engineer[^|\\n]{0,50}\\bai\\b"
      
    ),
    collapse = "|"
  ),
  ignore_case = TRUE
)


# ------------------------------------------------------------
# 16. Automatically identify Data / AI / ML hiring posts
# ------------------------------------------------------------

data_jobs <- jobs_raw |>
  mutate(
    is_data_or_ai_job = str_detect(
      role_zone,
      data_role_pattern
    )
  ) |>
  filter(
    is_data_or_ai_job
  ) |>
  select(
    comment_id,
    header,
    text
  )


message(
  "Data / AI / ML hiring posts: ",
  nrow(data_jobs)
)


# ------------------------------------------------------------
# 17. Save filtered hiring posts
# ------------------------------------------------------------

write_csv(
  data_jobs,
  data_jobs_file
)


# ------------------------------------------------------------
# 18. Define technical skills
#
# These patterns will be searched in the FULL text of each
# relevant hiring post.
# ------------------------------------------------------------

skill_patterns <- tribble(
  
  ~skill,       ~pattern,
  
  "Python",
  "\\bpython\\b",
  
  "SQL",
  "\\bsql\\b",
  
  "AWS",
  "\\baws\\b|amazon web services",
  
  "GCP",
  "\\bgcp\\b|google cloud",
  
  "Azure",
  "\\bazure\\b",
  
  "Docker",
  "\\bdocker\\b",
  
  "Kubernetes",
  "\\bkubernetes\\b|\\bk8s\\b",
  
  "PostgreSQL",
  "\\bpostgresql\\b|\\bpostgres\\b",
  
  "Spark",
  "\\bspark\\b|\\bpyspark\\b",
  
  "Snowflake",
  "\\bsnowflake\\b",
  
  "PyTorch",
  "\\bpytorch\\b",
  
  "TensorFlow",
  "\\btensorflow\\b",
  
  "dbt",
  "\\bdbt\\b",
  
  "Airflow",
  "\\bairflow\\b",
  
  "Kafka",
  "\\bkafka\\b",
  
  "LLMs",
  "\\bllm\\b|\\bllms\\b|large language model",
  
  "Tableau",
  "\\btableau\\b",
  
  "Power BI",
  "\\bpower\\s*bi\\b"
)


# ------------------------------------------------------------
# 19. Count the number of hiring posts mentioning each skill
#
# Each skill counts at most once per hiring post.
# ------------------------------------------------------------

skill_counts <- skill_patterns |>
  rowwise() |>
  mutate(
    n_posts = sum(
      str_detect(
        data_jobs$text,
        regex(
          pattern,
          ignore_case = TRUE
        )
      )
    )
  ) |>
  ungroup() |>
  mutate(
    share = n_posts / nrow(data_jobs)
  ) |>
  filter(
    n_posts > 0
  ) |>
  arrange(
    desc(n_posts)
  )


# ------------------------------------------------------------
# 20. Create clean result table
# ------------------------------------------------------------

skill_results <- skill_counts |>
  select(
    skill,
    n_posts,
    share
  )


print(
  skill_results
)


# ------------------------------------------------------------
# 21. Save skill-frequency results
# ------------------------------------------------------------

write_csv(
  skill_results,
  skill_file
)


# ------------------------------------------------------------
# 22. Select top skills for visualization
# ------------------------------------------------------------

top_skills <- skill_results |>
  slice_max(
    order_by = n_posts,
    n = 12,
    with_ties = FALSE
  )


# ------------------------------------------------------------
# 23. Create bar chart
# ------------------------------------------------------------

skill_plot <- ggplot(
  top_skills,
  aes(
    x = reorder(
      skill,
      share
    ),
    y = share
  )
) +
  geom_col() +
  coord_flip() +
  scale_y_continuous(
    labels = scales::percent_format(
      accuracy = 1
    )
  ) +
  labs(
    title =
      "Most Common Technical Skills in Data, AI, and ML Hiring Posts",
    
    subtitle =
      "Hacker News: Who is hiring? — September 2026",
    
    x = NULL,
    
    y =
      "Share of relevant hiring posts",
    
    caption =
      "Source: Hacker News"
  ) +
  theme_minimal()


# Display plot in RStudio
skill_plot


# ------------------------------------------------------------
# 24. Save plot
# ------------------------------------------------------------

ggsave(
  filename = plot_file,
  plot = skill_plot,
  width = 8,
  height = 5,
  dpi = 300
)


# ------------------------------------------------------------
# 25. Validation checks
# ------------------------------------------------------------

stopifnot(
  nrow(jobs_raw) > 0
)

stopifnot(
  nrow(data_jobs) > 0
)

stopifnot(
  nrow(skill_results) > 0
)


# ------------------------------------------------------------
# 26. Print summary
# ------------------------------------------------------------

cat(
  "\n--- ANALYSIS SUMMARY ---\n"
)

cat(
  "\nTotal top-level hiring posts:",
  nrow(jobs_raw),
  "\n"
)

cat(
  "Data / AI / ML hiring posts:",
  nrow(data_jobs),
  "\n"
)

cat(
  "\n--- OUTPUT FILES ---\n"
)

cat(
  "\nRaw HTML:\n",
  raw_html_file,
  "\n"
)

cat(
  "\nTop-level hiring posts:\n",
  top_level_file,
  "\n"
)

cat(
  "\nData / AI / ML hiring posts:\n",
  data_jobs_file,
  "\n"
)

cat(
  "\nSkill frequency table:\n",
  skill_file,
  "\n"
)

cat(
  "\nFinal figure:\n",
  plot_file,
  "\n"
)