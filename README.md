# ✈️ Aviation Data Warehouse Project

A modern aviation-focused data warehouse built using MySQL and Medallion Architecture to transform raw airport operations, passenger activity, baggage handling, gate events, and airport retail transactions into analytics-ready business views.

This project demonstrates end-to-end data engineering practices including raw data ingestion, profiling, cleansing, transformation, validation, dimensional modeling, and analytical reporting.

---

## 📌 Project Goal

The objective of this project is to consolidate aviation operational and passenger-related datasets into a centralized warehouse that supports:

* Flight operations monitoring
* Passenger journey analysis
* Baggage tracking and performance
* Gate and boarding activity analysis
* Airport retail performance analysis
* KPI reporting and dashboard development
* Ad-hoc SQL analysis for business decision-making

The warehouse is designed using a layered Medallion Architecture:

* Bronze Layer → Raw source data
* Silver Layer → Cleansed and standardized data
* Gold Layer → Business-ready analytical views

---

## 🏗️ Architecture Overview

The project follows a Medallion Architecture pattern to separate raw ingestion, business logic, and analytical reporting.

### Bronze Layer

Raw source data is loaded exactly as received from CSV files.

Characteristics:

* Full-load ingestion
* Minimal transformations
* Raw file structure preserved
* Technical metadata columns added
* Used for auditing and traceability

### Silver Layer

The Silver layer standardizes and validates the raw data.

Typical transformations include:

* Data type conversion
* Timestamp parsing
* Duplicate handling
* Boolean conversion
* Null handling
* Derived business logic
* Data quality validation
* Standardization of text values

### Gold Layer

The Gold layer exposes dimensional and fact-style analytical views for reporting.

This layer supports:

* KPI reporting
* Dashboard creation
* Business intelligence tools
* Trend analysis
* Operational analytics

---

## 📂 Source Systems

The project integrates two independent source systems.

### 1. Airport Operations Management System (AOMS)

Operational datasets related to airport activities.

Datasets:

* flights.csv
* baggage.csv
* gate_events.csv

Main tables:

* bronze.ops_flights
* bronze.ops_baggage
* bronze.ops_gate_events

### 2. Passenger Services and Retail System (PSRS)

Passenger booking and airport retail datasets.

Datasets:

* passengers.csv
* retail_transactions.csv

Main tables:

* bronze.pax_passengers
* bronze.ret_retail_transactions

---

## 🧱 Data Model Layers

### Bronze Tables

* bronze.ops_flights
* bronze.ops_baggage
* bronze.ops_gate_events
* bronze.pax_passengers
* bronze.ret_retail_transactions

### Silver Tables

* silver.ops_flights
* silver.ops_baggage
* silver.ops_gate_events
* silver.pax_passengers
* silver.ret_retail_transactions

### Gold Views

#### Dimension Views

* gold.dim_flights
* gold.dim_passengers

#### Fact Views

* gold.fact_flight_operations
* gold.fact_passenger_journey
* gold.fact_baggage
* gold.fact_retail_sales

---

## 🔄 Example Data Flow

```text
flights.csv
   → bronze.ops_flights
   → silver.ops_flights
   → gold.dim_flights
   → gold.fact_flight_operations

passengers.csv
   → bronze.pax_passengers
   → silver.pax_passengers
   → gold.dim_passengers
   → gold.fact_passenger_journey

baggage.csv
   → bronze.ops_baggage
   → silver.ops_baggage
   → gold.fact_baggage

retail_transactions.csv
   → bronze.ret_retail_transactions
   → silver.ret_retail_transactions
   → gold.fact_retail_sales
```

---

## ⚙️ Major Transformations Implemented

### Flights

* Converted airport codes into readable city names
* Standardized airline codes and delay reasons
* Converted timestamps into DATETIME
* Recalculated delay categories
* Capped booked passengers at seat capacity
* Capped load factor at 100%
* Standardized route and delay logic

### Passengers

