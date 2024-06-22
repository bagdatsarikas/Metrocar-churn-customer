----------    FUNNEL ANALYSIS AND EXPLORATION    ---------------


/*
This SQL query will analyze Metrocar's general drop-off and conversion rate user engagement funnel for the 
entire year of 2021. The analysis will track user progression through 
the following stages:

1. Download 
2. Sign up 
3. Ride request 
4. Ride acceptance 
5. Payment
*/ 


-- Downloads: Identify all unique app downloads within the year of 2021

WITH downloads AS (
  SELECT
  	0 AS funnel_step,
  	'download' AS funnel_name,
  	COUNT(DISTINCT app_download_key) AS total_users,
  	0 AS ride_count
  FROM app_downloads
  WHERE download_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59'
),

-- Sign-ups: Track users who signed up after downloading the app within the year of 2021

signup AS(
  SELECT 
  	1 AS funnel_step,
  	'signups' AS funnel_name,
  	COUNT(DISTINCT s.user_id) as total_users,
  	0 AS ride_count
  FROM signups s
  JOIN app_downloads a ON s.session_id = a.app_download_key
  WHERE (a.download_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59') 
  AND (signup_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59')
  
),

-- Ride Requests: Identify initial ride requests from signed up users in 2021

ride_requested AS(
  SELECT 
  	3 AS funnel_step,
  	'ride_request' AS funnel_name,
  	COUNT(DISTINCT r.user_id) AS total_users,
  	COUNT(r.ride_id) AS ride_count
  FROM ride_requests r
  JOIN signups s ON r.user_id = s.user_id
  JOIN app_downloads a ON a.app_download_key = s.session_id
  WHERE (r.request_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59')
  AND   (a.download_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59') 
  AND   (s.signup_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59')
  
  			
),

-- Ride Accept: Identify total users and rides  have been accepted in 2021

ride_accepted AS (
  SELECT 
  	4 AS funnel_step,
  	'ride_accepted' AS funnel_name,
  	COUNT(DISTINCT r.user_id) AS total_users,
  	COUNT(r.ride_id) AS ride_count
  FROM ride_requests r
  JOIN signups s ON r.user_id = s.user_id
  JOIN app_downloads a ON a.app_download_key = s.session_id
  WHERE r.request_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59'
    AND a.download_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59'
    AND s.signup_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59'
  	AND r.accept_ts IS NOT NULL
 
  	
),

-- Ride Completions: Count users and rides that were successfully completed in 2021

ride_completed AS (
  SELECT 
  	5 AS funnel_step,
  	'ride_completed' AS funnel_name,
  	COUNT(DISTINCT r.user_id) AS total_users,
  	COUNT(r.ride_id) AS ride_count
  FROM ride_requests r
  JOIN signups s ON r.user_id = s.user_id
  JOIN app_downloads a ON a.app_download_key = s.session_id
  WHERE r.request_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59'
    AND a.download_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59'
    AND s.signup_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59'
  	AND r.dropoff_ts IS NOT NULL
 
),

-- Payment: Count users and  rides that were successfully completed transaction in 2021

Payment AS ( 
	SELECT 
  	6 AS funnel_step,
  	'payment' AS funnel_name,
  	COUNT(DISTINCT r.user_id) as total_users,
  	COUNT(r.ride_id) AS ride_count
	FROM transactions t
  JOIN ride_requests r ON r.ride_id = t.ride_id
  JOIN signups s ON s.user_id = r.user_id
  JOIN app_downloads a ON a.app_download_key = s.session_id
  WHERE r.request_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59'
    AND a.download_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59'
    AND s.signup_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59'
  	AND t.transaction_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59'
  	AND t.charge_status = 'Approved'
	
  
),

-- Union all tables to show funnel stage, funnel name total users and total rides.

funnel AS (

SELECT * from downloads
UNION 
SELECT * from signup
UNION 
SELECT * from ride_requested
UNION 
SELECT * from ride_accepted
UNION 
SELECT * from ride_completed
UNION 
SELECT * from payment
ORDER BY funnel_step
  
),

-- Calculate Drop-off rates based on the previous step's total user

dropoff_and_conversion_rate AS (
  SELECT 
    f1.funnel_step,
    f1.funnel_name,
    f1.total_users,
    f1.ride_count,
    COALESCE(ROUND((1 - f1.total_users::numeric / LAG(f1.total_users, 1) OVER (ORDER BY f1.funnel_step))*100, 2), 0) AS drop_off_percentage,
  	COALESCE(ROUND((f1.total_users::numeric / LAG(f1.total_users, 1) OVER (ORDER BY f1.funnel_step))*100, 2), 0) AS conversion_percentage
  	
  FROM funnel f1
)

SELECT * FROM dropoff_and_conversion_rate;


/*
This SQL query will conduct an in-depth analysis of Metrocar's user engagement funnel,
focusing on platform( IOS ANDROID WEB)  drop-off and conversion rates for the year 2021. 
It will track the progression of different platform through these key stages:

1. Download 
2. Sign up 
3. Ride request 
4. Ride acceptance 
5. Payment

*/

-- Downloads: Identify all unique app downloads within the year of 2021, grouped by platform

WITH downloads AS (
  SELECT
  	0 AS funnel_step,
  	'download' AS funnel_name,
  	a.platform AS platform,
  	COUNT(DISTINCT a.app_download_key) AS total_users,
  	0 AS ride_count
  FROM app_downloads a
  WHERE download_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59'
  GROUP BY a.platform
),

-- Sign-ups: Track users who signed up after downloading the app within the year of 2021

signup AS(
  SELECT 
  	1 AS funnel_step,
  	'signups' AS funnel_name,
    a.platform AS platform, 
  	COUNT(DISTINCT s.user_id) as total_users,
  	0 AS ride_count
  FROM signups s
  JOIN app_downloads a ON s.session_id = a.app_download_key
  WHERE (a.download_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59') 
  AND (signup_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59')
  GROUP BY a.platform
),

-- Ride Requests: Identify initial ride requests from signed up users in 2021,grouped by platform

ride_requested AS(
  SELECT 
  	3 AS funnel_step,
  	'ride_request' AS funnel_name,
  	a.platform AS platform,
  	COUNT(DISTINCT r.user_id) AS total_users,
  	COUNT(r.ride_id) AS ride_count
  FROM ride_requests r
  JOIN signups s ON r.user_id = s.user_id
  JOIN app_downloads a ON a.app_download_key = s.session_id
  WHERE (r.request_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59')
  AND   (a.download_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59') 
  AND   (s.signup_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59')
  GROUP BY a.platform
  			
),

-- Ride Accept: Identify total users and rides  have been accepted in 2021,grouped by platform

ride_accepted AS (
  SELECT 
  	4 AS funnel_step,
  	'ride_accepted' AS funnel_name,
  	a.platform AS platform,
  	COUNT(DISTINCT r.user_id) AS total_users,
  	COUNT(r.ride_id) AS ride_count
  FROM ride_requests r
  JOIN signups s ON r.user_id = s.user_id
  JOIN app_downloads a ON a.app_download_key = s.session_id
  WHERE r.request_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59'
    AND a.download_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59'
    AND s.signup_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59'
  	AND r.accept_ts IS NOT NULL
  GROUP BY a.platform
 
  	
),

-- Ride Completions: Count users and rides that were successfully completed in 2021, grouped by platform

ride_completed AS (
  SELECT 
  	5 AS funnel_step,
  	'ride_completed' AS funnel_name,
  	a.platform AS platform,
  	COUNT(DISTINCT r.user_id) AS total_users,
  	COUNT(r.ride_id) AS ride_count
  FROM ride_requests r
  JOIN signups s ON r.user_id = s.user_id
  JOIN app_downloads a ON a.app_download_key = s.session_id
  WHERE r.request_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59'
    AND a.download_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59'
    AND s.signup_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59'
  	AND r.dropoff_ts IS NOT NULL
 	GROUP BY a.platform
),

-- Payment: Count users and  rides that were successfully completed transaction in 2021, grouped by platform

Payment AS ( 
	SELECT 
  	6 AS funnel_step,
  	'payment' AS funnel_name,
  	a.platform AS platform,
  	COUNT(DISTINCT r.user_id) as total_users,
  	COUNT(r.ride_id) AS ride_count
	FROM transactions t
  JOIN ride_requests r ON r.ride_id = t.ride_id
  JOIN signups s ON s.user_id = r.user_id
  JOIN app_downloads a ON a.app_download_key = s.session_id
  WHERE r.request_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59'
    AND a.download_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59'
    AND s.signup_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59'
  	AND t.transaction_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59'
  	AND t.charge_status = 'Approved'
  GROUP BY a.platform
	
  
),

-- Union all tables to show funnel stage, funnel name total users and total rides, grouped by platform

funnel AS (

SELECT * from downloads
UNION 
SELECT * from signup
UNION 
SELECT * from ride_requested
UNION 
SELECT * from ride_accepted
UNION 
SELECT * from ride_completed
UNION 
SELECT * from payment
ORDER BY funnel_step
),

-- Calculate Drop-off rates based on the previous step's total user, grouped by platform.

dropoff_and_conversion_rate AS (
  SELECT 
    f1.funnel_step,
    f1.funnel_name,
    f1.total_users,
    f1.ride_count,
    f1.platform,
    COALESCE(ROUND((1 - f1.total_users::numeric / LAG(f1.total_users, 1) OVER (PARTITION BY platform ORDER BY f1.funnel_step))*100, 2), 0) AS drop_off_percentage,
  	COALESCE(ROUND((f1.total_users::numeric / LAG(f1.total_users, 1) OVER (PARTITION BY platform ORDER BY f1.funnel_step))*100, 2), 0) AS conversion_percentage
  	
  FROM funnel f1
)

-- SELECT ANY PLATFORM ( WEB IOS ANDROID)
SELECT * FROM dropoff_and_conversion_rate
WHERE platform = 'web';




/*
This SQL query will conduct an in-depth analysis of Metrocar's user engagement funnel,
focusing on age groups  drop-off and conversion rates for the year 2021. 
It will track the progrssion of different platform through these key stages:

1. Download 
2. Sign up 
3. Ride request 
4. Ride acceptance 
5. Payment

*/

-- Downloads: Identify all unique app downloads within the year of 2021, grouped by age

WITH downloads AS (
  SELECT
  	0 AS funnel_step,
  	'download' AS funnel_name,
  	COUNT(DISTINCT a.app_download_key) AS total_users,
  	0 AS ride_count,
  	s.age_range
  FROM app_downloads a
  left join signups s on s.session_id = a.app_download_key
  WHERE download_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59'
  group by s.age_range
  
),

-- Sign-ups: Track users who signed up after downloading the app within the year of 2021

signup AS(
  SELECT 
  	1 AS funnel_step,
  	'signups' AS funnel_name, 
  	COUNT(DISTINCT s.user_id) as total_users,
  	0 AS ride_count,
  	s.age_range
  FROM signups s
  JOIN app_downloads a ON s.session_id = a.app_download_key
  WHERE (a.download_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59') 
  AND (signup_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59')
  GROUP BY s.age_range
),

-- Ride Requests: Identify initial ride requests from signed up users in 2021,grouped by age

ride_requested AS(
  SELECT 
  	3 AS funnel_step,
  	'ride_request' AS funnel_name,
  	COUNT(DISTINCT r.user_id) AS total_users,
  	COUNT(r.ride_id) AS ride_count,
  	s.age_range
  FROM ride_requests r
  JOIN signups s ON r.user_id = s.user_id
  JOIN app_downloads a ON a.app_download_key = s.session_id
  WHERE (r.request_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59')
  AND   (a.download_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59') 
  AND   (s.signup_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59')
  GROUP BY s.age_range
  			
),

-- Ride Accept: Identify total users and rides  have been accepted in 2021,grouped by age

ride_accepted AS (
  SELECT 
  	4 AS funnel_step,
  	'ride_accepted' AS funnel_name,
  	COUNT(DISTINCT r.user_id) AS total_users,
  	COUNT(r.ride_id) AS ride_count,
  	s.age_range
  FROM ride_requests r
  JOIN signups s ON r.user_id = s.user_id
  JOIN app_downloads a ON a.app_download_key = s.session_id
  WHERE r.request_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59'
    AND a.download_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59'
    AND s.signup_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59'
  	AND r.accept_ts IS NOT NULL
  GROUP BY s.age_range
 
  	
),

-- Ride Completions: Count users and rides that were successfully completed in 2021, grouped by age

ride_completed AS (
  SELECT 
  	5 AS funnel_step,
  	'ride_completed' AS funnel_name,
  	COUNT(DISTINCT r.user_id) AS total_users,
  	COUNT(r.ride_id) AS ride_count,
  	s.age_range
  FROM ride_requests r
  JOIN signups s ON r.user_id = s.user_id
  JOIN app_downloads a ON a.app_download_key = s.session_id
  WHERE r.request_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59'
    AND a.download_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59'
    AND s.signup_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59'
  	AND r.dropoff_ts IS NOT NULL
 	GROUP BY s.age_range
),

-- Payment: Count users and  rides that were successfully completed transaction in 2021, grouped by age

Payment AS ( 
	SELECT 
  	6 AS funnel_step,
  	'payment' AS funnel_name,
  	COUNT(DISTINCT r.user_id) as total_users,
  	COUNT(r.ride_id) AS ride_count,
  	s.age_range
  FROM transactions t
  JOIN ride_requests r ON r.ride_id = t.ride_id
  JOIN signups s ON s.user_id = r.user_id
  JOIN app_downloads a ON a.app_download_key = s.session_id
  WHERE r.request_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59'
    AND a.download_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59'
    AND s.signup_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59'
  	AND t.transaction_ts BETWEEN '2021-01-01 00:00:00' AND '2021-12-31 23:59:59'
  	AND t.charge_status = 'Approved'
  GROUP BY s.age_range
	
  
),

-- Union all tables to show funnel stage, funnel name total users and total rides, grouped by platform

funnel AS (

SELECT * from downloads
UNION 
SELECT * from signup
UNION 
SELECT * from ride_requested
UNION 
SELECT * from ride_accepted
UNION 
SELECT * from ride_completed
UNION 
SELECT * from payment
ORDER BY funnel_step
),

-- Calculate Drop-off rates based on the previous step's total user, grouped by platform.

dropoff_and_conversion_rate AS (
  SELECT 
    f1.funnel_step,
    f1.funnel_name,
    f1.total_users,
    f1.ride_count,
    f1.age_range,
    COALESCE(ROUND((1 - f1.total_users::numeric / LAG(f1.total_users, 1) OVER (PARTITION BY age_range ORDER BY f1.funnel_step))*100, 2), 0) AS drop_off_percentage,
  	COALESCE(ROUND((f1.total_users::numeric / LAG(f1.total_users, 1) OVER (PARTITION BY age_range ORDER BY f1.funnel_step))*100, 2), 0) AS conversion_percentage
  	
  FROM funnel f1
)

SELECT 
  funnel_step,
  funnel_name,
  age_range,
  total_users,
  ride_count,
  drop_off_percentage,
  conversion_percentage
FROM dropoff_and_conversion_rate 
ORDER BY age_range;


































