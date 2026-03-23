USE md_water_services;
DROP TABLE IF EXISTS auditor_report;
CREATE TABLE auditor_report 
(
    location_id VARCHAR (32),
    type_of_water_source VARCHAR (64),
    true_water_source_score int DEFAULT NULL,
    statements VARCHAR (255)
);


WITH incorrect_records AS (
	SELECT
		auditor_report.location_id AS auditor_location_id,
		visits.record_id AS visits_record_id,
		auditor_report.true_water_source_score AS auditor_score,
		water_quality.subjective_quality_score AS surveyor_score,
		visits.visit_count,
		auditor_report.type_of_water_source AS auditor_source,
		visits.assigned_employee_id,
		employee.employee_name
	FROM
		auditor_report
	INNER JOIN visits ON auditor_report.location_id = visits.location_id
	INNER JOIN water_quality ON visits.record_id = water_quality.record_id
	INNER JOIN employee ON employee.assigned_employee_id = visits.assigned_employee_id
	WHERE 
		water_quality.subjective_quality_score != auditor_report.true_water_source_score
	AND
		visits.visit_count = 1
),

employee_error_count AS (
	SELECT 
		COUNT(employee_name) AS error_count,
		employee_name
	FROM
		incorrect_records
	GROUP BY employee_name
	ORDER BY COUNT(employee_name) DESC
)

	SELECT
		error_count,
		employee_name
	FROM
		employee_error_count
	WHERE 
		error_count > (
		SELECT
		AVG (error_count)
		FROM
			employee_error_count)
	ORDER BY error_count DESC;
    
    
    CREATE VIEW incorrect_records AS
-- =====================================================
-- VIEW: incorrect_records
-- PURPOSE: Find all records where auditor and surveyor
--          scores disagree, for first visits only
-- =====================================================
-- DESCRIPTION:
-- This view contains records where the auditor's true score
-- does NOT match the surveyor's subjective score, indicating
-- potential errors in data collection or reporting.
-- =====================================================
-- DATA FILTERS:
-- - Only records where auditor_score != surveyor_score
-- - Only first visits (visit_count = 1)
-- =====================================================
-- TABLES JOINED:
--   * auditor_report (auditor's scores and observations)
--   * visits (visit information and employee assignments)
--   * water_quality (surveyor's subjective scores)
--   * employee (employee names for identification)
-- =====================================================
-- COLUMNS:
--   auditor_location_id : The location ID from auditor_report
--   visits_record_id    : The record ID from visits table
--   auditor_score       : Score given by auditor (TRUE score)
--   surveyor_score      : Score given by surveyor (SUBJECTIVE score)
--   visit_count         : Which visit number (ALWAYS 1 in this view)
--   auditor_source      : Type of water source recorded by auditor
--   assigned_employee_id: ID of employee who did the survey
--   employee_name       : Full name of the employee
--   statements            : Comments of the auditor on employees' work
-- =====================================================
-- USAGE EXAMPLES:
--   
--   1. Get all incorrect records:
--      SELECT * FROM incorrect_records;
--   
--   2. Count errors per employee:
--      SELECT employee_name, COUNT(*) 
--      FROM incorrect_records 
--      GROUP BY employee_name;
--   
--   3. Find locations with biggest score differences:
--      SELECT auditor_location_id, 
--             auditor_score, 
--             surveyor_score,
--             (auditor_score - surveyor_score) AS score_difference
--      FROM incorrect_records
--      WHERE auditor_score > surveyor_score
--      ORDER BY score_difference DESC;
-- =====================================================

SELECT
    auditor_report.location_id AS auditor_location_id,
    visits.record_id AS visits_record_id,
    auditor_report.true_water_source_score AS auditor_score,
    water_quality.subjective_quality_score AS surveyor_score,
    visits.visit_count,
    auditor_report.type_of_water_source AS auditor_source,
    visits.assigned_employee_id,
    employee.employee_name,
    auditor_report.statements
FROM
	auditor_report
INNER JOIN visits ON auditor_report.location_id = visits.location_id
INNER JOIN water_quality ON visits.record_id = water_quality.record_id
INNER JOIN employee ON employee.assigned_employee_id = visits.assigned_employee_id
WHERE 
    water_quality.subjective_quality_score != auditor_report.true_water_source_score
    AND visits.visit_count = 1;

SELECT
	*
FROM
	incorrect_records;
    

WITH employee_error_count AS (
	SELECT 
		COUNT(employee_name) AS error_count,
		employee_name
	FROM
		incorrect_records
	GROUP BY employee_name
	ORDER BY COUNT(employee_name) DESC
)

SELECT
	*
FROM
	employee_error_count;
    
WITH employee_error_count AS (
	SELECT 
		COUNT(employee_name) AS error_count,
		employee_name
	FROM
		incorrect_records
	GROUP BY employee_name
	ORDER BY COUNT(employee_name) DESC
),

suspect_list AS (
SELECT
	error_count,
    employee_name
FROM
	employee_error_count
WHERE
	error_count > (
		SELECT
			AVG(error_count)
		FROM
			employee_error_count)
)

SELECT
	*
FROM
	suspect_list
ORDER BY error_count DESC;

WITH employee_error_count AS (
	SELECT 
		COUNT(employee_name) AS error_count,
		employee_name
	FROM
		incorrect_records
	GROUP BY employee_name
	ORDER BY COUNT(employee_name) DESC
),

suspect_list AS (
SELECT
	error_count,
    employee_name
FROM
	employee_error_count
WHERE
	error_count > (
		SELECT
			AVG(error_count)
		FROM
			employee_error_count)
)

SELECT
	auditor_location_id,
    employee_name,
    statements
FROM
	incorrect_records
WHERE employee_name IN (
	SELECT
		employee_name
	FROM
		suspect_list)
	AND statements LIKE '%cash%'
	ORDER BY employee_name;
	

WITH employee_error_count AS (
	SELECT 
		COUNT(employee_name) AS error_count,
		employee_name
	FROM
		incorrect_records
	GROUP BY employee_name
	ORDER BY COUNT(employee_name) DESC
),

suspect_list AS (
SELECT
	error_count,
    employee_name
FROM
	employee_error_count
WHERE
	error_count > (
		SELECT
			AVG(error_count)
		FROM
			employee_error_count)
)

SELECT
	auditor_location_id,
    employee_name,
    statements
FROM
	incorrect_records
WHERE
	statements LIKE '%cash%'
    AND employee_name NOT IN (
		SELECT
			employee_name
		FROM
			suspect_list)
		ORDER BY employee_name;
        
SELECT
	*
FROM
	well_pollution;