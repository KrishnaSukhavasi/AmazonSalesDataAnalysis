CREATE DATABASE sql_capstone_project;
SELECT * FROM sql_capstone_project.amazon;
USE sql_capstone_project;

SET SQL_SAFE_UPDATES = 0;

-- adding timeofday column
ALTER TABLE amazon ADD COLUMN timeofday VARCHAR(20);
UPDATE amazon
SET timeofday = CASE
    WHEN HOUR(time) >=6 AND HOUR(time) < 12 THEN 'Morning'
    WHEN HOUR(time) >=12 AND HOUR(time) < 18 THEN 'Afternoon'
    WHEN HOUR(time) >=18 AND HOUR(time) < 24 THEN 'Evening'
    ELSE 'Night'
    END;
    
# Adding DAYNAME column
ALTER TABLE amazon ADD COLUMN dayname VARCHAR(20);
UPDATE amazon
SET dayname = DATE_FORMAT(date, '%a');    

# Adding MONTHNAME column
ALTER TABLE amazon ADD COLUMN monthname VARCHAR(20);
UPDATE amazon
SET monthname = DATE_FORMAT(date, '%b');

-- 1 Product analysis
-- Conduct analysis on the data to understand the different product lines, 
   --  the products lines performing best and the product lines that need to be improved.
SELECT `Product line`,ROUND(sum(total),2) as Total_Revenue,
(SELECT ROUND(SUM(`total`)/COUNT(DISTINCT `Product line`),2) from amazon) AS Average_Revenue,
RANK() OVER(ORDER BY ROUND(sum(total),2) DESC) AS Revenue_Rank FROM amazon group by `Product line` 
ORDER BY Total_Revenue DESC;

-- Product line-Comparision of  Sales
SELECT `Product line`,count(`Invoice id`) as Sales,
(SELECT ROUND(COUNT(`Invoice id`)/COUNT(DISTINCT `Product line`),0)  FROM amazon) as Average_Sales FROM amazon 
group by `Product line` ORDER BY Sales DESC;


-- 2 Sales analysis
-- Sales by Month
 SELECT DATE_FORMAT(date, '%b') as Month,COUNT(`Invoice id`) AS Sales FROM amazon GROUP BY Month;

-- Branch Performance in Sales
SELECT Branch,count(`Invoice id`) as Sales FROM amazon group by Branch;

-- Sales-Timeofday
SELECT timeofday,count(`Invoice id`) as Sales FROM amazon group by timeofday;

-- Sales-Dayofweek
with SalesDays as (SELECT branch,dayname,COUNT(`Invoice ID`) AS Sales FROM amazon GROUP BY branch,dayname ORDER BY BRANCH),
MaxSales as (SELECT branch,MAX(Sales) AS MaxSales FROM SalesDays GROUP BY branch)
SELECT sd.branch,sd.dayname,Sales FROM SalesDays sd JOIN MaxSales ms ON ms.branch=sd.branch AND ms.MaxSales=sd.Sales;

-- City contribution
SELECT City,Round(SUM(Total),2) as Revenue FROM amazon group by City ORDER BY Revenue DESC;

-- 3 Customer analysis
 -- customer type occurs most frequently
SELECT `Customer Type`,COUNT(`Customer Type`) AS Count FROM amazon GROUP BY `Customer Type` ORDER BY Count DESC;

  -- customer type contributing the highest revenue
SELECT `Customer Type`,ROUND(SUM(Total),2) AS Count FROM amazon GROUP BY `Customer Type` ORDER BY Count DESC;

-- Business_Questions_to_Answer
# 1) What is the count of distinct cities in the dataset?
SELECT COUNT(DISTINCT city) AS Total_Cities from amazon;

# 2) For each branch, what is the corresponding city?
SELECT Branch,city from amazon GROUP BY Branch,city;

# 3) What is the count of distinct product lines in the dataset?
SELECT COUNT(DISTINCT `Product line`) as Total_Product_lines from amazon;

# 4) Which payment method occurs most frequently?
SELECT Payment, COUNT(Payment) AS Total_Payments FROM amazon GROUP BY Payment ORDER BY Total_Payments DESC LIMIT 1;

# 5) Which product line has the highest sales?
SELECT `Product line`,Count(`Invoice Id`) AS Sales FROM amazon GROUP BY `Product line` ORDER BY Sales DESC LIMIT 1;

# 6) How much revenue is generated each month?
SELECT DATE_FORMAT(date, '%b') as Month,SUM(total) AS Total_Revenue FROM amazon GROUP BY Month;

# 7) In which month did the cost of goods sold reach its peak?
SELECT DATE_FORMAT(date, '%b') as Month,ROUND(SUM(cogs),2) AS Total_cogs FROM amazon GROUP BY Month ORDER BY Total_cogs DESC LIMIT 1;

# 8) Which product line generated the highest revenue?
SELECT `Product line`,ROUND(sum(total),2) as Total_Revenue FROM amazon group by `Product line` ORDER BY Total_Revenue DESC LIMIT 1;

# 9) In which city was the highest revenue recorded?
SELECT city,ROUND(sum(total),2) as Total_Revenue FROM amazon group by city ORDER BY Total_Revenue DESC LIMIT 1;

