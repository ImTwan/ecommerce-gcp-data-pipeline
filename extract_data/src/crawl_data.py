import csv
import requests
import re
import json
import random
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from tqdm import tqdm

INPUT = r"D:\python try hard\unigap\project5\Project-05-Data-Collection-Storage-Foundation\csv files result\product_ids_to_crawl.csv"
OUTPUT = r"D:\python try hard\unigap\project5\Project-05-Data-Collection-Storage-Foundation\csv files result\product_info.csv"

HEADERS_LIST = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
    "Mozilla/5.0 (iPhone; CPU iPhone OS 16_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.4 Mobile/15E148 Safari/604.1",
]

FIELDS = [
    "product_id","name","product_type","sku","price","min_price","max_price",
    "qty","collection_id","collection","category","category_name","store_code","gender"
]

MAX_WORKERS = 30          # increase concurrency
MAX_RETRIES = 5           # more retries for network errors
SLEEP_BETWEEN_REQUESTS = (0.5, 1.2)
TLD_LIST = ["fr","com","co.uk","de","ae"]  # extend as needed
SHOW_EACH_URL = False

def clean_react_data(raw):
    raw = raw.replace("undefined", "null")
    raw = re.sub(r"(\w+)\s*:", r'"\1":', raw)
    raw = re.sub(r":\s*'([^']*)'", r': "\1"', raw)
    raw = re.sub(r",\s*}", "}", raw)
    raw = re.sub(r",\s*]", "]", raw)
    return raw

def extract_product_info(product_id):
    for tld in TLD_LIST:
        url = f"https://www.glamira.{tld}/catalog/product/view/id/{product_id}"
        if SHOW_EACH_URL:
            print(f"🔍 Checking: {url}")

        for attempt in range(1, MAX_RETRIES + 1):
            try:
                time.sleep(random.uniform(*SLEEP_BETWEEN_REQUESTS))
                r = requests.get(url, headers={"User-Agent": random.choice(HEADERS_LIST)}, timeout=20)
                if r.status_code != 200:
                    continue

                match = re.search(r"var\s+react_data\s*=\s*(\{.*?\});", r.text, re.DOTALL)
                if not match:
                    continue

                raw_json = match.group(1)
                try:
                    data = json.loads(raw_json)
                except json.JSONDecodeError:
                    data = json.loads(clean_react_data(raw_json))

                # Skip if essential fields are missing
                if not data.get("product_id") or not data.get("name"):
                    continue

                return {
                    "product_id": product_id,
                    "name": data.get("name",""),
                    "product_type": data.get("product_type",""),
                    "sku": data.get("sku",""),
                    "price": float(data.get("price") or 0),
                    "min_price": float(data.get("min_price") or 0),
                    "max_price": float(data.get("max_price") or 0),
                    "qty": int(data.get("qty") or 1),
                    "collection_id": data.get("collection_id",""),
                    "collection": data.get("collection",""),
                    "category": data.get("category",""),
                    "category_name": data.get("category_name",""),
                    "store_code": data.get("store_code","glgb"),
                    "gender": data.get("gender","")
                }

            except Exception:
                if attempt < MAX_RETRIES:
                    time.sleep(2 ** attempt)
                else:
                    break  # move to next TLD

    return None  # failed after all TLDs

# Load product IDs
with open(INPUT, "r", encoding="utf-8") as f:
    rows = list(csv.DictReader(f))
product_ids = [row["product_id"] for row in rows]

print(f"📌 Total product IDs loaded: {len(product_ids):,}")
print("🚀 Starting extraction...")

detailed_products = []
failed_ids = []

# First pass
with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
    futures = {executor.submit(extract_product_info, pid): pid for pid in product_ids}
    for future in tqdm(as_completed(futures), total=len(futures), desc="Extracting"):
        result = future.result()
        if result:
            detailed_products.append(result)
        else:
            failed_ids.append(futures[future])

# Retry failed products until no more succeed
retry_round = 5
for r in range(retry_round):
    if not failed_ids:
        break
    print(f"🔄 Retry round {r+1} for {len(failed_ids)} failed products")
    temp_failed = []
    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        futures = {executor.submit(extract_product_info, pid): pid for pid in failed_ids}
        for future in tqdm(as_completed(futures), total=len(futures), desc=f"Retrying {r+1}"):
            result = future.result()
            if result:
                detailed_products.append(result)
            else:
                temp_failed.append(futures[future])
    failed_ids = temp_failed

print(f"\n🎉 Extraction complete! Total products extracted: {len(detailed_products):,}")

# Save only fully extracted products
with open(OUTPUT, "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=FIELDS)
    writer.writeheader()
    for product in detailed_products:
        writer.writerow(product)

print("📦 Saved:", OUTPUT)
print("✅ All done! ✅")
