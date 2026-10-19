
from pathlib import Path
import os
import zipfile

import requests
import pandas as pd
import geopandas as gpd
import matplotlib.pyplot as plt

root = Path(__file__).resolve().parent.parent
raw_dir = root / "data" / "raw"
derived_dir = root / "data" / "derived"
image_dir = root / "images"

for folder in [raw_dir, derived_dir, image_dir]:
    folder.mkdir(parents=True, exist_ok=True)


# County boundaries

url = "https://www2.census.gov/geo/tiger/GENZ2024/shp/cb_2024_us_county_500k.zip"

zip_path = raw_dir / "cb_2024_us_county_500k.zip"
shp_dir = raw_dir / "county_boundaries_2024"
shp_file = shp_dir / "cb_2024_us_county_500k.shp"

if not zip_path.exists():
    response = requests.get(url, timeout=120)
    response.raise_for_status()
    zip_path.write_bytes(response.content)

if not shp_file.exists():
    shp_dir.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(zip_path) as z:
        z.extractall(shp_dir)

counties = gpd.read_file(shp_file)
pa_counties = counties[counties["STATEFP"] == "42"].copy()

print("PA counties:", len(pa_counties))
print("CRS:", pa_counties.crs)

assert len(pa_counties) == 67


# ACS poverty data

api_key = os.getenv("CENSUS_API_KEY")

if not api_key:
    raise RuntimeError("Set CENSUS_API_KEY in Terminal first.")

acs_url = "https://api.census.gov/data/2024/acs/acs5"

params = {
    "get": "NAME,B17001_001E,B17001_002E",
    "for": "county:*",
    "in": "state:42",
    "key": api_key
}

response = requests.get(
    acs_url,
    params=params,
    timeout=60,
    allow_redirects=False
)

if response.status_code != 200:
    raise RuntimeError(
        f"Census API returned status {response.status_code}. Check your API key."
    )

if "json" not in response.headers.get("Content-Type", "").lower():
    raise RuntimeError("Census API did not return JSON.")

data = response.json()
poverty = pd.DataFrame(data[1:], columns=data[0])

poverty.to_csv(
    raw_dir / "acs_2024_pa_county_poverty.csv",
    index=False
)

poverty["GEOID"] = poverty["state"] + poverty["county"]

poverty["total_pop"] = pd.to_numeric(
    poverty["B17001_001E"],
    errors="coerce"
)

poverty["below_poverty"] = pd.to_numeric(
    poverty["B17001_002E"],
    errors="coerce"
)

poverty["poverty_rate"] = (
    poverty["below_poverty"] /
    poverty["total_pop"] * 100
)

print("ACS counties:", len(poverty))
print("Missing poverty rates:", poverty["poverty_rate"].isna().sum())

assert len(poverty) == 67
assert poverty["poverty_rate"].notna().all()


# Merge with county boundaries

pa_poverty = pa_counties.merge(
    poverty[["GEOID", "total_pop", "below_poverty", "poverty_rate"]],
    on="GEOID",
    how="left",
    validate="one_to_one"
)

print("Merged counties:", len(pa_poverty))
print("Unmatched counties:", pa_poverty["poverty_rate"].isna().sum())

assert len(pa_poverty) == 67
assert pa_poverty["poverty_rate"].notna().all()

pa_poverty[
    ["GEOID", "NAME", "total_pop", "below_poverty", "poverty_rate"]
].to_csv(
    derived_dir / "blog5_pa_county_poverty.csv",
    index=False
)

pa_poverty.to_file(
    derived_dir / "blog5_pa_county_poverty.gpkg",
    driver="GPKG"
)


# Check the results

print("\nHighest poverty rates:")

print(
    pa_poverty[["NAME", "poverty_rate"]]
    .sort_values("poverty_rate", ascending=False)
    .head(10)
    .to_string(index=False)
)

print("\nLowest poverty rates:")

print(
    pa_poverty[["NAME", "poverty_rate"]]
    .sort_values("poverty_rate")
    .head(10)
    .to_string(index=False)
)


# Map

pa_map = pa_poverty.to_crs("EPSG:5070")

fig, ax = plt.subplots(figsize=(11, 7))

pa_map.plot(
    column="poverty_rate",
    cmap="YlOrRd",
    legend=True,
    edgecolor="white",
    linewidth=0.5,
    legend_kwds={
        "label": "Population below poverty line (%)",
        "shrink": 0.7
    },
    ax=ax
)

ax.set_title(
    "Poverty Rates Across Pennsylvania Counties",
    fontsize=16,
    pad=18
)

ax.set_axis_off()

ax.text(
    0.5, -0.02,
    "Source: U.S. Census Bureau, 2024 ACS 5-year estimates",
    transform=ax.transAxes,
    ha="center",
    fontsize=9
)

plt.savefig(
    image_dir / "blog5_pa_poverty_map.png",
    dpi=300,
    bbox_inches="tight"
)

plt.show()

# Figure 2: Highest and lowest poverty rates

highest = pa_poverty.nlargest(10, "poverty_rate")
highest = highest.sort_values("poverty_rate")

lowest = pa_poverty.nsmallest(10, "poverty_rate")
lowest = lowest.sort_values("poverty_rate", ascending=False)

fig, axes = plt.subplots(1, 2, figsize=(14, 7), sharex=True)

bars1 = axes[0].barh(
    highest["NAME"],
    highest["poverty_rate"],
    color="tomato"
)

axes[0].set_title("10 Highest Poverty Rates")
axes[0].set_xlabel("Poverty rate (%)")
axes[0].bar_label(bars1, fmt="%.1f%%", padding=3)

bars2 = axes[1].barh(
    lowest["NAME"],
    lowest["poverty_rate"],
    color="steelblue"
)

axes[1].set_title("10 Lowest Poverty Rates")
axes[1].set_xlabel("Poverty rate (%)")
axes[1].bar_label(bars2, fmt="%.1f%%", padding=3)

for ax in axes:
    ax.set_xlim(0, pa_poverty["poverty_rate"].max() + 3)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)

fig.suptitle(
    "County Poverty Rates in Pennsylvania",
    fontsize=16
)

fig.text(
    0.5, 0.02,
    "Source: U.S. Census Bureau, 2024 ACS 5-year estimates",
    ha="center",
    fontsize=9
)

plt.tight_layout(rect=[0, 0.05, 1, 0.93])

plt.savefig(
    image_dir / "blog5_pa_poverty_ranking.png",
    dpi=300,
    bbox_inches="tight"
)

plt.show()
