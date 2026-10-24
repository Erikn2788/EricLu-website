from pathlib import Path
import csv
import sqlite3
import zipfile
from io import TextIOWrapper

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import statsmodels.api as sm
import statsmodels.formula.api as smf


root = Path(__file__).resolve().parent.parent
raw_dir = root / "data" / "raw"
output_dir = root / "data" / "derived"
image_dir = root / "images"

output_dir.mkdir(parents=True, exist_ok=True)
image_dir.mkdir(parents=True, exist_ok=True)


# 1. Read selected variables from NLS ZIP files

mother_vars = {
    "R0000100": "mother_id",
    "R6479800": "age_1998",
    "R6364600": "earnings_1998",
    "R7007500": "age_2000",
    "R6909700": "earnings_2000",
    "R7704800": "age_2002",
    "R7607800": "earnings_2002",
    "R8497200": "age_2004",
    "R8316300": "earnings_2004"
}

child_vars = {
    "C0000100": "child_id",
    "C0000200": "mother_id",
    "Y2966400": "age_2012",
    "Y2921600": "earnings_2012",
    "Y3331900": "age_2014",
    "Y3291400": "earnings_2014",
    "Y3675700": "age_2016",
    "Y3631700": "earnings_2016",
    "Y4281700": "age_2018",
    "Y4240000": "earnings_2018",
    "Y4602700": "age_2020",
    "Y4561200": "earnings_2020"
}


def read_nls(zip_name, variables):
    path = raw_dir / zip_name

    with zipfile.ZipFile(path) as z:
        csv_name = next(
            n for n in z.namelist()
            if n.lower().endswith(".csv")
        )

        with z.open(csv_name) as f:
            text = TextIOWrapper(
                f, encoding="utf-8-sig",
                errors="replace", newline=""
            )
            reader = csv.reader(text)
            header = next(reader)

            positions = {
                name: i for i, name in enumerate(header)
                if name in variables
            }

            missing = set(variables) - set(positions)
            if missing:
                raise ValueError(f"Missing variables: {missing}")

            rows = []
            for row in reader:
                rows.append([
                    row[positions[name]]
                    for name in variables
                ])

    print(f"Loaded {len(rows):,} respondents from {zip_name}")
    return pd.DataFrame(rows, columns=list(variables.values()))


mothers = read_nls(
    "nlsy79_all_1979-2022.zip", mother_vars
)

children = read_nls(
    "nlscya_all_1979-2020.zip", child_vars
)


# 2. Prepare IDs and longitudinal income records

for col in mothers.columns:
    mothers[col] = pd.to_numeric(mothers[col], errors="coerce")

for col in children.columns:
    children[col] = pd.to_numeric(children[col], errors="coerce")

mothers = mothers[mothers["mother_id"] > 0].copy()
children = children[
    (children["mother_id"] > 0) &
    (children["child_id"] > 0)
].copy()

mothers["mother_id"] = mothers["mother_id"].astype(int)
children["mother_id"] = children["mother_id"].astype(int)
children["child_id"] = children["child_id"].astype(int)

assert mothers["mother_id"].is_unique
assert children["child_id"].is_unique


def make_long(df, ids, years):
    parts = []

    for year in years:
        part = df[
            ids + [f"age_{year}", f"earnings_{year}"]
        ].copy()

        part = part.rename(columns={
            f"age_{year}": "age",
            f"earnings_{year}": "earnings"
        })

        part["year"] = year
        parts.append(part)

    return pd.concat(parts, ignore_index=True)


mother_long = make_long(
    mothers, ["mother_id"], [1998, 2000, 2002, 2004]
)

child_long = make_long(
    children, ["child_id", "mother_id"],
    [2012, 2014, 2016, 2018, 2020]
)


# 3. CPI adjustment and SQL matching

cpi = pd.DataFrame({
    "income_year": [
        1997, 1999, 2001, 2003,
        2011, 2013, 2015, 2017, 2019
    ],
    "cpi": [
        160.5, 166.6, 177.1, 184.0,
        224.939, 232.957, 237.017,
        245.120, 255.657
    ]
})

