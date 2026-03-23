-- Querying the database I want to work on
USE md_water_services;
 
/*Creating a copy of the employee table to perform update operations 
on before doing the actual updates on the original table*/
CREATE TABLE
	employee_copy
AS(
	SELECT
		*
	FROM
		employee
	);
 
 /*
 replacing the space in between the names with a dot
converting all letters into lower-case 
joining the new result with @ndogowater.gov to form a good email format
*/
SELECT
	CONCAT(
    LOWER(REPLACE(employee_name, ' ', '.')), '@ndogowater.gov')AS new_email
FROM
	employee_copy;
    
-- enabling updates in my database
SET SQL_SAFE_UPDATES = 0;
   
-- updating the changes in my new copy of the employee table
UPDATE
	employee_copy
	SET email = CONCAT(LOWER(REPLACE(employee_name, ' ', '.')), '@ndogowater.gov');

-- checking to confirm the updates happened succesfully
SELECT
	*
FROM
	employee_copy;

-- deleting the copy table
DROP TABLE employee_copy;

-- making the actual changes on the employee table
UPDATE
	employee
	SET email = CONCAT(LOWER(REPLACE(employee_name, ' ', '.')), '@ndogowater.gov');

-- viewing the employee table to confirm updates have happened successfully
SELECT
	*
FROM
	employee;
    
DESCRIBE
	employee;
    
SELECT
	phone_number,
    LENGTH(phone_number) AS current_length,
    LTRIM(RTRIM(phone_number)) AS trimmed_phone_number,
    LENGTH(LTRIM(RTRIM(phone_number))) AS new_length
FROM
	employee;
    
UPDATE
	employee
	SET phone_number = LTRIM(RTRIM(phone_number));

SELECT
	LENGTH(phone_number)
FROM
	employee;

SELECT
	province_name,
    town_name,
    COUNT(town_name) AS employees_per_town
FROM
	employee
GROUP BY
	province_name, town_name;
    
SELECT
	assigned_employee_id,
    COUNT(visit_count) AS employee_ID_visit_counts
FROM
	visits
GROUP BY
	assigned_employee_id
ORDER BY
	COUNT(visit_count) DESC;
    
SELECT
    employee.employee_name,
	employee.assigned_employee_id,
    employee.phone_number,
    employee.email,
	visits.assigned_employee_id,
    COUNT(visits.visit_count) AS employee_visit_counts
FROM
	employee
JOIN
	visits ON employee.assigned_employee_id = visits.assigned_employee_id
GROUP BY
	employee.employee_name, employee.assigned_employee_id
ORDER BY
	COUNT(visits.visit_count) ASC;
    
SELECT
	*
FROM
	location;
    
SELECT
	town_name,
    COUNT(town_name) AS records_per_town
FROM
	location
GROUP BY
	town_name
ORDER BY
	 COUNT(town_name) DESC;
	
SELECT
	province_name,
    COUNT(province_name) AS records_per_province
FROM
	location
GROUP BY
	province_name
ORDER BY
	COUNT(province_name) DESC;
    
SELECT
	province_name,
    town_name,
    COUNT(town_name) OVER(PARTITION BY province_name ORDER BY COUNT(town_name) DESC) AS records_per_town
FROM
	location
GROUP BY
	province_name, town_name
ORDER BY
	province_name;
    
SELECT
	province_name,
    town_name,
    COUNT(town_name) 
FROM
	location
GROUP BY
	province_name, town_name
ORDER BY
	province_name,
	COUNT(town_name)  DESC;
    
SELECT
	location_type,
    COUNT(location_type) AS records_per_location_type
FROM
	location
GROUP BY
	location_type
ORDER BY
	COUNT(location_type) DESC;

SELECT
	*
FROM
	water_source;
    
SELECT
	source_id,
    LENGTH(source_id) AS length_source_id,
    type_of_water_source,
    LENGTH(type_of_water_source) AS length_type_of_water_source,
    number_of_people_served,
    LENGTH(number_of_people_served) AS length_number_of_people_served
FROM
	water_source;
    
SELECT
	type_of_water_source,
    SUM(number_of_people_served) AS total_number_of_people_served,
    COUNT(source_id) AS number_of_water_sources,
    ROUND(AVG(number_of_people_served), 0) AS average_number_of_people_served,
    ROUND(SUM(number_of_people_served) * 100 /
		(
		SELECT
			SUM(number_of_people_served)
		FROM
			water_source
		), 0) AS percentage_of_people_served
FROM
	water_source
GROUP BY
	type_of_water_source
ORDER BY
	SUM(number_of_people_served) DESC;
    

SELECT
	type_of_water_source,
	SUM(number_of_people_served) AS total_number_of_people_served,
	DENSE_RANK() OVER (
	ORDER BY SUM(number_of_people_served) DESC) AS rank_by_population_served
	FROM 
	water_source
GROUP BY
	type_of_water_source;
    
SELECT
	*
FROM 
	(
	SELECT
		source_id,
		type_of_water_source,
		DENSE_RANK() OVER 
			(PARTITION BY type_of_water_source ORDER BY number_of_people_served DESC) AS priority_rank
	FROM
		water_source
	WHERE
		type_of_water_source IN 
		(
			'well',
			'river',
			'shared_tap',
			'tap_in_home_broken'
		)
    ) AS ranked_sources
