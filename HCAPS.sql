-- "National & state-level scores from 2013 to 2022 for the Hospital Consumer Assessment of Healthcare Providers and Systems (HCAHPS) survey, a national, standardized survey of hospital patients about their experiences during a recent inpatient hospital stay.

-- Counting facilities

SELECT 
COUNT(DISTINCT `Facility ID`)
FROM hcaps.responses;

-- 5245 facilites were questioned over period of 9 years

-- Checking response rate

SELECT 
    AVG(`Response Rate (%)`),
    MIN(`Response Rate (%)`),
    MAX(`Response Rate (%)`)
FROM hcaps.responses rs
JOIN hcaps.states st ON rs.State = st.State;

-- Average response rate is 23.3081%, Minimal is 0%, Maximal - 100%

SELECT 
ROUND(100 *  SUM(CASE WHEN `Response Rate (%)` = 0 THEN 1 ELSE 0 END) / COUNT(`Facility ID`),2) as no_response_rate
FROM hcaps.responses rs
JOIN hcaps.states st ON rs.State = st.State;

-- 12.40 % of facilities have not responded

SELECT 
	`Completed Surveys`,
	COUNT(`Completed Surveys`)
FROM hcaps.responses rs
JOIN hcaps.states st ON rs.State = st.State
WHERE `Completed Surveys` REGEXP '[a-zA-Z]'
GROUP BY `Completed Surveys`
ORDER BY `Completed Surveys` ASC;

-- updating responses column

UPDATE hcaps.responses 
SET `Completed Surveys` = CASE
	WHEN `Completed Surveys` = 'Not Available' THEN 0
    WHEN `Completed Surveys` = '300 or more' THEN 400
    WHEN `Completed Surveys` = 'Between 100 and 299' THEN 200
    WHEN `Completed Surveys` = 'Fewer than 100' THEN 80
    WHEN `Completed Surveys` = 'FEWER THAN 50' THEN 25
    ELSE `Completed Surveys`
    END;
    
ALTER TABLE hcaps.responses 
MODIFY `Completed Surveys` INT;



-- Getting data to understand amount of survey bins

SELECT
	MAX(`Completed Surveys`)
FROM hcaps.responses;

-- Getting Survey data

SELECT 
	 DATE(`Start Date`) as Period,
    `State Name`,
        CASE
        WHEN `Completed Surveys` BETWEEN 1 AND 2000 THEN 'From 1 To 2000'
        WHEN `Completed Surveys` BETWEEN 2001 AND 4000 THEN 'From 2001 To 4000'
        WHEN `Completed Surveys` BETWEEN 4001 AND 6000 THEN 'From 4001 To 6000'
        WHEN `Completed Surveys` BETWEEN 6001 AND 8000 THEN 'From 6001 To 8000'
        WHEN `Completed Surveys` BETWEEN 8001 AND 10000 THEN 'From 8001 To 10000'
        WHEN `Completed Surveys` > 10000 THEN 'More than 10000'
        END as Completed_surveys,
	`Completed Surveys`,
    `Response Rate (%)`,
    `Region`
FROM hcaps.responses rs
JOIN hcaps.states st ON rs.State = st.State
JOIN hcaps.reports rep ON rs.`Release Period` = rep.`Release Period`
WHERE `Response Rate (%)` > 0;

-- Getting response data nationwide

SELECT 
	DATE(`Start Date`) as Period,
    Question,
    `Bottom-box Answer` as Answer,
    `Bottom-box Percentage` as '%_of_responses',
    Measure,
    Type,
    'Bottom' as Response
FROM hcaps.national_results nr
JOIN hcaps.measures m ON nr.`Measure ID` = m.`Measure ID`
JOIN hcaps.questions q ON nr.`Measure ID` = q.`Measure ID`
JOIN hcaps.reports rep ON nr.`Release Period` = rep.`Release Period`

UNION

SELECT 
	DATE(`Start Date`) as Period,
    Question,
    `Middle-box Answer` as Answer,
    `Middle-box Percentage` as '%_of_responses',
    Measure,
    Type,
    'Middle' as Response
FROM hcaps.national_results nr
JOIN hcaps.measures m ON nr.`Measure ID` = m.`Measure ID`
JOIN hcaps.questions q ON nr.`Measure ID` = q.`Measure ID`
JOIN hcaps.reports rep ON nr.`Release Period` = rep.`Release Period`
UNION

