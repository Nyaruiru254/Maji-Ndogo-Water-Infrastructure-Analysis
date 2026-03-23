# 💧 Maji Ndogo Water Infrastructure Analysis

## Project Overview

Maji Ndogo is a fictional country facing a severe water crisis. This project involves an end-to-end SQL-based analysis of a **60,000-record water survey database**, collected by a team of field engineers, scientists, and surveyors. The goal was to understand how citizens access water, identify infrastructure problems, detect data integrity issues, and ultimately build an actionable improvement plan for the government.

This project was completed as part of the **ALX Data Analytics Programme** and spans four progressive parts — from initial data exploration to building a live project tracking table for repair teams.

---

## 🗂️ Repository Structure

```
Maji-Ndogo-Water-Infrastructure-Analysis/
│
├── Part_1_Maji_Ndogo_Integrated_Project.sql   # Data exploration & pollution data cleaning
├── Part_2_Maji_Ndogo_Integrated_Project.sql   # Water source analysis & queue time insights
├── Part_3_Maji_Ndogo_Integrated_Project.sql   # Auditor report & corruption detection
└── Part_4_Maji_Ndogo_Integrated_Project.sql   # Provincial analysis & project progress table
```

---

## 🛠️ Tools & Technologies

- **MySQL** — Primary database and query engine
- **SQL Concepts Used:**
  - `SELECT`, `WHERE`, `GROUP BY`, `ORDER BY`, `HAVING`
  - `JOIN` (INNER, LEFT)
  - Aggregate functions (`SUM`, `AVG`, `COUNT`, `MIN`, `MAX`)
  - String functions (`CONCAT`, `REPLACE`, `LOWER`, `LTRIM`, `RTRIM`, `LIKE`, `SUBSTRING_INDEX`)
  - Date/time functions (`DATEDIFF`, `TIMEDIFF`, `DAYNAME`, `HOUR`)
  - Window functions (`DENSE_RANK`, `PARTITION BY`)
  - `CASE` statements and pivot tables
  - CTEs (`WITH` clause) — including nested CTEs
  - Views (`CREATE VIEW`)
  - Temporary Tables (`CREATE TEMPORARY TABLE`)
  - `UPDATE`, `INSERT INTO`, `DROP TABLE`, `ALTER TABLE`
  - Subqueries
  - Foreign keys and constraints (`REFERENCES`, `ON DELETE CASCADE`, `CHECK`)

---

## 📊 Part 1 — Beginning Our Data-Driven Journey

### Objective
Explore the database structure, understand water source types, and fix critical data quality issues in the well pollution table.

### Key Tasks
- Explored 8 tables: `employee`, `location`, `visits`, `water_source`, `water_quality`, `well_pollution`, `global_water_access`, `data_dictionary`
- Identified **5 types of water sources**: river, well, shared tap, tap in home, broken tap in home
- Detected **218 anomalous records** where high-quality home taps were visited more than once — flagging potential surveyor errors
- Found and corrected **pollution data inconsistencies** where wells were incorrectly marked as "Clean" despite biological contamination above 0.01 CFU/mL
- Fixed corrupted descriptions (`Clean Bacteria: E. coli` → `Bacteria: E. coli`) using `UPDATE` with `LIKE` filters

### SQL Highlights
```sql
-- Detecting incorrectly classified clean wells
SELECT * FROM well_pollution
WHERE description LIKE 'clean%'
AND biological > 0.01;

-- Fixing corrupted pollution records
UPDATE well_pollution
SET results = 'Contaminated: Biological'
WHERE biological > 0.01 AND results = 'Clean';
```

---

## 📊 Part 2 — Water Accessibility & Infrastructure Analysis

### Objective
Analyse water source usage patterns, employee performance, location data, and queue time trends to build a summary report for President Naledi.

### Key Findings
1. **Most water sources are in rural areas**
2. **43% of citizens use shared taps** — often 2,000 people sharing one tap
3. **31% have home water infrastructure**, but **45% of those face broken systems**
4. **18% rely on wells**, but only **28% of those wells are clean**
5. **Average queue time exceeds 120 minutes**
6. Queue times peak on **Saturdays** and during **morning/evening hours**
7. **Wednesdays and Sundays** have the shortest queues