WHERE
	priority_rank <= 5
ORDER BY 
	type_of_water_source,
    priority_rank;
    
SELECT
	*
FROM	
	visits;

-- Question 1: How long did the survey take?
SELECT
    MIN(time_of_record) AS first_survey_date,
    MAX(time_of_record) AS last_survey_date,
    DATEDIFF(MAX(time_of_record), MIN(time_of_record)) AS days_duration,
    TIMEDIFF(MAX(time_of_record), MIN(time_of_record)) AS time_duration
FROM 
	visits;

-- Question 2: What is the average total queue time for water?
SELECT
    AVG(time_in_queue) AS avg_queue_time_minutes,
    ROUND(AVG(time_in_queue), 0) AS avg_queue_time_rounded
FROM 
	visits;

-- Question 3: What is the average queue time on different days?
SELECT
    DAYNAME(time_of_record) AS day_of_week,
    ROUND(AVG(time_in_queue), 1) AS avg_queue_time,
    COUNT(*) AS number_of_visits,
    MIN(time_in_queue) AS min_wait_time,
    MAX(time_in_queue) AS max_wait_time
FROM 
	visits
GROUP BY 
	day_of_week
ORDER BY 
    CASE day_of_week
        WHEN 'Monday' THEN 1
        WHEN 'Tuesday' THEN 2
        WHEN 'Wednesday' THEN 3
        WHEN 'Thursday' THEN 4
        WHEN 'Friday' THEN 5
        WHEN 'Saturday' THEN 6
        WHEN 'Sunday' THEN 7
    END;
    
SELECT
    DATE(time_of_record) AS survey_date,
    DAYNAME(time_of_record) AS day_name,
    ROUND(AVG(time_in_queue), 1) AS avg_queue_time,
    COUNT(*) AS visits_that_day
FROM 
	visits
GROUP BY 
	DATE(time_of_record), DAYNAME(time_of_record)
ORDER BY 
	survey_date;

-- Question 4: How can we communicate this effectively?
SELECT
    DAYNAME(time_of_record) AS day_of_week,
    ROUND(AVG(time_in_queue), 1) AS avg_wait_minutes,
    CASE 
        WHEN AVG(time_in_queue) < 30 THEN 'Good'
        WHEN AVG(time_in_queue) BETWEEN 30 AND 60 THEN 'Moderate'
        WHEN AVG(time_in_queue) BETWEEN 61 AND 120 THEN 'Long'
        ELSE 'Critical'
    END AS wait_status,
    COUNT(*) AS visits_recorded
FROM 
	visits
GROUP BY 
	DAYNAME(time_of_record)
ORDER BY 
	avg_wait_minutes DESC;
  
-- Question 5: Time of day people collect water
SELECT
    HOUR(time_of_record) AS hour_of_day,
    COUNT(*) AS visit_count,
    ROUND(AVG(time_in_queue), 1) AS avg_wait_time,
    MIN(time_in_queue) AS min_wait,
    MAX(time_in_queue) AS max_wait,
    SUM(CASE WHEN time_in_queue > 0 THEN 1 ELSE 0 END) AS visits_with_wait,
    ROUND(SUM(CASE WHEN time_in_queue > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_with_wait
FROM 
	visits
GROUP BY 
	HOUR(time_of_record)
ORDER BY 
	HOUR(time_of_record);
    
-- Question 6: Queue times per day at diferent hours.
SELECT
    HOUR(time_of_record) AS hour_of_day,
    ROUND(AVG(CASE WHEN DAYNAME(time_of_record) = 'Monday' THEN time_in_queue END), 1) AS Monday,
    ROUND(AVG(CASE WHEN DAYNAME(time_of_record) = 'Tuesday' THEN time_in_queue END), 1) AS Tuesday,
    ROUND(AVG(CASE WHEN DAYNAME(time_of_record) = 'Wednesday' THEN time_in_queue END), 1) AS Wednesday,
    ROUND(AVG(CASE WHEN DAYNAME(time_of_record) = 'Thursday' THEN time_in_queue END), 1) AS Thursday,
    ROUND(AVG(CASE WHEN DAYNAME(time_of_record) = 'Friday' THEN time_in_queue END), 1) AS Friday,
    ROUND(AVG(CASE WHEN DAYNAME(time_of_record) = 'Saturday' THEN time_in_queue END), 1) AS Saturday,
    ROUND(AVG(CASE WHEN DAYNAME(time_of_record) = 'Sunday' THEN time_in_queue END), 1) AS Sunday
FROM visits
GROUP BY HOUR(time_of_record)
ORDER BY HOUR(time_of_record);

SELECT
	*
FROM
	global_water_access;
    
SELECT
	type_of_water_source,
	AVG(number_of_people_served) AS average_number_of_people_served,
	DENSE_RANK() OVER (
	ORDER BY AVG(number_of_people_served) DESC) AS rank_by_population_served
	FROM 
	water_source
GROUP BY
	type_of_water_source;
    
