# Extract data
## A. SET UP
## 1. Local environment requirements:
* Visual Studio Code editor.
* Python 3.11.
* Python library: ip2location, requests, BeautifulSoup, pandas, time, concurrent.futures, pymongo, tqdm, csv, os

## 2. Folder structure:  
<pre>
extract_data
│
├── csv files result/
│       ├── ip_location_results.csv # IP result 
│       ├── product_ids_to_crawl.csv # Retrieve product_id and url
│       ├── product_info.csv # Crawl the product id 
│
│
└── src/
    ├── crawl_data.py # Step 6: Product name collection
    ├── ip_location.py # Step 5: IP Location Processing
    └── retrieve_data.py # Step 6: Product name collection


</pre>

## 3. Documenting GCS Setup
* Bucket name: twan-glamira
* Location: us-central1-a
* Storage class: Standard
* Public access: Not public
* Protection: Soft Delete enabled
* Encryption: Google-managed encryption keys
* Inside the bucket, I create a raw_data folder with this structure:
<pre>
twan-glamira/                           # GCS Bucket Name
└── raw_data/                        # Folder for raw data storage
    ├── IP-COUNTRY-REGION-CITY.BIN   # IP Geolocation Database (Binary)
    └── glamira_ubl_oct2019_nov2019.tar.gz  # Raw data archive file (October-November 2019)
</pre>

## 4. Google Cloud VM Setup
* Instance name: project5vm
* Zone:	us-central1-a
* Machine type: e2-standard-2 (2 vCPUs, 8 GB Memory)
* OS Image:	ubuntu-2204-jammy-v20251111
* Boot disk: 70 GB, Balanced Persistent Disk

## 5. MongoDB Installation & Configuration
MongoDB Community Edition 8.0 was installed following the official guide:

Reference:
https://www.mongodb.com/docs/v8.0/tutorial/install-mongodb-on-ubuntu/

* Import the public key.
```text
  sudo apt-get install gnupg curl
```
```text
  curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg \
   --dearmor
```
* Create the list file (Ubuntu 22.04(Jammy))
```text
  echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
```
* Install MongoDB
```text
sudo systemctl start mongod
sudo systemctl enable mongod
```
* Start & Enable the Service
```text
sudo systemctl start mongod
sudo systemctl enable mongod
```
* Verify MongoDB Installation
```text
sudo systemctl status mongod
mongosh
```
## 6. Initial Data Loading
* SSH into your VM on GCP and download data from GCS
```text
    gsutil cp gs://YOUR_BUCKET_NAME/glamira_ubl_oct2019_nov2019.tar.gz .
    gsutil cp gs://YOUR_BUCKET_NAME/IP-COUNTRY-REGION-CITY.BIN .
```
* Check file exists
```text
    ls 
```
* Extract the dataset
```text
    tar -xvzf glamira_ubl_oct2019_nov2019.tar.gz
```
* This will produce something like:
```text
    ~/glamira_ubl_oct2019_nov2019/dump/countly/
```
Inside, you should see .bson and .json
* Restore the MongoDB dump
Make sure MongoDB is running:
```text
    sudo systemctl start mongod
```
Run restore:
```text
    mongorestore --db countly --drop ~/glamira_dataset/dump/countly
```
* Validate import
```text
    mongosh
    show dbs
```
Check DB + collections
```text
    use countly
    show collections
```

## 7. IP Location Processing
* Install ip2location-python library
* Python script: ip_location.py
* Result:
📥 Fetching unique IPs via aggregation...
3239628it [03:59, 13504.83it/s]
🎉 DONE! Processed 3,239,628 unique IPs. Results saved to CSV + MongoDB collection.

## 8. Product name collection
* Filter data from collections: </br>
    `view_product_detail` </br>
    `select_product_option` </br>
    `select_product_option_quality` </br>
    `add_to_cart_action` </br>
    `product_detail_recommendation_visible` </br>
    `product_detail_recommendation_noticed` </br>

→ Retrieve `product_id` (or `viewing_product_id` if `product_id` is missing) and `current_url`

* Filter data from `product_view_all_recommend_clicked` → Retrieve `viewing_product_id` and `referrer_url`
* Result:</br>
Unique product IDs found: 19,417 </br>
📦 Saved: product_ids_to_crawl.csv

* Crawl the product name based on the above information; get **only one active `product name`** for each distinct `product_id`.
* Result: </br>
🎉 Validation complete! </br>
✔ Valid IDs: 14,445 </br>
✖ Invalid IDs: 4,972 </br>
💾 Saving valid IDs to valid_product_ids.csv... </br>
📦 Saved: valid_product_ids.csv </br>
✅ All done! </br>