SELECT 
	DATE(`Start Date`) as Period,
    Question,
    `Top-box Answer` as Answer,
    `Top-box Percentage` as '%_of_responses',
    Measure,
    Type,
    'Top' as Response
FROM hcaps.national_results nr
JOIN hcaps.measures m ON nr.`Measure ID` = m.`Measure ID`
JOIN hcaps.questions q ON nr.`Measure ID` = q.`Measure ID`
JOIN hcaps.reports rep ON nr.`Release Period` = rep.`Release Period`;

-- Getting state response data

SELECT 
	DATE(`Start Date`) as Period,
    `State Name`,
    Region,
    Question,
    `Bottom-box Answer` as Answer,
    `Bottom-box Percentage` as '%_of_responses',
    Measure,
    Type,
    'Bottom' as Response
FROM hcaps.state_results str
JOIN hcaps.measures m ON str.`Measure ID` = m.`Measure ID`
JOIN hcaps.questions q ON str.`Measure ID` = q.`Measure ID`
JOIN hcaps.reports rep ON str.`Release Period` = rep.`Release Period`
JOIN hcaps.states st ON str.State = st.State

UNION

SELECT 
	DATE(`Start Date`) as Period,
    `State Name`,
    Region,
    Question,
    `Middle-box Answer` as Answer,
    `Middle-box Percentage` as '%_of_responses',
    Measure,
    Type,
    'Middle' as Response
FROM hcaps.state_results str
JOIN hcaps.measures m ON str.`Measure ID` = m.`Measure ID`
JOIN hcaps.questions q ON str.`Measure ID` = q.`Measure ID`
JOIN hcaps.reports rep ON str.`Release Period` = rep.`Release Period`
JOIN hcaps.states st ON str.State = st.State

UNION

SELECT 
	DATE(`Start Date`) as Period,
    `State Name`,
    Region,
    Question,
    `Top-box Answer` as Answer,
    `Top-box Percentage` as '%_of_responses',
    Measure,
    Type,
    'Top' as Response
FROM hcaps.state_results str
JOIN hcaps.measures m ON str.`Measure ID` = m.`Measure ID`
JOIN hcaps.questions q ON str.`Measure ID` = q.`Measure ID`
JOIN hcaps.reports rep ON str.`Release Period` = rep.`Release Period`
JOIN hcaps.states st ON str.State = st.State;

-- Getting unique questions

SELECT 
	DISTINCT Question
FROM hcaps.questions;

-- Calculating difference in state performance over 9 years

DROP VIEW IF EXISTS hcaps.view1;

CREATE VIEW hcaps.view1 AS     

  WITH CTE AS (SELECT 
    DATE(`Start Date`) AS Period,
    MIN(DATE(`Start Date`)) OVER () AS MN,
    `State Name`,
    Question,
    `Top-box Percentage` AS `%_of_responses`
  FROM hcaps.state_results str
  JOIN hcaps.measures m ON str.`Measure ID` = m.`Measure ID`
  JOIN hcaps.questions q ON str.`Measure ID` = q.`Measure ID`
  JOIN hcaps.reports rep ON str.`Release Period` = rep.`Release Period`
  JOIN hcaps.states st ON str.State = st.State)
  
  SELECT
	`State Name`,
	Question,
    `%_of_responses`
    FROM CTE
    WHERE Period = MN;

DROP VIEW IF EXISTS hcaps.view2;

CREATE VIEW hcaps.view2 AS     

  WITH CTE AS (SELECT 
    DATE(`Start Date`) AS Period,
    MAX(DATE(`Start Date`)) OVER () AS MN,
    `State Name`,
    Question,
    `Top-box Percentage` AS `%_of_responses`
  FROM hcaps.state_results str
  JOIN hcaps.measures m ON str.`Measure ID` = m.`Measure ID`
  JOIN hcaps.questions q ON str.`Measure ID` = q.`Measure ID`
  JOIN hcaps.reports rep ON str.`Release Period` = rep.`Release Period`
  JOIN hcaps.states st ON str.State = st.State)
  
  SELECT
	`State Name`,
	Question,
    `%_of_responses`
    FROM CTE
    WHERE Period = MN; 

SELECT
	v1.`State Name`,
    v1.Question,
    v2.`%_of_responses` - v1.`%_of_responses` as difference
FROM hcaps.view1 v1
JOIN hcaps.view2 v2 ON v1.`State Name` = v2.`State Name` AND v1.Question = v2.Question
