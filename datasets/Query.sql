--------> extracting and cleaning marketing data with SQL <----------
USE PortfolioProject_MarketingAnalytics;

-- 1. categorize products based on their price 
SELECT
	ProductID, ProductName, Price,

	CASE -- categorizes the products based on price values
		WHEN Price < 50 THEN 'Low'
		WHEN Price BETWEEN 50 AND 200 THEN 'Medium'
		ELSE 'High'
	END AS PriceCategory
FROM products;

-- ******************************************************
-- ******************************************************

-- 2. join customer with geography to enrich customer data with geographic information
SELECT 
	C.CustomerID, C.CustomerName, C.Email, C.Gender, C.Age,
	G.Country, G.City
FROM customers AS C
LEFT JOIN geography AS G
ON C.GeographyID = G.GeographyID

-- ******************************************************
-- ******************************************************

-- 3. clean Review Text field
SELECT 
	ReviewID, CustomerID, ProductID, ReviewDate, Rating,
	REPLACE(ReviewText, '  ', ' ') AS ReviewText
FROM customer_reviews;

-- UPDATE customer_reviews
-- SET ReviewText = REPLACE(ReviewText, '  ', ' ')
-- WHERE ReviewText LIKE '%  %';

select * from customer_reviews;
-- ******************************************************
-- ******************************************************

-- 4. Clean & Normalize Enagagement data
SELECT 
	EngagementID, ContentID, CampaignID, ProductID,
	UPPER(REPLACE(ContentType, 'Socialmedia', 'Social Media')) AS CoontentType,
	LEFT(ViewsClicksCombined, CHARINDEX('-', ViewsClicksCombined)-1) AS Views,
	RIGHT(ViewsClicksCombined, LEN(ViewsClicksCombined) - CHARINDEX('-', ViewsClicksCombined)) AS Clicks,
	Likes,
	FORMAT(CONVERT(DATE, EngagementDate), 'dd.MM.yyyy') AS EngagementDate
FROM engagement_data
WHERE ContentType != 'Newsletter';

-- ******************************************************
-- ******************************************************

-- 5. Common Table Expression (CTE) to identify & tag duplicate records
WITH DuplicateRecords AS (
	SELECT 
		*, 
		ROW_NUMBER() 
			OVER(
				PARTITION BY CustomerID, ProductID, VisitDate, Stage, Action -- group by
				ORDER BY JourneyID -- sort by asc order
				) AS row_num
	FROM customer_journey
)

SELECT * FROM DuplicateRecords
WHERE row_num > 1 -- if (=1) means unique, non-unique means (>1)
ORDER BY JourneyID;

-- ******************************************************
-- ******************************************************

-- 6. Fill Null Duration and clean dataset
SELECT 
	JourneyID, CustomerID, ProductID, VisitDate, Stage, Action,
	COALESCE(Duration, Avg_duration) AS Duration -- Replace missing value
FROM (
	SELECT 
		JourneyID, CustomerID, ProductID, VisitDate,
		UPPER(Stage) AS Stage,
		Action, Duration,
		AVG(Duration) OVER (PARTITION BY VisitDate) AS Avg_duration, -- avg duration for date wise
		ROW_NUMBER()
			OVER(
				PARTITION BY CustomerID, ProductID, VisitDate, UPPER(Stage), Action
				ORDER BY JourneyID
			) AS row_num
	FROM customer_journey
	) AS sub_query
WHERE row_num=1;