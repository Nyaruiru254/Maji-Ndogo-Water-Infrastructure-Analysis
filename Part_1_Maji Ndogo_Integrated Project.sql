-- use database md-water_services
USE
	md_water_services;

/*merging type_of_water_source column from water_source table with columns from visits table 
where subjective_quality_score is 10 and type_of_water_source is tap_in_home to figure 
out tap_in_home values that have second visits*/ 
SELECT 
	water_quality.record_id,
    water_quality.subjective_quality_score,
    water_quality.visit_count,
    water_source.type_of_water_source
FROM
	water_quality
JOIN
	water_source
 WHERE
	subjective_quality_score = 10
AND
	visit_count = 2
AND
	type_of_water_source = 'tap_in_home';
 
 /*selecting rows from the well_population table that are described 
 to be clean yet have a biological score of more than 0.01*/
SELECT 
	*
FROM
	well_pollution
WHERE
	description LIKE 'clean%'
AND
	biological > 0.01;
    

SELECT @@autocommit;
SET autocommit = 0;

/*counting rows from the well_population table that are described 
 to be clean yet have a biological score of more than 0.01*/
SELECT 
	COUNT(*)
FROM 
	well_pollution
WHERE 
	description LIKE 'clean%'
AND
	biological > 0.01;
    
/*updating values in the description column of well_population table, 
replacing Clean Bacteria: Giardia Lamblia with Bacteria: Giardia Lamblia*/
UPDATE
	well_pollution
SET
	description = 'Bacteria: Giardia Lamblia'
WHERE
	description = 'Clean Bacteria: Giardia Lamblia';
	
SET 
	sql_safe_updates = 0;

/*updating values in the description column of well_population table, 
replacing Clean Bacteria: E. Coli with Bacteria: E. Coli*/
UPDATE
	well_pollution
SET
	description = 'Bacteria: E. Coli'
WHERE
	description = 'Clean Bacteria: E. Coli';

/*updating values in the results column of well_population table that have 
biological score greater than 0.01 and have results set as clean*/
UPDATE
	well_pollution
SET
	results = 'Contaminated: Biological'
WHERE
	biological > 0.01
AND
	results = 'Clean';
    
SELECT
	*
FROM
	well_pollution
WHERE
	results = 'Clean'
AND
	biological > 0.01
    
SELECT
	COUNT(*)
FROM
	well_pollution
WHERE
	results = 'Clean'
AND
	biological > 0.01;

SELECT
	*
FROM
	location
WHERE
	province_name = 'Bello Azibo'
    OR town_name = 'Bello Azibo'
    
SELECT
	*
FROM
	employee
WHERE
	position = 'Micro Biologist'
    
SELECT
    *
FROM
	water_source
WHERE(
SELECT
	MAX(number_of_people_served)
FROM
	water_source
);
   
SELECT
	*
FROM
	water_source
WHERE
	number_of_people_served = 3998
    
SELECT
	*
FROM
	data_dictionary
WHERE
	description LIKE '%population%';
    
SELECT
	SUM(pop_n)
FROM
	global_water_access
    
SELECT
	*
FROM
	global_water_access
WHERE
	NAME = 'Maji Ndogo'

SELECT
	*
FROM
	employee
WHERE
	(position = 'Civil Engineer')
    AND(town_name = 'Dahabu' OR address LIKE '%avenue%')
    
SELECT
	*
FROM
	employee
WHERE
	position = 'Field Surveyor'
    AND (phone_number LIKE '%86%' OR phone_number LIKE '%11%')
    AND (employee_name LIKE ' A%' OR employee_name LIKE ' M%');
    
SELECT *
FROM employee
WHERE position = 'Field Surveyor'
    AND (phone_number LIKE '%86%' OR phone_number LIKE '%11%')
    AND (SUBSTRING_INDEX(employee_name, ' ', -1) LIKE 'A%' 
         OR SUBSTRING_INDEX(employee_name, ' ', -1) LIKE 'M%');
         
SELECT COUNT(*)
FROM well_pollution
WHERE description LIKE 'Clean_%' OR results = 'Clean' AND biological < 0.01;

SELECT COUNT(*)
FROM well_pollution
WHERE description
IN ('Parasite: Cryptosporidium', 'biologically contaminated')
OR (results = 'Clean' AND biological > 0.01);


    

