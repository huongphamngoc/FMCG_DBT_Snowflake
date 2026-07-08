# FMCG Data Pipeline: Airflow, dbt & Snowflake

## 📌 Project Overview
This project implements a Modern Data Stack (MDS) pipeline for a Fast-Moving Consumer Goods (FMCG) company. It extracts raw CSV data from an AWS S3 stage, loads it into a Snowflake Data Warehouse, and transforms it into a production-ready Star Schema using **dbt (Data Build Tool)**. The entire workflow is orchestrated via **Apache Airflow** using the Astronomer Astro CLI and **Astronomer Cosmos**.

## 🏗️ Architecture & Tech Stack
* **Storage:** AWS S3 (External Stage)
* **Data Warehouse:** Snowflake
* **Orchestration:** Apache Airflow (via Astro CLI)
* **Transformation:** dbt (Data Build Tool)
* **Integration:** Astronomer Cosmos (translates dbt models into Airflow Tasks)
* **Containerization:** Docker & Astro Runtime (`astrocrpublic.azurecr.io/runtime:3.0-5`)

## 📂 Project Structure
```text
FMCG_DBT_Snowflake/
├── dags/
│   ├── cosmos_snowflake_dbt.py      # Main DAG orchestrating ELT workflow
│   └── dbt/
│       └── dbt_FMCG/                # dbt project directory
│           ├── models/
│           │   ├── staging/         # Bronze Layer: Cleaned source views
│           │   ├── intermediate/    # Silver Layer: Denormalized & joined data
│           │   └── marts/           # Gold Layer: Fact & Dimension tables
│           ├── dbt_project.yml      # dbt configuration file
│           └── packages.yml         # dbt dependencies (dbt_utils)
├── Dockerfile                       # Custom image installing dbt-snowflake in a venv
├── requirements.txt                 # Airflow providers & Astronomer Cosmos
└── .astro/                          # Astro CLI configurations

```

## 🔄 Data Modeling (Medallion Architecture)

The dbt project transforms data through three distinct layers, defined in `dbt_project.yml`:

1. **Bronze Layer (Staging) - `stg` schema:** - Materialized as `view`.
* Cleans and standardizes raw data from the `RAW.FMCG` database.
* Models: `stg_fmcg_categories`, `stg_fmcg_cities`, `stg_fmcg_countries`, `stg_fmcg_customers`, `stg_fmcg_employees`, `stg_fmcg_products`, `stg_fmcg_sales`.


2. **Silver Layer (Intermediate) - `int` schema:** - Materialized as `ephemeral`.
* Resolves complex logic and denormalizes lookup tables.
* Models: `int_locations_joined` (combines cities and countries).


3. **Gold Layer (Marts) - `marts` schema:** - Materialized as `table`.
* Business-ready tables optimized for BI tools (Star Schema).
* **Dimensions:** `dim_customers`, `dim_employees`, `dim_products`.
* **Facts:** `fct_sales` (One Big Table containing transactional logic, net revenue calculations, and time dimensions).



## 🚀 Airflow DAG Details

**DAG ID:** `DbtDag_FMCG_snowflake`

* **Schedule:** `@daily`
* **Workflow:**
1. **Data Loading (EL):** Executes `COPY INTO` commands using `SQLExecuteQueryOperator` to load 7 CSV files (Categories, Cities, Countries, Products, Customers, Employees, Sales) from an external S3 stage (`@RAW.FMCG.my_s3_stage_direct`) into Snowflake raw tables.
2. **Data Transformation (T):** Once all data is successfully loaded, Airflow triggers the dbt transformation pipeline using Cosmos `DbtTaskGroup`. Cosmos automatically parses the dbt project and runs the models while respecting their dependencies.



## 🛠️ Setup & Local Development

### Prerequisites

* Docker installed and running.
* [Astro CLI](https://www.google.com/search?q=https://docs.astronomer.io/astro/cli/install-cli) installed.
* A Snowflake account with the `RAW` database and `FMCG` schema configured.

### Instructions

1. **Clone the repository:**
```bash
git clone <repository-url>
cd fmcg_dbt_snowflake

```


2. **Configure Snowflake Connection:**
Create a .env file in the project root directory (you can copy .env_example if available) and configure your Airflow connection to Snowflake.

Astronomer Cosmos uses this connection to execute dbt models.
```env
DBT_ROOT_PATH="include/dbt"

# Snowflake Connection string for Airflow/Cosmos
AIRFLOW_CONN_SNOWFLAKE_DEFAULT='{
    "conn_type": "snowflake",
    "login": "<your_snowflake_username>",
    "password": "<your_snowflake_password>",
    "schema": "<your_schema>",
    "extra": {
        "account": "<your_account_identifier>",
        "warehouse": "<your_warehouse>",
        "database": "<your_database>",
        "region": "<your_region>",
        "role": "<your_role>"
    }
}'

```


3. **Start the Airflow environment:**
The `Dockerfile` is configured to create a dedicated Python virtual environment named `dbt_venv_snowflake` specifically for `dbt-snowflake`.

This approach prevents dependency conflicts between:

* Airflow providers
* dbt adapters

Start the local environment:

```bash
astro dev start
```

> **Note:** If you modify the `Dockerfile` or `requirements.txt`, rebuild the environment using:

```bash
astro dev restart
```
*Note: The `Dockerfile` automatically sets up a Python virtual environment (`dbt_venv`) and installs `dbt-snowflake` to ensure compatibility and isolation for Cosmos.*


4. **Access Airflow UI:**
Once the containers are running, access the Airflow UI:

| Setting  | Value                 |
| -------- | --------------------- |
| URL      | http://localhost:8080 |
| Username | admin                 |
| Password | admin                 |

5. **Run the Pipeline:**

*Open the Airflow UI.
*Locate the DAG named:

```text
DbtDag_FMCG_snowflake
```

Defined in:

```text
dags/cosmos_snowflake_dbt.py
```
*Unpause the DAG using the toggle switch.
*Click **Trigger DAG** (▶ Play button).

## 🛑 Stopping the Environment

Stop the running containers while preserving DAG history and metadata:

```bash
astro dev stop
```

Perform a complete reset and remove all local Airflow metadata:

```bash
astro dev kill
```

---


## 🧪 Testing & Quality Assurance

Data quality is enforced using built-in dbt tests defined in `schema.yml` files. Tests include:

* `not_null` and `unique` checks on primary keys (e.g., `SalesID`, `CustomerID`).
* Foreign key relationship tests between the Fact table and Dimension tables.
* Custom generic macros (e.g., `is_non_negative`) ensuring metrics like `Price`, `Quantity`, and `Discount` are logically valid.


