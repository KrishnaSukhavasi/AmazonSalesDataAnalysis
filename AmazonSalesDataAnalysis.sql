CREATE DATABASE amazon_sales_db;
USE amazon_sales_db;

SELECT * FROM AMAZON;

SET SQL_SAFE_UPDATES = 0;

-- ADDING timeofday COLUMN
ALTER TABLE amazon ADD COLUMN timeofday VARCHAR(20);
UPDATE amazon
SET timeofday = CASE
    WHEN HOUR(time) >=6 AND HOUR(time) < 12 THEN 'Morning'
    WHEN HOUR(time) >=12 AND HOUR(time) < 18 THEN 'Afternoon'
    WHEN HOUR(time) >=18 AND HOUR(time) < 24 THEN 'Evening'
    ELSE 'Night'
    END;
    
--  Adding dayname COLUMN
ALTER TABLE amazon ADD COLUMN dayname VARCHAR(20);
UPDATE amazon
SET dayname = DATE_FORMAT(date, '%a');    

# Adding monthname column
ALTER TABLE amazon ADD COLUMN monthname VARCHAR(20);
UPDATE amazon
SET monthname = DATE_FORMAT(date, '%b');

-- 1) Product analysis
-- Conduct analysis on the data to understand the different product lines, 
-- the products lines performing best and the product lines that need to be improved.
SELECT 
    `Product line`,
    ROUND(SUM(total), 2) AS Total_Revenue,
    (SELECT ROUND(SUM(`total`) / COUNT(DISTINCT `Product line`), 2) FROM amazon) AS Average_Revenue,
    ROUND(SUM(total) * 100 / (SELECT SUM(total) FROM amazon), 2) AS Revenue_Percentage,
    RANK() OVER(ORDER BY ROUND(SUM(total), 2) DESC) AS Revenue_Rank
FROM amazon
GROUP BY `Product line`
ORDER BY Total_Revenue DESC;


-- Product line-Comparision of  Sales
SELECT `Product line`, COUNT(`Invoice id`) AS Sales,
       (SELECT ROUND(COUNT(`Invoice id`)/COUNT(DISTINCT `Product line`),0) FROM amazon) AS Average_Sales,
       RANK() OVER(ORDER BY COUNT(`Invoice id`) DESC) AS Sales_Rank
FROM amazon 
GROUP BY `Product line`
ORDER BY Sales DESC;

--  Average Rating per Product Line (Customer Satisfaction)
SELECT `Product line`, 
       ROUND(AVG(Rating), 2) AS avg_rating
FROM amazon
GROUP BY `Product line`
ORDER BY avg_rating DESC;

-- 2) Sales analysis
-- Sales by Month 
SELECT  
    DATE_FORMAT(date, '%b') AS Month,  
    COUNT(`Invoice id`) AS Sales  
FROM amazon  
GROUP BY Month;

-- Branch Performance in Sales  
SELECT  
    Branch,  
    COUNT(`Invoice id`) AS Sales  
FROM amazon  
GROUP BY Branch  
ORDER BY Sales DESC; 

-- Sales Analysis by Time of Day  
SELECT  
    timeofday,  
    COUNT(`Invoice id`) AS Sales  
FROM amazon  
GROUP BY timeofday  
ORDER BY FIELD(timeofday, 'Morning', 'Afternoon', 'Evening', 'Night');

-- Sales Analysis --best-performing day of the week for each branch based on sales

WITH SalesDays AS (  
    SELECT  
        branch,  
        dayname,  
        COUNT(`Invoice ID`) AS Sales  
    FROM amazon  
    GROUP BY branch, dayname  
),  

MaxSales AS (  
    SELECT  
        branch,  
        MAX(Sales) AS MaxSales  
    FROM SalesDays  
    GROUP BY branch  
)  

SELECT  
    sd.branch,  
    sd.dayname,  
    sd.Sales  
FROM SalesDays sd  
JOIN MaxSales ms  
ON ms.branch = sd.branch AND ms.MaxSales = sd.Sales  
ORDER BY sd.branch;  

-- City Contribution to Total Revenue  
SELECT  
    City,  
    ROUND(SUM(Total), 2) AS Revenue  
FROM amazon  
GROUP BY City  
ORDER BY Revenue DESC;


-- 3 Customer analysis
-- Most Frequent Customer Type  
SELECT  
    `Customer Type`,  
    COUNT(`Customer Type`) AS Count  
FROM amazon  
GROUP BY `Customer Type`  
ORDER BY Count DESC;