# 10) Which product line incurred the highest Value Added Tax?
SELECT `Product line`,max(`Tax 5%`) as Highest_Vat FROM amazon group by `Product line` ORDER BY Highest_Vat DESC LIMIT 1;

# 11) For each product line, add a column indicating "Good" if its sales are above average, otherwise "Bad."
with SalesCount as (SELECT `Product line`,COUNT(`Invoice ID`) AS Sales FROM amazon GROUP BY `Product line`),
AverageSales as (SELECT `Product line`,AVG(Sales) OVER () AS Average_Sales FROM SalesCount)
SELECT sc.`Product line`,sc.Sales, avs.Average_Sales,
CASE 
 WHEN Sales>Average_Sales THEN 'Good'
 ELSE 'Bad'
 END AS Performance
 FROM SalesCount sc JOIN AverageSales avs ON sc.`Product line`=avs.`Product line`;

# 12) Identify the branch that exceeded the average number of products sold.
with ProductsCount as (SELECT branch,SUM(`Quantity`) AS Sales FROM amazon GROUP BY branch),
AverageProductsSold as (SELECT branch,AVG(Sales) OVER () AS Average_Products_Sold FROM ProductsCount)
SELECT pc.branch,pc.Sales, aps.Average_Products_Sold
FROM ProductsCount pc JOIN AverageProductsSold aps ON pc.branch=aps.branch WHERE sales>Average_Products_Sold;

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
SELECT `Product line`,ROUND(AVG(`Rating`),2) as Avg_Rating FROM amazon group by `Product line`;

# 15) Count the sales occurrences for each time of day on every weekday.
select dayname,timeofday,count(*) as SalesCount from amazon where dayname not in ('Sat','Sun')group by dayname,timeofday 
ORDER BY FIELD(dayname, 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'), FIELD(timeofday,'Morning','Afternoon','Evening');

# 16) Identify the customer type contributing the highest revenue.
SELECT `Customer type`,SUM(Total) as Total_Revenue FROM amazon group by `Customer type` LIMIT 1;

# 17) Determine the city with the highest VAT percentage.
SELECT City,MAX(`Tax 5%`) as VAT FROM amazon group by City ORDER BY VAT DESC LIMIT 1;

# 18) Identify the customer type with the highest VAT payments.
SELECT `Customer type`,MAX(`Tax 5%`) as VAT FROM amazon group by `Customer type` ORDER BY VAT DESC  LIMIT 1;

# 19) What is the count of distinct customer types in the dataset?
SELECT COUNT(DISTINCT `Customer type`) AS Total_Customer_Types FROM amazon;

# 20) What is the count of distinct payment methods in the dataset?
SELECT COUNT(DISTINCT Payment) AS Total_Payment_Methods FROM amazon;

# 21) Which customer type occurs most frequently?
SELECT `Customer Type`,COUNT(`Customer Type`) AS Count FROM amazon GROUP BY `Customer Type` ORDER BY Count DESC LIMIT 1;

# 22) Identify the customer type with the highest purchase frequency.
SELECT `Customer Type`,COUNT(`Invoice id`) AS Count FROM amazon GROUP BY `Customer Type` ORDER BY Count DESC LIMIT 1;

# 23) Determine the predominant gender among customers.
SELECT Gender,COUNT(Gender) AS Count FROM amazon GROUP BY Gender ORDER BY Count DESC LIMIT 1;

# 24) Examine the distribution of genders within each branch.
SELECT Branch,Gender,COUNT(Gender) AS Count FROM amazon GROUP BY Branch,Gender ORDER BY BRANCH;

# 25)Identify the time of day when customers provide the most ratings.
SELECT timeofday,COUNT(rating) AS Total_Ratings FROM amazon GROUP BY timeofday ORDER BY ratings DESC LIMIT 1;

# 26) Determine the time of day with the highest customer ratings for each branch.
with Ratings as (SELECT branch,timeofday,ROUND(avg(rating),2) AS Average_Ratings FROM amazon GROUP BY branch,timeofday order by branch),
MaxRatings as (SELECT branch,max(Average_Ratings) AS maxratings FROM Ratings GROUP BY branch)
select r.branch,r.timeofday,r.Average_Ratings from Ratings r join MaxRatings mr on mr.branch=r.branch and r.Average_Ratings=mr.maxratings;

# 27) Identify the day of the week with the highest average ratings.
SELECT dayname,ROUND(avg(rating),2) AS Average_Ratings FROM amazon GROUP BY dayname ORDER BY Average_Ratings DESC LIMIT 1;

# 28) Determine the day of the week with the highest average ratings for each branch.
with AverageCounts as (SELECT dayname,BRANCH,ROUND(avg(rating),2) AS Average_Ratings FROM amazon GROUP BY BRANCH,dayname ORDER BY branch,
field(dayname,'Sun','Mon','Tue','Wed','Thu','Fri','Sat'))
,MaxCounts as (SELECT BRANCH,MAX(Average_Ratings) AS Max_Ratings FROM AverageCounts GROUP BY BRANCH ORDER BY branch)
SELECT ac.dayname,ac.BRANCH,Average_Ratings FROM AverageCounts ac JOIN MaxCounts mc ON mc.Max_Ratings = ac.Average_Ratings AND mc.branch=ac.branch;