cpi_2024 = 313.689

conn = sqlite3.connect(":memory:")

mother_long.to_sql("mother_income", conn, index=False)
child_long.to_sql("child_income", conn, index=False)
cpi.to_sql("cpi", conn, index=False)

query = """
WITH mother_valid AS (
    SELECT
        m.mother_id,
        m.year,
        m.earnings * (? / p.cpi) AS real_earnings
    FROM mother_income m
    JOIN cpi p ON m.year - 1 = p.income_year
    WHERE m.age BETWEEN 30 AND 40
      AND m.earnings > 0
),

mother_ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY mother_id
            ORDER BY year DESC
        ) AS rn
    FROM mother_valid
),

mother_summary AS (
    SELECT
        mother_id,
        COUNT(*) AS mother_years,
        AVG(real_earnings) AS mother_average,
        MAX(CASE WHEN rn = 1 THEN real_earnings END)
            AS mother_single
    FROM mother_ranked
    GROUP BY mother_id
    HAVING COUNT(*) >= 2
),

child_valid AS (
    SELECT
        c.child_id,
        c.mother_id,
        c.year,
        c.earnings * (? / p.cpi) AS real_earnings
    FROM child_income c
    JOIN cpi p ON c.year - 1 = p.income_year
    WHERE c.age BETWEEN 30 AND 40
      AND c.earnings > 0
),

child_ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY child_id
            ORDER BY year DESC
        ) AS rn
    FROM child_valid
),

child_summary AS (
    SELECT
        child_id,
        mother_id,
        COUNT(*) AS child_years,
        AVG(real_earnings) AS child_average,
        MAX(CASE WHEN rn = 1 THEN real_earnings END)
            AS child_single
    FROM child_ranked
    GROUP BY child_id, mother_id
    HAVING COUNT(*) >= 2
)

SELECT
    c.child_id,
    c.mother_id,
    m.mother_single,
    c.child_single,
    m.mother_average,
    c.child_average
FROM child_summary c
JOIN mother_summary m
    ON c.mother_id = m.mother_id
"""

pairs = pd.read_sql_query(
    query, conn, params=(cpi_2024, cpi_2024)
)

print("\nMatched pairs:", len(pairs))
print("Unique mothers:", pairs["mother_id"].nunique())


# 4. Estimate single-year and multi-year IGE

def estimate_ige(x, y, groups):
    model = sm.OLS(
        np.log(y),
        sm.add_constant(np.log(x))
    ).fit(
        cov_type="cluster",
        cov_kwds={"groups": groups}
    )
    return model


single = estimate_ige(
    pairs["mother_single"],
    pairs["child_single"],
    pairs["mother_id"]
)

average = estimate_ige(
    pairs["mother_average"],
    pairs["child_average"],
    pairs["mother_id"]
)


def summarize(model, method):
    ci = model.conf_int().iloc[1]

    return {
        "method": method,
        "ige": model.params.iloc[1],
        "std_error": model.bse.iloc[1],
        "p_value": model.pvalues.iloc[1],
        "ci_lower": ci.iloc[0],
        "ci_upper": ci.iloc[1],
        "n_pairs": int(model.nobs)
    }


results = pd.DataFrame([
    summarize(single, "Single-year earnings"),
    summarize(average, "Multi-year average earnings")
])

print("\nIGE comparison:")
print(results.round(4).to_string(index=False))

results.to_csv(
    output_dir / "blog6_ige_comparison.csv",
    index=False
)


# Figure 1: IGE comparison

fig, ax = plt.subplots(figsize=(9, 5))

errors = np.vstack([
    results["ige"] - results["ci_lower"],
    results["ci_upper"] - results["ige"]
])

ax.barh(results["method"], results["ige"], alpha=0.75)

ax.errorbar(
    results["ige"], results["method"],
    xerr=errors, fmt="none",
    ecolor="black", capsize=5
)