### SQL Highlights
```sql
-- Queue time pivot table by hour and day of week
SELECT
    HOUR(time_of_record) AS hour_of_day,
    ROUND(AVG(CASE WHEN DAYNAME(time_of_record) = 'Monday' THEN time_in_queue END), 1) AS Monday,
    ROUND(AVG(CASE WHEN DAYNAME(time_of_record) = 'Saturday' THEN time_in_queue END), 1) AS Saturday
FROM visits
GROUP BY HOUR(time_of_record)
ORDER BY HOUR(time_of_record);

-- Ranking water source types by population served
SELECT type_of_water_source,
    SUM(number_of_people_served) AS total_served,
    DENSE_RANK() OVER (ORDER BY SUM(number_of_people_served) DESC) AS rank_by_population
FROM water_source
GROUP BY type_of_water_source;
```

---

## 📊 Part 3 — Auditor Report & Corruption Detection

### Objective
Cross-reference surveyor-collected data with an independent auditor's report to identify incorrect records and flag potentially corrupt employees.

### Key Tasks
- Loaded an external **auditor report** database containing independently verified water source scores
- Joined 4 tables to isolate records where surveyor scores did **not match** auditor scores
- Built a `CREATE VIEW` with full documentation to store all mismatched records
- Used **nested CTEs** to calculate each employee's error count and compare it to the average
- Filtered for employees whose error rates were **above the statistical average**
- Cross-referenced flagged employees with auditor `statements` containing the keyword `'cash'` to detect **bribery patterns**

### Corrupt Surveyors Identified
| Employee Name     |
|-------------------|
| Zuriel Matembo    |
| Malachi Mavuso    |
| Bello Azibo       |
| Lalitha Kaburi    |

### SQL Highlights
```sql
-- Identifying employees with above-average error rates
WITH employee_error_count AS (
    SELECT COUNT(employee_name) AS error_count, employee_name
    FROM incorrect_records
    GROUP BY employee_name
),
suspect_list AS (
    SELECT error_count, employee_name
    FROM employee_error_count
    WHERE error_count > (SELECT AVG(error_count) FROM employee_error_count)
)
-- Cross-check suspects with cash-related auditor statements
SELECT auditor_location_id, employee_name, statements
FROM incorrect_records
WHERE employee_name IN (SELECT employee_name FROM suspect_list)
AND statements LIKE '%cash%';
```

---

## 📊 Part 4 — Provincial Analysis & Project Progress Tracking

### Objective
Perform a granular province and town-level analysis of water access, then build a `project_progress` table to guide and track on-the-ground repair teams.

### Key Tasks
- Created a **unified View** (`combined_water_source_analysis`) joining `visits`, `water_source`, `location`, and `well_pollution`
- Built a **province/town pivot table** using a Temporary Table and CTEs showing percentage of citizens using each water source type
- Identified key regional insights:
  - **Sokoto** has the highest river water dependency and extreme wealth inequality in water access
  - **Amina (Amanzi)** has over 50% broken home taps — infrastructure failure
  - Politicians' capital city **Dahabu** had suspiciously well-maintained infrastructure
- Created the **`project_progress` table** with constraints, foreign keys, and status tracking for repair teams

### Improvement Logic
| Water Source | Condition | Action |
|---|---|---|
| River | Any | Drill wells |
| Well | Biological contamination | Install UV + RO filter |
| Well | Chemical contamination | Install RO filter |
| Shared tap | Queue ≥ 30 min | Install `FLOOR(queue/30)` taps nearby |
| Broken home tap | Any | Diagnose local infrastructure |

### SQL Highlights
```sql
-- Calculating number of taps needed based on queue time
CASE
    WHEN type_of_water_source = 'shared_tap' AND time_in_queue >= 30
        THEN CONCAT('Install ', FLOOR(time_in_queue / 30), ' taps nearby')
    WHEN type_of_water_source = 'well' AND results = 'Contaminated: Biological'
        THEN 'Install UV and RO filter'
    WHEN type_of_water_source = 'river'
        THEN 'Drill Wells'
END AS improvement
```

---

## 🔍 Key Insights Summary

| # | Insight |
|---|---------|
| 1 | Most water sources are in **rural areas** |
| 2 | **43%** of citizens rely on shared taps, often serving 2,000+ people per tap |
| 3 | **45%** of home tap infrastructure is broken |
| 4 | Only **28%** of wells are clean |
| 5 | Average queue time is **over 120 minutes** |
| 6 | **4 corrupt surveyors** were identified and flagged |
| 7 | **Sokoto** needs drilling teams urgently |
| 8 | **Amina** needs infrastructure repair teams urgently |

---

## 📌 About This Project

This project was completed as part of the **ALX Data Analytics Programme**, under the *Maji Ndogo: From Analysis to Action* integrated project series by **ExploreAI Academy**.

**Analyst:** Mary Mwangi  
**GitHub:** [Nyaruiru254](https://github.com/Nyaruiru254)
