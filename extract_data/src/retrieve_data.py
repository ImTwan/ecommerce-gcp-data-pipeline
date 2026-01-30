from pymongo import MongoClient
from tqdm import tqdm
import csv

MONGO_URL = "mongodb://34.134.190.155:27017/"
DB_NAME = "countly"
COLLECTION = "summary"

OUTPUT_FILE = "D:\python try hard\project5\Project-05-Data-Collection-Storage-Foundation\csv files result\product_ids_to_crawl.csv"

TARGET_COLLECTIONS = {
    "view_product_detail",
    "select_product_option",
    "select_product_option_quality",
    "add_to_cart_action",
    "product_detail_recommendation_visible",
    "product_detail_recommendation_noticed"
}

CLICK_EVENT = "product_view_all_recommend_clicked"

client = MongoClient(MONGO_URL)
db = client[DB_NAME]

unique_products = {}   # product_id → url

def add_entry(pid, url):
    if pid and url and pid not in unique_products:
        unique_products[pid] = url

print("📌 Counting documents...")
est_total = db.summary.estimated_document_count()
print(f"📌 Total documents: {est_total:,}")

cursor = db.summary.find(
    {
        "collection": {
            "$in": list(TARGET_COLLECTIONS) + [CLICK_EVENT]
        }
    },
    {
        "collection": 1,
        "product_id": 1,
        "viewing_product_id": 1,
        "current_url": 1,
        "referrer_url": 1
    }
).batch_size(5000)

print("🚀 Extracting product IDs...")

for doc in tqdm(cursor, total=est_total):
    event = doc.get("collection")

    if event in TARGET_COLLECTIONS:
        pid = doc.get("product_id") or doc.get("viewing_product_id")
        url = doc.get("current_url")
        add_entry(pid, url)

    elif event == CLICK_EVENT:
        pid = doc.get("viewing_product_id")
        url = doc.get("referrer_url")
        add_entry(pid, url)

print(f"✅ Unique product IDs found: {len(unique_products):,}")

with open(OUTPUT_FILE, "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(["product_id", "url"])
    for pid, url in unique_products.items():
        writer.writerow([pid, url])

print("📦 Saved:", OUTPUT_FILE)