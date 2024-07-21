
--getting to know the data
show tables
from md_water_services

SELECT *
FROM location,
water_source,
water_quality,
well_pollution
LIMIT 10;

select *
from location

--dive into the water sources
SELECT type_of_water_source 
FROM water_source
GROUP BY type_of_water_source;

--unpacking the visit time table
--all recordes where time in a queue is => 500min
SELECT *
FROM visits
WHERE
time_in_queue>=500

--type of water sources with long time in a queue
SELECT *
FROM
water_source
WHERE 
source_id IN ('AkKi00881224', 'SoRu37635224', 'SoRu36096224','AkRu05234224',
'HaZa21742224','AkLu01628224')
ORDER BY number_of_people_served DESC

--Assess the quality of water sources:
SELECT *
FROM water_quality
WHERE subjective_quality_score = 10
AND
Visit_count>1

--Investigate pollution issues:

SELECT*
FROM well_pollution

--close checking data where the results is clean but the biological contamination is >0.01
SELECT *
FROM well_pollution
WHERE
results = 'clean'
AND
biological >0.01

SELECT *
FROM well_pollution
WHERE
description LIKE 'clean_%'

--Case 1a: Update descriptions that mistakenly mention`Clean Bacteria: E. coli` to `Bacteria: E. coli`

UPDATE well_pollution
      SET description = 'Bacteria: E. coli'
	   WHERE description = 'Clean Bacteria: E. coli';
    
