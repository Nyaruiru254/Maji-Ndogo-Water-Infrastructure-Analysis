-- Querying the database to be used
USE md_water_services;

/* 
View Name: combined_water_source_analysis
Purpose: Provide a unified dataset combining location details, visit metrics,
water source capacity, and pollution results. 
Assumptions: Only includes visits where visit_count = 1.
*/
CREATE VIEW combined_water_source_analysis AS
SELECT
	location.province_name,               	-- province where each water source is located
	location.town_name,                   	-- town in each province
	location.location_type,               	-- type of location (urban / rural)
	visits.time_in_queue,                 	-- time taken waiting to access water
	water_source.type_of_water_source,    	-- classification of the water source
	water_source.number_of_people_served, 	-- count of individuals served by a single water source
	well_pollution.results                	-- sanitation status of each well source
FROM
	visits
-- match well population table data with visits table data 
-- (missing records from well_population table will have nulls)
LEFT JOIN well_pollution
	ON well_pollution.source_id = visits.source_id
-- match water source table data with visits table data
INNER JOIN water_source
	ON water_source.source_id = visits.source_id
-- match location table data with visits table data
INNER JOIN  location
	ON location.location_id = visits.location_id
-- restrict to visits only recorded once
WHERE 
	visits.visit_count = 1;

/* 
Creating a pivot table for water source percentage usage per province and town
This query calculates the percentage of population served by each water source type
per province and town, based on first-visit data from the combined_water_source_analysis view
*/

-- Step 1: Calculate total population served per province
CREATE TEMPORARY TABLE aggregated_water_access_per_town AS
WITH province_totals AS (    
SELECT
	combined_water_source_analysis.province_name,
    combined_water_source_analysis.town_name,
    SUM(combined_water_source_analysis.number_of_people_served) AS total_number_of_people_served
FROM
	combined_water_source_analysis
GROUP BY
    combined_water_source_analysis.province_name,
    combined_water_source_analysis.town_name
)
-- Step 2: Calculate percentage breakdowns by source type for each province
SELECT
	combined_water_source_analysis.province_name,
    combined_water_source_analysis.town_name,
    ROUND(SUM(CASE WHEN type_of_water_source = 'well'
		THEN number_of_people_served ELSE 0 END) / province_totals.total_number_of_people_served * 100.0) AS 'well',
    ROUND(SUM(CASE WHEN type_of_water_source = 'tap_in_home'
		THEN number_of_people_served ELSE 0 END) / province_totals.total_number_of_people_served * 100.0) AS 'tap_in_home',
    ROUND(SUM(CASE WHEN type_of_water_source = 'river'
		THEN number_of_people_served ELSE 0 END) / province_totals.total_number_of_people_served * 100.0) AS 'river',
    ROUND(SUM(CASE WHEN type_of_water_source = 'tap_in_home_broken'
		THEN number_of_people_served ELSE 0 END) / province_totals.total_number_of_people_served * 100.0) AS 'tap_in_home_broken',
    ROUND(SUM(CASE WHEN type_of_water_source = 'shared_tap'
		THEN number_of_people_served ELSE 0 END) / province_totals.total_number_of_people_served * 100.0) AS 'shared_tap'
	FROM
		combined_water_source_analysis
	-- Join with CTE to get province totals for percentage calculation
	JOIN province_totals
		ON combined_water_source_analysis.province_name = province_totals.province_name
        AND combined_water_source_analysis.town_name = province_totals.town_name
	-- Group by province to get one row per province with all source type sums
	GROUP BY
		combined_water_source_analysis.province_name,
        combined_water_source_analysis.town_name
	-- Display results alphabetically by province
	ORDER BY
		  combined_water_source_analysis.province_name;

/*
This query is meant to find out the percentage of broken taps in every town and province
*/
SELECT
	town_name,
    province_name,
    ROUND(tap_in_home_broken / tap_in_home + tap_in_home_broken) * 100.0 AS pct_tap_in_home_broken
FROM
	aggregated_water_access_per_town
ORDER BY
	pct_tap_in_home_broken;

-- Create a table to track water source improvement projects
CREATE TABLE project_progress (

 -- Auto-incrementing unique identifier for each project record
-- SERIAL generates sequential numbers automatically
project_id SERIAL PRIMARY KEY,

-- References the specific water source being improved
-- Foreign key ensures we only work with existing sources
source_id VARCHAR (20) NOT NULL 
	REFERENCES water_source(source_id) 
    ON DELETE CASCADE
    ON UPDATE CASCADE,

-- street address for each source
address VARCHAR (50),

-- town name for each source
town_name VARCHAR (30),

-- province name for each source
province_name VARCHAR (30),

-- classification of water source
type_of_water_source VARCHAR (50),

-- specific actions engineers need to make at this source
improvement VARCHAR (50),

-- Current status of the project
-- Default is 'backlog' (waiting to be started)
-- CHECK constraint limits to only these three valid statuses
source_status VARCHAR (50) DEFAULT 'backlog' 
	CHECK (source_status IN ('backlog', 'in progress', 'complete')),

-- Date when engineers completed the work
-- NULL until project is finished
date_of_completion DATE,
 
-- Additional notes or observations from engineers
-- TEXT type allows unlimited length
comments TEXT
);

