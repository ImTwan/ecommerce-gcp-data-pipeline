from pymongo import MongoClient
from tqdm import tqdm
import IP2Location
import csv

MONGO_URI = "mongodb://34.134.190.155:27017/"
DB_NAME = "countly"
MAIN_COLLECTION = "summary"
OUTPUT_COLLECTION = "ip_location_results"
OUTPUT_CSV = "D:\python_try_hard\unigap\glamira_project\outputs\ip_location_results.csv"
BIN_FILE = r"D:\python_try_hard\unigap\glamira_project\data_source\dataset\IP-COUNTRY-REGION-CITY.BIN"
BATCH_SIZE = 50000

def process_ip_locations():
    client = MongoClient(MONGO_URI)
    db = client[DB_NAME]
    col = db[MAIN_COLLECTION]
    out_col = db[OUTPUT_COLLECTION]

    print("📥 Fetching unique IPs via aggregation...")
    pipeline = [
        {"$group": {"_id": "$ip"}},  # group by IP
        {"$project": {"_id": 0, "ip": "$_id"}}
    ]
    cursor = col.aggregate(pipeline, allowDiskUse=True)

    ip2 = IP2Location.IP2Location(BIN_FILE)

    csv_file = open(OUTPUT_CSV, "w", newline="", encoding="utf-8")
    writer = csv.writer(csv_file)
    writer.writerow(["ip", "country", "region", "city"])

    batch = []
    count = 0
    for doc in tqdm(cursor):
        ip = doc["ip"]
        try:
            rec = ip2.get_all(ip)
            data = {
                "ip": ip,
                "country": rec.country_long,
                "region": rec.region,
                "city": rec.city
            }
            batch.append(data)
            writer.writerow([ip, rec.country_long, rec.region, rec.city])
            count += 1

            if len(batch) >= BATCH_SIZE:
                out_col.insert_many(batch)
                batch = []

        except Exception:
            continue

    if batch:
        out_col.insert_many(batch)

    csv_file.close()
    print(f"🎉 DONE! Processed {count:,} unique IPs. Results saved to CSV + MongoDB collection.")

if __name__ == "__main__":
    process_ip_locations()