--Case 1b: Update the descriptions that mistakenly mention`Clean Bacteria: Giardia Lamblia` to `Bacteria: Giardia Lamblia

UPDATE well_pollution
  SET description = 'Bacteria: Giardia Lamblia'
  WHERE description= 'Clean Bacteria: Giardia Lamblia'
  
  --Case 2: Update the `result` to `Contaminated: Biological` where`biological` is greater than 0.01 plus current results is `Clean`

UPDATE well_pollution
SET results = 'Contamianted: Biological'
WHERE biological >0.01

--Data cleaning
--Adding email address
SELECT*
FROM employee

SELECT
     REPLACE(employee_name,' ','.') 
FROM employee

  
SELECT
     LOWER(REPLACE(employee_name,' ','.')) 
FROM employee


SELECT 
     CONCAT(
     LOWER(REPLACE(employee_name,' ','.')), '@ndogowater.gov') AS new_email
FROM employee

UPDATE employee
SET email = CONCAT(LOWER(REPLACE(employee_name, ' ', '.')), '@ndogowater.gov')

--checking phone number column

SELECT 
     LENGTH(phone_number)
FROM employee

--removing leading or trailing spaces from phone number column

SELECT 
      TRIM(phone_number) AS new_phone_number
FROM employee

UPDATE employee
SET phone_number = TRIM(phone_number)

SELECT * 
FROM employee

--Aggregating employees info: address, perfomance...

SELECT town_name, COUNT(town_name) AS num_employees
FROM employee
GROUP BY town_name

SELECT assigned_employee_id, COUNT(visit_count) AS number_of_visit
FROM visits
GROUP BY assigned_employee_id
LIMIT 3

-- Top 3 employees: name,phone number, email

SELECT employee_name,phone_number,email
FROM employee
WHERE 
assigned_employee_id IN (0,1,2)

--analysing locations to understand where the water sources are
-- records per town

SELECT COUNT(town_name) AS records_per_town, town_name 
FROM location
GROUP BY town_name
ORDER BY records_per_town DESC

--records per province
SELECT COUNT(province_name) AS records_per_province, province_name 
FROM location
GROUP BY province_name
ORDER BY records_per_province DESC

-- results that shows every province and town has many documented source of water.

SELECT 
      province_name, town_name, COUNT(town_name) AS records_per_town
FROM location
GROUP BY town_name, province_name
ORDER BY province_name,records_per_town DESC

--number of records for each location type
SELECT
      COUNT(location_type) AS number_sources,
     location_type     
FROM location
GROUP BY location_type

--Diving into the water sources
SELECT * 
FROM water_source

--How many people did were survied in total

SELECT SUM(number_of_people_served)
FROM water_source

--How many wells, taps and rivers are there?

SELECT  type_of_water_source,COUNT(type_of_water_source) AS Total_Types_of_watersources
FROM water_source
GROUP BY type_of_water_source
ORDER BY Total_Types_of_watersources DESC

-- How many people uses water sources on average.

SELECT type_of_water_source, ROUND(AVG(number_of_people_served),0) AS Avrg_number_of_people_using_eachsource
FROM water_source
GROUP BY type_of_water_source

 --Total number of people getting water from each type of source
 
SELECT type_of_water_source,SUM(number_of_people_served) AS people_served_by_eachtype
FROM water_source
GROUP BY type_of_water_source
ORDER BY people_served_by_eachtype DESC

-- Total percentage of people getting water from each type of source

SELECT 
type_of_water_source,ROUND(SUM(number_of_people_served)/27000000*100,0) AS percentage_of_people_served_by_eachtype
FROM water_source
GROUP BY type_of_water_source
ORDER BY percentage_of_people_served_by_eachtype DESC

--Ranking number of people served based on water source consided unclean

SELECT 
    type_of_water_source,
    total_number_of_people_served,
    RANK() OVER (ORDER BY total_number_of_people_served DESC) AS ranks
FROM (
    SELECT 
        type_of_water_source, 
        SUM(number_of_people_served) AS total_number_of_people_served
    FROM 
        water_source
    WHERE 
        type_of_water_source != 'tap_in_home'
    GROUP BY 
        type_of_water_source
) AS aggregated_data;

--water sources to priotize based on the number of people they serve
SELECT 
    source_id,
    type_of_water_source,
    number_of_people_served,
    DENSE_RANK() OVER (ORDER BY number_of_people_served DESC) AS priority_rank
FROM water_source

--How long the survey took
SELECT
  MAX(total_days) - MIN(total_days) AS day_difference
FROM (
  SELECT
    DATEDIFF('2023-07-14', time_of_record) AS total_days
  FROM visits
) AS subquery;

-- how long people have to queue on average

SELECT ROUND(AVG(NULLIF(time_in_queue, 0)),0) AS Average_queuetime
FROM visits;

--the queue times aggregated across the different days of the week.
SELECT 
 DAYNAME(time_of_record) AS Day_of_week,
    ROUND(AVG(NULLIF(time_in_queue, 0)), 0) AS Average_queuetime
FROM visits
GROUP BY Day_of_week
ORDER BY FIELD(Day_of_week, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday');

--the queue times aggregated across the different hours of the day.
SELECT 
TIME_FORMAT(TIME(time_of_record), '%H:00') AS Hour_of_day,
    ROUND(AVG(NULLIF(time_in_queue, 0)), 0) AS Average_queuetime
FROM visits
GROUP BY Hour_of_day
ORDER BY Hour_of_day;

--average time in the queue for all days

SELECT
  TIME_FORMAT(TIME(time_of_record), '%H:00') AS hour_of_day,

  -- Monday
  ROUND(AVG(
    CASE
      WHEN DAYNAME(time_of_record) = 'Monday' THEN NULLIF(time_in_queue, 0)
      ELSE NULL
    END
  ), 0) AS Monday,

  -- Tuesday
  ROUND(AVG(
    CASE
      WHEN DAYNAME(time_of_record) = 'Tuesday' THEN NULLIF(time_in_queue, 0)
      ELSE NULL
    END
  ), 0) AS Tuesday,

  -- Wednesday
  ROUND(AVG(
    CASE
      WHEN DAYNAME(time_of_record) = 'Wednesday' THEN NULLIF(time_in_queue, 0)
      ELSE NULL
    END
  ), 0) AS Wednesday,

  -- Thursday
  ROUND(AVG(
    CASE
      WHEN DAYNAME(time_of_record) = 'Thursday' THEN NULLIF(time_in_queue, 0)
      ELSE NULL
    END
  ), 0) AS Thursday,

  -- Friday
  ROUND(AVG(
    CASE
      WHEN DAYNAME(time_of_record) = 'Friday' THEN NULLIF(time_in_queue, 0)
      ELSE NULL
    END
  ), 0) AS Friday,

  -- Saturday
  ROUND(AVG(
    CASE
      WHEN DAYNAME(time_of_record) = 'Saturday' THEN NULLIF(time_in_queue, 0)
      ELSE NULL
    END
  ), 0) AS Saturday,

  -- Sunday
  ROUND(AVG(
    CASE
      WHEN DAYNAME(time_of_record) = 'Sunday' THEN NULLIF(time_in_queue, 0)
      ELSE NULL
    END
  ), 0) AS Sunday

FROM
  visits
GROUP BY
  hour_of_day
ORDER BY
  hour_of_day;

--joining the tables

SELECT
    auditor_report.location_id AS audit_location,
    auditor_report.true_water_source_score,
    visits.location_id AS visit_location,
    visits.record_id,
	water_quality.subjective_quality_score
    
FROM
    auditor_report, water_quality
JOIN
   visits
   ON water_quality.record_id = visits.location_id
--------
SELECT
    ar.location_id AS audit_location,
    ar.true_water_source_score,
    v.location_id AS visit_location,
    v.record_id,
    wq.subjective_quality_score
FROM
    auditor_report ar
JOIN
    visits v
    ON ar.location_id = v.location_id
JOIN
    water_quality wq 
    ON v.record_id = wq.record_id;

--cleaning the joined tables

SELECT
    ar.location_id AS audit_location,
    ar.true_water_source_score AS auditor_score,
    v.record_id,
    wq.subjective_quality_score AS surveyor_score
FROM
    auditor_report ar
JOIN
    visits v
    ON ar.location_id = v.location_id
JOIN
    water_quality wq 
    ON v.record_id = wq.record_id;



SELECT 
    v.visit_count,
    ar.location_id AS audit_location,
    v.record_id,
    ar.true_water_source_score AS auditor_score,
    wq.subjective_quality_score AS surveyor_score,
    ar.true_water_source_score - wq.subjective_quality_score AS Verification
FROM
    auditor_report ar
JOIN
    visits v
    ON ar.location_id = v.location_id
JOIN
    water_quality wq 
    ON v.record_id = wq.record_id
WHERE v.visit_count = 1;