ALTER TABLE project_progress 
MODIFY source_id VARCHAR(50) NOT NULL;

INSERT INTO project_progress (source_id, address, province_name, town_name, type_of_water_source, improvement)
SELECT
	location.address,
	location.province_name,
	location.town_name,
	water_source.source_id,
	water_source.type_of_water_source,
		-- determining the improvements needed
		CASE
			-- wells with biological pollution
			WHEN water_source.type_of_water_source = 'well' AND well_pollution.results = 'Contaminated: Biological'
				THEN  'Install UV and RO filter'
					
			-- wells with chemical pollution
			WHEN water_source.type_of_water_source = 'well' AND well_pollution.results = 'Contaminated: Chemical'
				THEN 'Install RO filter'
					
			-- rivers
			WHEN water_source.type_of_water_source = 'river' 
				THEN 'Drill Wells'
					
			-- broken taps in homes
			WHEN water_source.type_of_water_source = 'tap_in_home_broken' 
				THEN 'Diagnose local infrastructure'
                
			-- rivers  
			WHEN water_source.type_of_water_source = 'river'  
				THEN 'Drill Wells'  

			-- broken taps in homes  
			WHEN water_source.type_of_water_source = 'tap_in_home_broken'  
				THEN 'Diagnose local infrastructure'  
			
			-- shared taps with waiting times longer than 30 minutes
			WHEN water_source.type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30
				THEN	
					CASE
						-- Special case: At exactly 60 min, install ONLY 1 tap
						-- (Second tap only installed when queue > 60 min)
						WHEN visits.time_in_queue = 60
							THEN 'Install 1 tap nearby'
						-- Normal calculation: 1 tap per 30 min of queue time
						ELSE CONCAT('Install ', FLOOR(visits.time_in_queue/30), ' taps nearby')
						END
	ELSE 'No action needed'
	END AS improvement
FROM
	water_source
LEFT JOIN well_pollution
	ON well_pollution.source_id = water_source.source_id
INNER JOIN visits
	ON visits.source_id = water_source.source_id
INNER JOIN location
	ON visits.location_id = location.location_id
WHERE
	visits.visit_count = 1
    AND (
	(water_source.type_of_water_source = 'well'  AND well_pollution.results != 'Clean')
    OR  water_source.type_of_water_source = 'river'
    OR water_source.type_of_water_source = 'tap_in_home_broken'
    OR (water_source.type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30)
    );
    
SELECT
	*
FROM
	project_progress;
  
-- Determine the number of UV filters needed to be installed
-- Assumption: UV filters ae installed for wells with biological contamination
SELECT
	COUNT(results)
FROM
	well_pollution
WHERE
	results = 'Contaminated: Biological';
 

SELECT
	town_name,
	AVG(time_in_queue),
    AVG(number_of_people_served),
    type_of_water_source
FROM
	combined_water_source_analysis
GROUP BY
	town_name,
    type_of_water_source
ORDER BY
	     AVG(time_in_queue);
         
SELECT
    town_name,
    AVG(time_in_queue) AS avg_queue_time,
    SUM(number_of_people_served) AS total_people_served_by_shared_taps,
    COUNT(*) AS number_of_shared_taps
FROM
    combined_water_source_analysis
WHERE
    type_of_water_source = 'shared_tap'  -- Only shared taps!
    AND time_in_queue IS NOT NULL
GROUP BY
    town_name
HAVING
    AVG(time_in_queue) >= 30  -- Only towns with queue problems
ORDER BY 
    AVG(time_in_queue) DESC,  -- Longest queues first
    total_people_served_by_shared_taps DESC;  -- Then most people affected
         
  
  
WITH total_home_taps_per_province AS 
(
	SELECT
		province_name,
        town_name,
        SUM(CASE WHEN type_of_water_source IN ('tap_in_home_broken', 'tap_in_home')
			THEN 1 ELSE 0 END) AS total_home_taps
	FROM
		combined_water_source_analysis
	GROUP BY
		province_name,
		town_name
	ORDER BY
		province_name
)
SELECT
	total_home_taps_per_province.province_name,
    total_home_taps_per_province.town_name,
    ROUND(SUM(CASE WHEN combined_water_source_analysis.type_of_water_source = 'tap_in_home'
		THEN 1 ELSE 0 END) / total_home_taps_per_province.total_home_taps * 100.0, 2) AS pct_working_taps,
	ROUND(SUM(CASE WHEN combined_water_source_analysis.type_of_water_source = 'tap_in_home_broken'
		THEN 1 ELSE 0 END) / total_home_taps_per_province.total_home_taps * 100.0, 2) AS pct_broken_taps
FROM
	combined_water_source_analysis
JOIN
	total_home_taps_per_province
	ON total_home_taps_per_province.province_name = combined_water_source_analysis.province_name
    AND total_home_taps_per_province.town_name = combined_water_source_analysis.town_name
GROUP BY
	combined_water_source_analysis.province_name,
    combined_water_source_analysis.town_name,
    total_home_taps_per_province.total_home_taps
ORDER BY
	combined_water_source_analysis.province_name;
	