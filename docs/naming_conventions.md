# Aviation Data Warehouse Naming Conventions

This document defines the naming standards currently implemented in the Aviation Data Warehouse project.

The conventions below are based only on the Bronze, Silver, and Gold objects that have already been designed or implemented in the current project.

---

# Table of Contents

1. General Standards
2. Schema Naming Standards
3. Bronze Layer Naming Rules
4. Silver Layer Naming Rules
5. Gold Layer Naming Rules
6. Column Naming Rules
7. Surrogate Key Naming
8. Technical Metadata Columns
9. Examples from Current Project

---

# 1. General Standards

* All object names use lowercase letters.
* Words are separated using underscores (`_`).
* Snake case is used for all schemas, tables, views, columns.
* English is used for all naming.
* Table names remain short, descriptive, and aligned with the business domain.
* Naming should remain consistent across Bronze, Silver, and Gold layers.

---

# 2. Schema Naming Standards

The project currently uses three schemas:

* `bronze`
* `silver`
* `gold`

Each schema represents one layer of the Medallion Architecture.

| Schema | Purpose                                      |
| ------ | -------------------------------------------- |
| bronze | Raw source data loaded with minimal changes  |
| silver | Cleansed, standardized, and transformed data |
| gold   | Business-ready analytical views              |

---

# 3. Bronze Layer Naming Rules

Bronze table names begin with the source system prefix followed by the business entity name.

Pattern:

```text
<source_system>_<entity>
```

Current source system prefixes used in the project:

| Prefix | Meaning                 |
| ------ | ----------------------- |
| ops    | Airport operations data |
| pax    | Passenger-related data  |
| ret    | Retail transaction data |

Current Bronze Tables:

| Table Name                     | Description                           |
| ------------------------------ | ------------------------------------- |
| bronze.ops_flights             | Raw flight operations data            |
| bronze.ops_baggage             | Raw baggage movement data             |
| bronze.ops_gate_events         | Raw gate event data                   |
| bronze.pax_passengers          | Raw passenger booking and travel data |
| bronze.ret_retail_transactions | Raw airport retail transaction data   |

Bronze tables preserve the source naming structure as much as possible.

---

# 4. Silver Layer Naming Rules

Silver tables use the same source-system-based naming pattern as Bronze.

Pattern:

```text
<source_system>_<entity>
```

Current Silver Tables:

| Table Name                     | Description                                      |
| ------------------------------ | ------------------------------------------------ |
| silver.ops_flights             | Cleaned and standardized flight data             |
| silver.ops_baggage             | Cleaned and standardized baggage data            |
| silver.ops_gate_events         | Cleaned and standardized gate event data         |
| silver.pax_passengers          | Cleaned and standardized passenger data          |
| silver.ret_retail_transactions | Cleaned and standardized retail transaction data |

Silver layer naming remains aligned with Bronze so that lineage is easy to understand.

---

# 5. Gold Layer Naming Rules

Gold objects use business-oriented names rather than source-system-oriented names.

Pattern:

```text
<category>_<entity>
```

Current category prefixes planned and partially designed in the project:

| Prefix | Meaning        |
| ------ | -------------- |
| dim    | Dimension view |
| fact   | Fact view      |
|        |                |

Examples currently used in the project:

| Object Name                 | Description                 |
| --------------------------- | --------------------------- |
| gold.dim_flights            | Flight dimension view       |
| gold.dim_passengers         | Passenger dimension view    |
| gold.dim_date               | Date dimension view         |
| gold.fact_flight_operations | Flight operations fact view |
| gold.fact_passenger_journey | Passenger journey fact view |
| gold.fact_baggage           | Baggage fact view           |
| gold.fact_retail_sales      | Retail sales fact view      |

Gold names should be meaningful to business users and reporting teams.

---

# 6. Column Naming Rules

All columns use snake_case.

Pattern:

```text
<business_term>
```

Examples from the current project:

* `flight_id`
* `airline_name`
* `scheduled_departure_time`
* `departure_delay_minutes`
* `baggage_weight_kg`
* `boarding_completion_time`
* `transaction_timestamp`
* `loyalty_points_earned`
* `load_factor_percentage`

General column naming standards:

* IDs use the `_id` suffix.
* Time-based columns use suffixes such as `_time`, `_timestamp`, or `_date`.
* Boolean columns use the `_flag` suffix.
* Percentage columns use the `_percentage` suffix.
* Numeric duration fields use units in the column name when relevant, such as `_minutes`, `_kg`, `_km`, or `_tons`.

Examples:

| Pattern       | Example                  |
| ------------- | ------------------------ |
| `_id`         | `flight_id`              |
| `_date`       | `date_of_birth`          |
| `_time`       | `checkin_time`           |
| `_timestamp`  | `event_timestamp`        |
| `_flag`       | `weekend_flight_flag`    |
| `_minutes`    | `baggage_delay_minutes`  |
| `_percentage` | `load_factor_percentage` |

---

# 7. Surrogate Key Naming

Silver tables currently use a generic surrogate key column named `id`.

Examples:

* `silver.ops_flights.id`
* `silver.pax_passengers.id`
* `silver.ops_baggage.id`
* `silver.ops_gate_events.id`
* `silver.ret_retail_transactions.id`

For Gold views, surrogate keys are expected to use the `_key` suffix.

Pattern:

```text
<entity>_key
```

Examples planned in Gold:

* `flight_key`
* `passenger_key`
* `date_key`
* `airport_key`
* `retail_category_key`

---

# 8. Technical Metadata Columns

Technical metadata columns use the `dwh_` prefix.

Pattern:

```text
dwh_<column_name>
```

Examples already implemented in the project:

| Column Name       | Purpose                                        |
| ----------------- | ---------------------------------------------- |
| dwh_source_system | Stores the source system name                  |
| dwh_load_date     | Stores the raw load timestamp                  |
| dwh_batch_id      | Stores the load batch identifier               |
| dwh_file_name     | Stores the source file name                    |
| dwh_create_date   | Stores the record creation timestamp in Silver |

Bronze tables currently include:

* `dwh_source_system`
* `dwh_load_date`
* `dwh_batch_id`
* `dwh_file_name`

Silver tables currently include:

* `dwh_create_date`

---


# 9. Examples from Current Project

## Bronze Examples

```text
bronze.ops_flights
bronze.ops_baggage
bronze.ops_gate_events
bronze.pax_passengers
bronze.ret_retail_transactions
```

## Silver Examples

```text
silver.ops_flights
silver.ops_baggage
silver.ops_gate_events
silver.pax_passengers
silver.ret_retail_transactions
```

## Gold Examples

```text
gold.dim_flights
gold.dim_passengers
gold.fact_flight_operations
gold.fact_passenger_journey
gold.fact_baggage
gold.fact_retail_sales
```

## Metadata Examples

```text
dwh_source_system
dwh_load_date
dwh_batch_id
dwh_file_name
dwh_create_date
```
