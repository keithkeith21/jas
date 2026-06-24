# Financial Consumer Complaints: Data Warehousing & Analytics
**By:** Jasfher Pantoja  
**Role:** Data Analyst  
**Tools:** MySQL (ETL & Modeling), Power BI (Visualization & DAX)

---

## 1. Project Overview
This project demonstrates an end-to-end data pipeline, transforming over **4,000+ raw consumer complaint records** into an actionable analytical tool. I developed a structured Data Warehouse using SQL and built an Interactive Executive Dashboard in Power BI to facilitate data-driven business decisions.

---

## 2. The Problem Statement
The original dataset was stored in a single "flat" table (`consumer_complaints`), which presented several operational challenges:
* **Data Quality Issues:** The presence of null values, inconsistent text casing (upper/lower case), and trailing white spaces made reporting inaccurate.
* **Performance Bottlenecks:** Querying large flat tables for complex analytics is inefficient and slow.
* **Lack of Time Intelligence:** There was no built-in capability to analyze trends by month, quarter, or year dynamically.

---

## 3. Data Engineering & Star Schema (SQL)
I utilized SQL to perform ETL (Extract, Transform, Load) processes, cleaning the data and normalizing it into a **Star Schema** architecture. The data was partitioned into **1 Fact Table** and **7 Dimension Tables**.

### Key ETL Transformations:
* **Data Standardization:** Applied `TRIM()` and `LOWER()` functions to ensure uniform text formatting across all fields.
* **Null Value Management:** Leveraged `COALESCE()` and `NULLIF()` to replace empty fields with a standard "Unknown" or "Missing" tag instead of leaving them blank.

### Warehouse Design:
* **Fact Table:** `fact_complaints` (Stores quantitative metrics and foreign keys).
* **Dimension Tables:** `dim_products`, `dim_issues`, `dim_companies`, `dim_locations`, `dim_date`, `dim_submitted`, and `dim_consumer_behavior`.

### Analytical Insights (Sample Queries)
Once the schema was built, I ran complex queries to extract business value.

#### Insight 1: Monthly Complaint Volume per Product
*This query identifies which products are gaining more complaints over time.*
```sql
SELECT 
    d.year,
    d.month_name,
    p.product,
    COUNT(f.complaint_id) AS total_complaints
FROM fact_complaints f
JOIN dim_date d ON f.date_received_id = d.date_id
JOIN dim_products p ON f.product_id = p.product_id
GROUP BY d.year, d.month, d.month_name, p.product
ORDER BY d.year DESC, d.month DESC, total_complaints DESC;
```

#### Insight 2: Companies with Poor Response Time
*Identifying companies that fail to provide a 'Timely Response' to consumers.*
```sql
SELECT 
    comp.company,
    loc.state,
    cb.timely_response,
    COUNT(f.complaint_id) AS complaint_count
FROM fact_complaints f
JOIN dim_companies comp ON f.company_id = comp.company_id
JOIN dim_locations loc ON f.location_id = loc.location_id
JOIN dim_consumer_behavior cb ON f.consumer_behavior_id = cb.consumer_behavior_id
WHERE cb.timely_response = 'no'
GROUP BY comp.company, loc.state, cb.timely_response
ORDER BY complaint_count DESC
LIMIT 10;
```

---

## 4. Data Modeling (Power BI)
The cleaned database was imported into Power BI, where I established a Star Schema model using **One-to-Many (1:*) relationships**. This structure ensures high-performance filtering and accurate data aggregation.

---

## 5. Advanced Analytics (DAX)
I developed custom DAX Measures to calculate key performance indicators (KPIs) dynamically:
* **Total Complaints:** Aggregated volume of all reported grievances.
* **Timely Response Rate %:** Measures corporate efficiency in meeting response deadlines *(Result: 98.3%)*.
* **Dispute Rate %:** Tracks the frequency at which consumers challenge the resolution provided.

---

## 6. Executive Dashboard & Insights
The final output is an interactive dashboard that translates complex data into clear business insights.

<img width="1363" height="597" alt="Screenshot 2026-05-13 021226" src="https://github.com/user-attachments/assets/08ad8c91-780a-48f6-a482-8949ed8d7334" />


### Key Business Insights:
1. **Product Vulnerability:** Mortgages and Credit Reporting were identified as the products with the highest complaint volumes.
2. **Channel Preference:** Over 62% of complaints are submitted via the Web, indicating a strong consumer preference for digital channels.
3. **Operational Efficiency:** While the Timely Response Rate is high at 98%, the Dispute Rate highlights specific areas where the quality of resolution can be improved.
4. **Temporal Trends:** The Monthly Trend analysis revealed specific seasonal spikes, allowing for better resource allocation during peak periods.

---

## 7. Conclusion
By migrating from a flat-file system to a Normalized Star Schema, I significantly improved query performance and reporting accuracy. This project serves as a blueprint for how structured data modeling can turn "messy" raw data into a powerful tool for stakeholder decision-making.
