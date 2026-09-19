# Hevo → Postgres → Snowflake → dbt Pipeline

## Overview
This project implements an ELT pipeline:
1. PostgreSQL (source), running in Docker on a DigitalOcean Droplet
2. Hevo Data replicates raw tables into Snowflake (`RAW_CUSTOMERS`, `RAW_ORDERS`, `RAW_PAYMENTS`)
3. dbt transforms the raw tables into a materialized `customers` table

## Prerequisites
- Docker
- Python 3.8+
- A Hevo Data account
- A Snowflake account with a warehouse, database, role, and user provisioned

## Configuration (IMPORTANT — no credentials are stored in this repo)
All secrets (Snowflake account, user, password/private key, warehouse, database, schema) are supplied via dbt's `profiles.yml`, which lives **outside this repository** at `~/.dbt/profiles.yml` and is never committed to version control.

Before running this project, create your own `~/.dbt/profiles.yml`:

```yaml
hevo_pipeline:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: "{{ env_var('SNOWFLAKE_ACCOUNT') }}"
      user: "{{ env_var('SNOWFLAKE_USER') }}"
      role: "{{ env_var('SNOWFLAKE_ROLE') }}"
      warehouse: "{{ env_var('SNOWFLAKE_WAREHOUSE') }}"
      database: "{{ env_var('SNOWFLAKE_DATABASE') }}"
      schema: "{{ env_var('SNOWFLAKE_SCHEMA') }}"
      private_key_path: "{{ env_var('SNOWFLAKE_PRIVATE_KEY_PATH') }}"
      private_key_passphrase: "{{ env_var('SNOWFLAKE_PRIVATE_KEY_PASSPHRASE') }}"
      threads: 4
```

Set the corresponding environment variables before running dbt:

```bash
export SNOWFLAKE_ACCOUNT=xxxxx
export SNOWFLAKE_USER=xxxxx
export SNOWFLAKE_ROLE=xxxxx
export SNOWFLAKE_WAREHOUSE=xxxxx
export SNOWFLAKE_DATABASE=xxxxx
export SNOWFLAKE_SCHEMA=xxxxx
export SNOWFLAKE_PRIVATE_KEY_PATH=/path/to/key.p8
export SNOWFLAKE_PRIVATE_KEY_PASSPHRASE=xxxxx
```

Similarly, Postgres connection details for Hevo's source are never hardcoded — configure them directly in the Hevo UI, or via environment variables if scripting the container:

```bash
export PG_USER=xxxxx
export PG_PASSWORD=xxxxx
export PG_DB=xxxxx
```

## How to run

### 1. Start Postgres (source)

```bash
docker volume create pgdata

docker run -d --name pg-hevo \
  -e POSTGRES_USER=$PG_USER \
  -e POSTGRES_PASSWORD=$PG_PASSWORD \
  -e POSTGRES_DB=$PG_DB \
  -v pgdata:/var/lib/postgresql/data \
  -p 5432:5432 \
  postgres:16 \
  -c wal_level=logical -c max_replication_slots=5 -c max_wal_senders=5
```

### 2. Configure Hevo

Create a Postgres source and Snowflake destination pipeline in the Hevo UI, pointing to the values above.

### 3. Run dbt

```bash
python3 -m venv dbt-env
source dbt-env/bin/activate
pip install dbt-snowflake
cd hevo_pipeline
dbt debug
dbt run
```

### 4. Verify

```sql
SELECT * FROM customers LIMIT 10;
```

## Project structure

hevo_pipeline/
├── models/
│ ├── staging/
│ │ ├── sources.yml
│ │ ├── stg_customers.sql
│ │ ├── stg_orders.sql
│ │ └── stg_payments.sql
│ └── marts/
│ └── customers.sql
└── dbt_project.yml

