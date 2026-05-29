# Customer 360 Data Pipeline: dbt, Snowflake & Airflow (via Cosmos)

This repository contains a modern Data Engineering pipeline designed to build a comprehensive **Customer 360** view for a financial institution. It leverages **dbt (Data Build Tool)** for data transformation, **Snowflake** as the cloud data warehouse, and **Apache Airflow** (using **Astronomer Cosmos**) for seamless orchestration.

## 🚀 Tech Stack & Architecture

* **Orchestration:** [Apache Airflow](https://airflow.apache.org/) (managed via [Astro CLI](https://docs.astronomer.io/astro/cli/overview))
* **Transformation:** [dbt-core](https://www.getdbt.com/) & `dbt-snowflake`
* **Data Warehouse:** [Snowflake](https://www.snowflake.com/)
* **Integration:** [Astronomer Cosmos](https://astronomer.github.io/astronomer-cosmos/) (Dynamically converts dbt projects into Airflow DAGs)

## 📁 Project Structure

The project follows dbt best practices, organizing data transformations into distinct layers:

```text
customer_360_snowflake/
├── Dockerfile                  # Astro Runtime image & dbt virtual env setup
├── requirements.txt            # Airflow providers (Cosmos, Snowflake)
├── dags/
│   ├── cosmos_snowflake_dbt.py # Airflow DAG using Cosmos DbtDag
│   └── dbt/customer_360_snowflake/
│       ├── dbt_project.yml     # dbt project configuration
│       ├── seeds/              # Reference data (CSV mappings, risk ratings, etc.)
│       └── models/
│           ├── staging/        # Base layer: Raw data cleansing & standardization
│           ├── intermediate/   # Logic layer: Aggregations, risk profiles, financial summaries
│           └── marts/          # Presentation layer: Business-ready tables (Executive, Marketing)
```

## 📊 Data Modeling Architecture (dbt Models)

The project follows a layered dbt architecture to ensure maintainability, scalability, and clear separation of concerns.

### Staging Layer (`models/staging`)

The foundational layer. Models here typically maintain a 1:1 relationship with raw source tables. The primary goal is data cleansing and standardization: renaming columns for consistency, casting data types, handling `NULL` values, and removing exact duplicates.
Standardizes raw source tables into clean, consistently formatted views:

* Customers
* Accounts
* Cards
* Loans
* Investments
* Transactions

This layer serves as the foundation for downstream transformations.

---

### Intermediate Layer (`models/intermediate`)

The core business logic layer. Here, we join staging tables and calculate complex, domain-specific metrics. Models are organized by analytical domains to keep logic isolated and reusable:
* **Customer Analytics:** * `int_customer_360_master`: The central hub consolidating demographics, retention, and profile data.
* **Financial Metrics:** * `int_customer_financial_summary`: Aggregates balances, limits, and holdings across deposit accounts, cards, loans, and investments into a single unified view per customer.
* **Risk Analytics:** * `int_comprehensive_risk_profile`: Evaluates credit scores, KYC compliance, and fraud alerts to generate risk categories.
* **Product Analytics:** * `int_product_penetration_analysis`, `int_channel_effectiveness`.

---

### Marts Layer (`models/marts`)

The presentation layer. These are highly denormalized, wide tables optimized for Business Intelligence (BI) tools (like Power BI or Tableau) and end-user consumption. They are organized by business unit to ensure data is strictly tailored to stakeholder needs:
* **Executive (`/executive`):** * `executive_customer_dashboard`: High-level KPIs such as total relationship value, active customer counts, and net worth.
* **Customer Marketing (`/customer_marketing`):** * `customer_segmentation_analysis`: Ready-to-use data for targeted campaigns based on behavior and profitability segments.
* **Risk Operations (`/risk_operations`):** * `risk_management_dashboard`: Monitoring defaults, delinquent loans, and high-risk customer profiles.
* **Product Revenue (`/product_revenue`):** * `product_performance_analytics`.

These models are consumed directly by:

* BI dashboards
* Reporting tools
* Data analysts
* Business stakeholders

---

### Seeds (`dags/dbt/.../seeds/`)
Static reference data loaded directly into Snowflake as tables. These are used to enrich transactional data with standardized dimensions without hardcoding values in SQL.
* **Key Domains:** `age_cohorts`, `country_risk_ratings`, `credit_score_ranges`, `currency_codes`, `marketing_segments`.

---

## ⚙️ Prerequisites

Before you begin, ensure the following dependencies are installed:

* Docker Desktop (Running)
* Astro CLI
* Snowflake Account

---

## 🛠️ Local Setup & Execution

### 1. Configure the Environment

Create a `.env` file in the project root directory (you can copy `.env_example` if available) and configure your Airflow connection to Snowflake.

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

---

### 2. Build and Start the Project

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

---

### 3. Access Airflow

Once the containers are running, access the Airflow UI:

| Setting  | Value                 |
| -------- | --------------------- |
| URL      | http://localhost:8080 |
| Username | admin                 |
| Password | admin                 |

---

### 4. Run the Pipeline

1. Open the Airflow UI.
2. Locate the DAG named:

```text
customer_360_snow
```

Defined in:

```text
dags/cosmos_snowflake_dbt.py
```

3. Unpause the DAG using the toggle switch.
4. Click **Trigger DAG** (▶ Play button).

#### What Happens?

Thanks to Astronomer Cosmos:

* The dbt project is automatically parsed.
* `manifest.json` is used to generate task dependencies.
* Every dbt model appears as an individual Airflow task.
* Model execution can be monitored directly from Airflow.
* Failed nodes can be retried independently.

---

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

## 🧠 Key Features Implemented

### Seamless dbt-Airflow Integration

No need for:

* `BashOperator`
* `DockerOperator`

Astronomer Cosmos automatically parses the dbt project and generates the DAG structure.

---

### Virtual Environment Isolation

A dedicated dbt virtual environment ensures:

* Clean dependency management
* Reduced package conflicts
* Easier maintenance

---

### Seed Data Injection

Extensive use of dbt seeds to load static reference datasets into Snowflake.

Examples:

* Age cohorts
* Currency codes
* Fee structures
* Business mappings

---

### Modular Analytics Architecture

Business logic is organized into dedicated analytical domains:

* Financial Metrics
* Product Revenue
* Risk Operations
* Marketing Segmentation

This modular design improves:

* Scalability
* Reusability
* Testing
* Team collaboration