-- Customer Type Revenue Contribution  
SELECT  
    `Customer Type`,  
    ROUND(SUM(Total), 2) AS Revenue  
FROM amazon  
GROUP BY `Customer Type`  
ORDER BY Revenue DESC;

		-- Business_Questions_to_Answer
        
# 1) What is the count of distinct cities in the dataset?
SELECT COUNT(DISTINCT city) AS Total_Cities  
FROM amazon;

# 2) For each branch, what is the corresponding city?
SELECT Branch, City  
FROM amazon  
GROUP BY Branch, City;

# 3) What is the count of distinct product lines in the dataset?
SELECT COUNT(DISTINCT `Product line`) as Total_Product_lines 
FROM amazon;

# 4) Which payment method occurs most frequently?
SELECT Payment, COUNT(Payment) AS Total_Payments  
FROM amazon  
GROUP BY Payment  
ORDER BY Total_Payments DESC  
LIMIT 1;

# 5) Which product line has the highest sales?
SELECT `Product line`, COUNT(`Invoice Id`) AS Sales  
FROM amazon  
GROUP BY `Product line`  
ORDER BY Sales DESC  
LIMIT 1;

# 6) How much revenue is generated each month?
-- Revenue Generated Each Month  
SELECT DATE_FORMAT(date, '%b') AS Month,  
       ROUND(SUM(total), 2) AS Total_Revenue  
FROM amazon  
GROUP BY Month;

# 7) In which month did the cost of goods sold reach its peak?
-- Month with Highest COGS  
SELECT DATE_FORMAT(date, '%b') AS Month,  
       ROUND(SUM(cogs), 2) AS Total_COGS  
FROM amazon  
GROUP BY Month  
ORDER BY Total_COGS DESC  
LIMIT 1;

#  8) Which product line generated the highest revenue?
SELECT `Product line`,  
       ROUND(SUM(total), 2) AS Total_Revenue  
FROM amazon  
GROUP BY `Product line`  
ORDER BY Total_Revenue DESC  
LIMIT 1;

# 9) In which city was the highest revenue recorded?
SELECT city,  
       ROUND(SUM(total), 2) AS Total_Revenue  
FROM amazon  
GROUP BY city  
ORDER BY Total_Revenue DESC  
LIMIT 1;

# 10) Which product line incurred the highest Value Added Tax?
SELECT `Product line`,  
       MAX(`Tax 5%`) AS Highest_VAT  
FROM amazon  
GROUP BY `Product line`  
ORDER BY Highest_VAT DESC  
LIMIT 1;

# 11) For each product line, add a column indicating "Good" if its sales are above average, otherwise "Bad."
-- sALES ANALYSIS DAY OF WEEK
WITH SalesCount AS (
    SELECT `Product line`, COUNT(`Invoice ID`) AS Sales
    FROM amazon
    GROUP BY `Product line`
),
AverageSales AS (
    SELECT AVG(Sales) AS Average_Sales FROM SalesCount
)
SELECT sc.`Product line`, sc.Sales, avs.Average_Sales,
       CASE 
           WHEN sc.Sales > avs.Average_Sales THEN 'Good'
           ELSE 'Bad'
       END AS Performance
FROM SalesCount sc
CROSS JOIN AverageSales avs;
 

# 12) Identify the branch that exceeded the average number of products sold.
WITH ProductsCount AS (
    SELECT branch, SUM(`Quantity`) AS Sales
    FROM amazon
    GROUP BY branch
),
AverageProductsSold AS (
    SELECT AVG(Sales) AS Average_Products_Sold FROM ProductsCount
)
SELECT pc.branch, pc.Sales, aps.Average_Products_Sold
FROM ProductsCount pc
CROSS JOIN AverageProductsSold aps
WHERE pc.Sales > aps.Average_Products_Sold;


# 13) Which product line is most frequently associated with each gender?
with ProductLineCounts AS (
    SELECT Gender,`Product line`, COUNT(*) AS Count
    FROM amazon
    GROUP BY Gender, `Product line`
),
MaxCounts AS (
    SELECT Gender, MAX(Count) AS MaxCount
    FROM ProductLineCounts
    GROUP BY Gender
)
SELECT plc.Gender, plc.`Product line`, plc.Count
FROM ProductLineCounts plc
JOIN MaxCounts mc
ON plc.Gender = mc.Gender AND plc.Count = mc.MaxCount;