ax.axvline(0, color="black", linewidth=0.8)
ax.invert_yaxis()
ax.set_xlabel("Estimated IGE")
ax.set_title("Intergenerational Earnings Elasticity")
ax.spines["top"].set_visible(False)
ax.spines["right"].set_visible(False)

fig.text(
    0.5, 0.01,
    "Source: NLSY79 and NLSY79 Child/Young Adult. "
    "95% confidence intervals.",
    ha="center", fontsize=9
)

plt.tight_layout(rect=[0, 0.05, 1, 1])

fig.savefig(
    image_dir / "blog6_ige_comparison.png",
    dpi=300, bbox_inches="tight"
)

plt.close(fig)


# 5. Life-cycle analysis using the same matched sample

pairs[
    ["child_id", "mother_id", "mother_average"]
].to_sql("matched_pairs", conn, index=False)

lifecycle_query = """
SELECT
    c.child_id,
    c.mother_id,
    c.year,
    c.age,
    m.mother_average AS mother_earnings,
    c.earnings * (? / p.cpi) AS child_earnings
FROM child_income c
JOIN matched_pairs m
    ON c.child_id = m.child_id
   AND c.mother_id = m.mother_id
JOIN cpi p
    ON c.year - 1 = p.income_year
WHERE c.age BETWEEN 25 AND 40
  AND c.earnings > 0
"""

life = pd.read_sql_query(
    lifecycle_query, conn, params=(cpi_2024,)
)

conn.close()

life["log_mother"] = np.log(life["mother_earnings"])
life["log_child"] = np.log(life["child_earnings"])
life["age_c"] = life["age"] - 30

model = smf.ols(
    "log_child ~ log_mother * age_c + C(year)",
    data=life
).fit(
    cov_type="cluster",
    cov_kwds={"groups": life["mother_id"]}
)

print("\nLife-cycle analysis:")
print("Child-year observations:", len(life))
print("IGE at age 30:", round(model.params["log_mother"], 4))
print(
    "Age interaction:",
    round(model.params["log_mother:age_c"], 4)
)
print(
    "Age interaction p-value:",
    round(model.pvalues["log_mother:age_c"], 4)
)


# Figure 2: IGE by child's age

terms = ["log_mother", "log_mother:age_c"]

beta = model.params[terms].to_numpy()
cov = model.cov_params().loc[terms, terms].to_numpy()

age_results = []

for age in range(25, 41):
    weights = np.array([1, age - 30])
    ige = weights @ beta
    se = np.sqrt(weights @ cov @ weights)

    age_results.append({
        "age": age,
        "ige": ige,
        "ci_lower": ige - 1.96 * se,
        "ci_upper": ige + 1.96 * se
    })

age_results = pd.DataFrame(age_results)

age_results.to_csv(
    output_dir / "blog6_ige_by_age.csv",
    index=False
)

fig, ax = plt.subplots(figsize=(9, 5))

ax.plot(
    age_results["age"],
    age_results["ige"],
    linewidth=2.5,
    label="Estimated IGE"
)

ax.fill_between(
    age_results["age"],
    age_results["ci_lower"],
    age_results["ci_upper"],
    alpha=0.2,
    label="95% confidence interval"
)

ax.axhline(0, color="gray", linestyle="--", linewidth=0.8)

ax.set_title("How Does Estimated IGE Change with Child's Age?")
ax.set_xlabel("Child's age")
ax.set_ylabel("Estimated mother-child earnings elasticity")
ax.set_xticks([25, 30, 35, 40])
ax.legend(frameon=False)

ax.spines["top"].set_visible(False)
ax.spines["right"].set_visible(False)

fig.text(
    0.5, 0.01,
    "Source: NLSY79 and NLSY79 Child/Young Adult. "
    "Clustered 95% confidence intervals.",
    ha="center", fontsize=9
)

plt.tight_layout(rect=[0, 0.05, 1, 1])

fig.savefig(
    image_dir / "blog6_ige_by_age.png",
    dpi=300, bbox_inches="tight"
)

plt.close(fig)

print("\nBoth figures saved successfully.")