* Standardized names and gender values
* Recalculated passenger age using date of birth
* Rebuilt age group logic
* Converted no-show and VIP flags into booleans
* Removed sparse and low-value columns
* Corrected booking channel anomalies

### Baggage

* Converted baggage weight into numeric format
* Standardized baggage status and flags
* Corrected baggage timestamp sequence
* Derived baggage scan and baggage loaded times
* Converted baggage delay metrics into numeric values

### Gate Events

* Standardized boarding event types
* Converted timestamps into DATETIME
* Corrected gate open, boarding completion, and gate close sequences
* Standardized gate change flags and passenger counts

### Retail Transactions

* Corrected unit price and quantity logic
* Derived payment method based on transaction amount
* Derived loyalty points from total spend
* Derived store category, terminal, and store location
* Recalculated mathematically correct transaction totals

---

## ✅ Data Quality Framework

The project contains dedicated validation and profiling scripts for both Bronze and Silver layers.

Quality checks include:

* Null checks
* Duplicate detection
* Timestamp validation
* Referential integrity checks
* Invalid range detection
* Invalid categorical values
* Data type validation
* Cross-table relationship checks

Examples:

* Flights departing before scheduled departure
* Boarding before passenger check-in
* Invalid baggage timestamp sequences
* Missing gate numbers
* Retail transactions without matching passengers or flights

---

## 📊 Business Questions Supported

The warehouse is designed to answer analytical questions such as:

### Flight Operations

* Which airlines have the highest delay rates?
* Which routes generate the highest ticket revenue?
* Which terminals and gates are busiest?
* Which flights operate with the highest load factors?

### Passenger Analysis

* Which age groups travel most frequently?
* What is the distribution of travel classes?
* Which passengers are repeat travelers?
* Which nationalities spend the most in airport retail?

### Baggage Analysis

* Which flights have the highest baggage delay rates?
* Which baggage statuses occur most frequently?
* Which routes have the heaviest baggage loads?

### Gate Analysis

* Which gates process the highest number of passengers?
* Which gates experience the longest boarding times?
* Which terminals are the busiest during peak operations?

### Retail Analysis

* Which terminals generate the most retail revenue?
* Which product categories perform best?
* Which flights are linked to higher passenger spending?
* Which payment methods are most commonly used?

---

## 🛠️ Technology Stack

* Database: MySQL 8.x
* Query Language: SQL
* Architecture Style: Medallion Architecture
* Data Sources: CSV files
* Modeling Style: Star Schema
* Documentation: Markdown
* Visualization Readiness: Power BI / Tableau compatible

---

## 📁 Repository Structure

```text
aviation-data-warehouse/
│
├── datasets/
│   ├── source_AOMS/
│   │   ├── flights.csv
│   │   ├── baggage.csv
│   │   └── gate_events.csv
│   │
│   └── source_PSRS/
│       ├── passengers.csv
│       └── retail_transactions.csv
│
├── docs/
│   ├── data_catalog_gold.md
│   ├── naming_conventions.md
│   └── architecture and project documentation
│
├── scripts/
│   ├── bronze/
│   ├── silver/
│   └── gold/
│
├── tests/
│   └── quality_checks_silver.sql
│
├── README.md
└── LICENSE
```

---

## 🚀 Suggested Execution Order

1. Create schemas and database
2. Load Bronze layer tables
3. Perform Bronze data profiling
4. Build Silver layer tables and transformations
5. Run Silver quality checks
6. Create Gold layer views
7. Validate referential integrity and business metrics
8. Run analytical queries and build dashboards

---

## 📘 Notes

This repository is designed as a portfolio-ready project for showcasing practical skills in:

* SQL Development
* Data Warehousing
* Data Engineering
* ETL Design
* Data Modeling
* Data Quality Management
* Business Intelligence
* Analytical Reporting

The project structure, transformations, and validation rules were built specifically around aviation operations and passenger analytics use cases.