# 14) Calculate the average rating for each product line.
SELECT `Product line`, ROUND(AVG(`Rating`),2) AS Avg_Rating
FROM amazon
GROUP BY `Product line`;

# 15) Count the sales occurrences for each time of day on every weekday.
SELECT dayname, timeofday, COUNT(*) AS SalesCount  
FROM amazon  
WHERE dayname NOT IN ('Sat', 'Sun')  
GROUP BY dayname, timeofday  
ORDER BY FIELD(dayname, 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'),  
         FIELD(timeofday, 'Morning', 'Afternoon', 'Evening');  

# 16) Identify the customer type contributing the highest revenue.
SELECT `Customer type`, SUM(Total) AS Total_Revenue  
FROM amazon  
GROUP BY `Customer type`  
ORDER BY Total_Revenue DESC  
LIMIT 1;

# 17) Determine the city with the highest VAT percentage.
SELECT City, ROUND(SUM(`Tax 5%`),2) AS Total_VAT  
FROM amazon  
GROUP BY City  
ORDER BY Total_VAT DESC  
LIMIT 1;

# 18) Identify the customer type with the highest VAT payments.
SELECT `Customer type`, ROUND(SUM(`Tax 5%`), 2) AS Total_VAT  
FROM amazon  
GROUP BY `Customer type`  
ORDER BY Total_VAT DESC  
LIMIT 1;

# 19) What is the count of distinct customer types in the dataset?
SELECT  COUNT(distinct `Customer type`) AS Total_Customer_types  
FROM amazon;

# 20) What is the count of distinct payment methods in the dataset?
SELECT COUNT(DISTINCT Payment) AS Total_Payment_Methods 
FROM amazon;

# 21) Which customer type occurs most frequently?
SELECT `Customer Type`, COUNT(`Customer Type`) AS Count  
FROM amazon  
GROUP BY `Customer Type`  
ORDER BY Count DESC LIMIT 1;

# 22) Identify the customer type with the highest purchase frequency.
SELECT `Customer Type`, COUNT(`Invoice ID`) AS Count  
FROM amazon  
GROUP BY `Customer Type`  
ORDER BY Count DESC  
LIMIT 1;

# 23) Determine the predominant gender among customers.
SELECT Gender, COUNT(Gender) AS Count  
FROM amazon  
GROUP BY Gender  
ORDER BY Count DESC  
LIMIT 1;

# 24) Examine the distribution of genders within each branch.
SELECT Branch, Gender, COUNT(Gender) AS Count  
FROM amazon  
GROUP BY Branch, Gender  
ORDER BY Branch;

# 25)Identify the time of day when customers provide the most ratings.
SELECT timeofday, COUNT(rating) AS Total_Ratings  
FROM amazon  
GROUP BY timeofday  
ORDER BY Total_Ratings DESC;

# 26) Determine the time of day with the highest customer ratings for each branch.
WITH Ratings AS (  
    SELECT branch, timeofday, ROUND(AVG(rating), 2) AS Average_Ratings  
    FROM amazon  
    GROUP BY branch, timeofday  
    ORDER BY branch  
),  
MaxRatings AS (  
    SELECT branch, MAX(Average_Ratings) AS maxratings  
    FROM Ratings  
    GROUP BY branch  
)  
SELECT r.branch, r.timeofday, r.Average_Ratings  
FROM Ratings r  
JOIN MaxRatings mr  
ON mr.branch = r.branch AND r.Average_Ratings = mr.maxratings;


# 27) Identify the day of the week with the highest average ratings.
SELECT dayname, ROUND(AVG(rating), 2) AS Average_Ratings  
FROM amazon  
GROUP BY dayname  
ORDER BY Average_Ratings DESC  
LIMIT 1;


# 28) Determine the day of the week with the highest average ratings for each branch.
WITH AverageRatings AS (  
    SELECT dayname, BRANCH, ROUND(AVG(rating), 2) AS Average_Ratings  
    FROM amazon  
    GROUP BY BRANCH, dayname  
    ORDER BY branch,  
    FIELD(dayname, 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat')  
),  
MaxRatings AS (  
    SELECT BRANCH, MAX(Average_Ratings) AS Max_Ratings  
    FROM AverageRatings  
    GROUP BY BRANCH  
)  
SELECT ac.dayname, ac.BRANCH, ac.Average_Ratings  
FROM AverageRatings ac  
JOIN MaxRatings mc  
ON mc.Max_Ratings = ac.Average_Ratings  
AND mc.branch = ac.branch;