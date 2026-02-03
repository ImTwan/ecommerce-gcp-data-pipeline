# End-to-End Data Engineering Pipeline on GCP using Glamira dataset
# 📌 Project Overview
This project implements a production-style, end-to-end data engineering pipeline using Google Cloud Platform (GCP). </br>
It covers the project's workflow:

<img src="assets\workflow.PNG" alt="image" width="1000"/>

The pipeline processes large-scale MongoDB data, enriches it with IP geolocation, loads it into BigQuery, transforms it using dbt, and prepares analytics-ready datasets for BI reporting (Looker).

# 🏗️ Architecture Overview
Workflow summary:
## 1. Data Source
* MongoDB collections (user activity & product events)
* External IP geolocation binary database
* Raw compressed datasets
## 2. Extract & Process (VM + Python)
* Crawl and extract product & IP data
* Enrich IPs with country / region / city
* Output intermediate results as JSON and CSV
## 3. Data Lake (Google Cloud Storage)
* Store raw and processed data files
* Serve as the ingestion layer for BigQuery
## 4. Event Triggering
* Cloud Function triggers BigQuery load jobs on new files
## 5. Data Warehouse (BigQuery)
* Raw tables
* Analytics-ready tables
## 6. Transformation (dbt)
* Dimensional modeling (fact & dimension tables)
* Data quality tests
## 7. Analytics
* Data consumed by Looker dashboards
# 📁 Project Structure
<pre>
.
├── data_source/                 # External raw inputs
│   ├── dataset/
│   │   ├── glamira_ubl_oct2019_nov2019.tar.gz
│   │   └── IP-COUNTRY-REGION-CITY.BIN
│
├── log/                         # Pipeline logs
│   └── export_to_gcs.log
│
├── tmp/                         # Intermediate processing outputs
│   ├── summary_export/
│   ├── ip_location_results.jsonl
│   ├── product_ids_to_crawl.jsonl
│   └── product_info.jsonl
│
├── extract_data/                # Data extraction & enrichment
│   └── src/
│       ├── retrieve_data.py     # Extract MongoDB data
│       ├── ip_location.py       # IP geolocation enrichment
│       └── crawl_data.py        # Product details crawling
│
├── loading_data/                # Load data into GCP
│   └── src/
│       ├── export_csv_files.py  # Convert CSV → JSONL
│       ├── export.py            # Upload data to GCS
│       ├── load_data.py         # Load GCS → BigQuery
│       └── trigger_bigquery_test_on_GCP.py
│
├── outputs/                     # Final extracted data
│   ├── ip_location_results.csv
│   ├── product_ids_to_crawl.csv
│   └── product_info.csv
│
├── transformation/
│   └── glamira_dbt/             # dbt 
│       ├── models/
│       │   ├── staging/
│       │   └── marts/
│       ├── seeds/
│       ├── tests/
│       ├── macros/
│       ├── dbt_project.yml
│       └── README.md
│
├── README.md                    # Project documentation


</pre>

# ⚙️ Data Processing Details
## 1. Data Extraction
* Processed 40M+ MongoDB documents
* Extracted 3.2M+ unique IP addresses
* Enriched IPs using a local binary IP database
* Extracted ~20,000 product IDs and ~18,000 valid products after crawling

## 2. Data Loading 
* JSONL, CSV files uploaded to Google Cloud Storage
* Cloud Function triggers BigQuery load jobs
* Raw tables created in BigQuery

## 3. Data Transformation (dbt)
* Implemented ELT approach
* ERD diagram:
<img src="assets\ERD.png" alt="image" width="1000"/>
* Built:
  * Fact tables (e.g. fact_sales_order)
  * Dimension tables (e.g. dim_customers, dim_store, dim_date, etc.)
* Applied:
  * Deduplication
  * Surrogate keys
  * Data quality tests

# 🧪 Data Quality & Testing
* Schema validation in BigQuery
* dbt tests:
  * Primary key checks
  * Not-null constraints
  * Relationship tests
* Profiling:
  * Null counts
  * Distinct values
  * Type consistency

# Looker Visualization
<img src="assets\1.PNG" alt="image" width="1000"/>
<img src="assets\2.PNG" alt="image" width="1000"/>
<img src="assets\3.PNG" alt="image" width="1000"/>
<img src="assets\4.PNG" alt="image" width="1000"/>

# 🛠️ Tech Stack
* Languages: Python, SQL
* Cloud: Google Cloud Platform
  * Compute Engine (VM)
  * Cloud Storage
  * Cloud Functions
  * BigQuery
* Database: MongoDB
* Transformation: dbt
* Visualization: Looker

# 🎯 Key Takeaways
* Designed a real-world, production-style data pipeline
* Handled large-scale semi-structured data
* Used event-driven architecture on GCP
* Applied dimensional modeling best practices
* Fully reproducible and modular pipeline

# Reference
For more detail about every in the project:
* Extract: https://github.com/ImTwan/Data-Collection-Storage.git
* Loading: https://github.com/ImTwan/Data-Pipeline-Storage.git
* Transform: https://github.com/ImTwan/Data-Transformation-Visualization-DBT.git
* Link to the project's dataset: https://drive.google.com/drive/folders/1V2_LSDwkKMJn2_fF8UfjKngk3QcIvRdd?usp=sharing
