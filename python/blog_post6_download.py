
from pathlib import Path
import zipfile
import requests

root = Path(__file__).resolve().parent.parent
raw_dir = root / "data" / "raw"
raw_dir.mkdir(parents=True, exist_ok=True)

datasets = {
    "nlsy79_all_1979-2022.zip":
        "https://nlsinfo.org/cohort-data/nlsy79_all_1979-2022.zip",

    "nlscya_all_1979-2020.zip":
        "https://nlsinfo.org/cohort-data/nlscya_all_1979-2020.zip"
}

for filename, url in datasets.items():

    file_path = raw_dir / filename
    temp_path = raw_dir / (filename + ".part")

    if file_path.exists() and zipfile.is_zipfile(file_path):
        print(f"{filename} already exists. Skipping.")
        continue

    print(f"\nDownloading {filename}...")

    with requests.get(url, stream=True, timeout=(30, 120)) as response:
        response.raise_for_status()

        with open(temp_path, "wb") as file:
            for chunk in response.iter_content(chunk_size=1024 * 1024):
                if chunk:
                    file.write(chunk)

    if not zipfile.is_zipfile(temp_path):
        raise ValueError(f"Invalid ZIP file: {filename}")

    temp_path.replace(file_path)

    print(f"Saved to: {file_path}")

print("\nAll downloads complete.")
