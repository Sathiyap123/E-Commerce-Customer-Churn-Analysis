--                                E-Commerce Customer Churn Analysis
-- Data Cleaning Queries
-- Impute Mean (Rounded to Nearest Integer):

-- Impute mean for numeric columns with rounding
UPDATE your_table_name
SET WarehouseToHome = ROUND((SELECT AVG(WarehouseToHome) FROM your_table_name WHERE WarehouseToHome IS NOT NULL))
WHERE WarehouseToHome IS NULL;

UPDATE your_table_name
SET HourSpendOnApp = ROUND((SELECT AVG(HourSpendOnApp) FROM your_table_name WHERE HourSpendOnApp IS NOT NULL))
WHERE HourSpendOnApp IS NULL;

UPDATE your_table_name
SET OrderAmountHikeFromLastYear = ROUND((SELECT AVG(OrderAmountHikeFromLastYear) FROM your_table_name WHERE OrderAmountHikeFromLastYear IS NOT NULL))
WHERE OrderAmountHikeFromLastYear IS NULL;

UPDATE your_table_name
SET DaySinceLastOrder = ROUND((SELECT AVG(DaySinceLastOrder) FROM your_table_name WHERE DaySinceLastOrder IS NOT NULL))
WHERE DaySinceLastOrder IS NULL;
-- Impute Mode for Categorical Columns:

-- Impute mode for Tenure, CouponUsed, and OrderCount
UPDATE your_table_name
SET Tenure = (SELECT Tenure FROM your_table_name GROUP BY Tenure ORDER BY COUNT(*) DESC LIMIT 1)
WHERE Tenure IS NULL;

UPDATE your_table_name
SET CouponUsed = (SELECT CouponUsed FROM your_table_name GROUP BY CouponUsed ORDER BY COUNT(*) DESC LIMIT 1)
WHERE CouponUsed IS NULL;

UPDATE your_table_name
SET OrderCount = (SELECT OrderCount FROM your_table_name GROUP BY OrderCount ORDER BY COUNT(*) DESC LIMIT 1)
WHERE OrderCount IS NULL;
-- Remove Outliers:

-- Delete rows with outliers in WarehouseToHome
DELETE FROM your_table_name
WHERE WarehouseToHome > 100;
-- Fix Inconsistencies:

-- Replace inconsistent values
UPDATE your_table_name
SET PreferredLoginDevice = 'Mobile Phone'
WHERE PreferredLoginDevice IN ('Phone', 'Mobile');

UPDATE your_table_name
SET PreferredPaymentMode = CASE 
    WHEN PreferredPaymentMode = 'COD' THEN 'Cash on Delivery'
    WHEN PreferredPaymentMode = 'CC' THEN 'Credit Card'
    ELSE PreferredPaymentMode
END;
-- Data Transformation Queries
-- Rename Columns:

-- Rename columns
ALTER TABLE your_table_name RENAME COLUMN PreferedOrderCat TO PreferredOrderCat;
ALTER TABLE your_table_name RENAME COLUMN HourSpendOnApp TO HoursSpentOnApp;
-- Create New Columns:

-- Add new columns
-- ALTER TABLE your_table_name ADD ComplaintReceived VARCHAR(3), VARCHAR(10);

-- Populate ComplaintReceived and ChurnStatus
UPDATE your_table_name
SET ComplaintReceived = CASE WHEN Complain = 1 THEN 'Yes' ELSE 'No' END;

UPDATE your_table_name
SET ChurnStatus = CASE WHEN Churn = 1 THEN 'Churned' ELSE 'Active' END;
-- Drop Unnecessary Columns:

-- Drop columns Churn and Complain
ALTER TABLE your_table_name DROP COLUMN Churn, DROP COLUMN Complain;
-- Data Exploration and Analysis Queries
-- Count Churned and Active Customers:

SELECT ChurnStatus, COUNT(*) AS CustomerCount
FROM your_table_name
GROUP BY ChurnStatus;
-- Average Tenure of Churned Customers:

SELECT AVG(Tenure) AS AverageTenure
FROM your_table_name
WHERE ChurnStatus = 'Churned';
-- Total Cashback for Churned Customers:

SELECT SUM(CashbackAmount) AS TotalCashback
FROM your_table_name
WHERE ChurnStatus = 'Churned';
-- Percentage of Churned Customers Who Complained:

SELECT 
    (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM your_table_name WHERE ChurnStatus = 'Churned')) AS PercentageComplained
FROM your_table_name
WHERE ChurnStatus = 'Churned' AND ComplaintReceived = 'Yes';
-- Gender Distribution of Customers Who Complained:

SELECT Gender, COUNT(*) AS ComplaintCount
FROM your_table_name
WHERE ComplaintReceived = 'Yes'
GROUP BY Gender;
-- City Tier with Most Churned Customers (Laptop & Accessory):

SELECT CityTier, COUNT(*) AS ChurnCount
FROM your_table_name
WHERE ChurnStatus = 'Churned' AND PreferredOrderCat = 'Laptop & Accessory'
GROUP BY CityTier
ORDER BY ChurnCount DESC
LIMIT 1;
-- Most Preferred Payment Mode (Active Customers):

SELECT PreferredPaymentMode, COUNT(*) AS PaymentModeCount
FROM your_table_name
WHERE ChurnStatus = 'Active'
GROUP BY PreferredPaymentMode
ORDER BY PaymentModeCount DESC
LIMIT 1;
-- Customers Taking >10 Days Since Last Order (Preferred Device):

SELECT PreferredLoginDevice, COUNT(*) AS DeviceCount
FROM your_table_name
WHERE DaySinceLastOrder > 10
GROUP BY PreferredLoginDevice
ORDER BY DeviceCount DESC;
-- Active Customers Spending >3 Hours on App:

SELECT COUNT(*) AS ActiveCustomerCount
FROM your_table_name
WHERE ChurnStatus = 'Active' AND HoursSpentOnApp > 3;
-- Customer Returns Queries
-- Create Customer Returns Table and Insert Data:

-- Create table
CREATE TABLE customer_returns (
    ReturnID INT,
    CustomerID INT,
    ReturnDate DATE,
    RefundAmount DECIMAL(10, 2)
);

-- Insert data
INSERT INTO customer_returns (ReturnID, CustomerID, ReturnDate, RefundAmount)
VALUES
(1001, 50022, '2023-01-01', 2130),
(1002, 50316, '2023-01-23', 2000),
(1003, 51099, '2023-02-14', 2290),
(1004, 52321, '2023-03-08', 2510),
(1005, 52928, '2023-03-20', 3000),
(1006, 53749, '2023-04-17', 1740),
(1007, 54206, '2023-04-21', 3250),
(1008, 54838, '2023-04-30', 1990);
-- Return Details for Churned Customers with Complaints:

SELECT r.ReturnID, r.RefundAmount, c.*
FROM customer_returns r
JOIN your_table_name c ON r.CustomerID = c.CustomerID
WHERE c.ChurnStatus = 'Churned' AND c.ComplaintReceived = 'Yes';


         
         -- Additional Data Cleaning and Preprocessing Ideas




-- Impute missing Gender values (e.g., use 'Unknown' as a placeholder)
UPDATE your_table_name
SET Gender = 'Unknown'
WHERE Gender IS NULL;
-- Handling Duplicate Entries: It is important to check and remove duplicates to ensure data integrity.

-- Remove duplicate customer entries based on CustomerID
DELETE FROM your_table_name
WHERE CustomerID IN (
    SELECT CustomerID
    FROM your_table_name
    GROUP BY CustomerID
    HAVING COUNT(*) > 1
) AND RowID NOT IN (
    SELECT MIN(RowID)
    FROM your_table_name
    GROUP BY CustomerID
);
-- Advanced Data Exploration Queries

-- Calculate monthly churn rate
SELECT YEAR(OrderDate) AS Year, MONTH(OrderDate) AS Month, 
       COUNT(CASE WHEN ChurnStatus = 'Churned' THEN 1 END) / COUNT(*) AS ChurnRate
FROM your_table_name
GROUP BY YEAR(OrderDate), MONTH(OrderDate);

-- Find the last order date for churned customers
SELECT CustomerID, MAX(OrderDate) AS LastOrderDate
FROM your_table_name
WHERE ChurnStatus = 'Churned'
GROUP BY CustomerID;

-- Segment customers based on total spend and frequency of orders
SELECT CustomerID, 
       SUM(OrderAmount) AS TotalSpend,
       COUNT(OrderID) AS OrderFrequency,
       CASE 
           WHEN SUM(OrderAmount) > 500 THEN 'High Spender'
           WHEN SUM(OrderAmount) > 100 THEN 'Medium Spender'
           ELSE 'Low Spender'
       END AS SpendCategory,
       CASE 
           WHEN COUNT(OrderID) > 10 THEN 'Frequent'
           ELSE 'Infrequent'
       END AS OrderFrequencyCategory
FROM your_table_name
GROUP BY CustomerID;


-- Churn rate by product category
SELECT PreferredOrderCat, 
       COUNT(CASE WHEN ChurnStatus = 'Churned' THEN 1 END) / COUNT(*) AS ChurnRate
FROM your_table_name
GROUP BY PreferredOrderCat;

-- Estimate Customer Lifetime Value (CLV) based on average order value and purchase frequency
SELECT CustomerID, 
       AVG(OrderAmount) * COUNT(OrderID) AS EstimatedCLV
FROM your_table_name
GROUP BY CustomerID;
-- Retention and Engagement Queries

-- Calculate retention rate of customers who used coupons
SELECT CouponUsed, 
       COUNT(CASE WHEN ChurnStatus = 'Churned' THEN 1 END) / COUNT(*) AS RetentionRate
FROM your_table_name
GROUP BY CouponUsed;

-- Find the average satisfaction score of churned vs active customers
SELECT ChurnStatus, AVG(SatisfactionScore) AS AvgSatisfaction
FROM your_table_name
GROUP BY ChurnStatus;

-- Find products frequently purchased together (assumes you have a 'Product' column)
SELECT Product, COUNT(*) AS PurchaseCount
FROM your_table_name
GROUP BY Product
HAVING PurchaseCount > 50;
-- Predictive Analytics and Modeling Ideas

-- Prepare data for churn prediction (this would be part of a larger data science pipeline)
SELECT CustomerID, 
       SatisfactionScore, 
       FrequencyOfOrders, 
       AvgSpendPerOrder, 
       ChurnStatus
FROM your_table_name;

-- Calculate retention for customers based on their cohort (e.g., based on the first order month)
SELECT YEAR(MIN(OrderDate)) AS CohortYear, 
       MONTH(MIN(OrderDate)) AS CohortMonth, 
       COUNT(DISTINCT CustomerID) AS TotalCustomers,
       COUNT(DISTINCT CASE WHEN ChurnStatus = 'Churned' THEN CustomerID END) AS ChurnedCustomers
FROM your_table_name
GROUP BY YEAR(MIN(OrderDate)), MONTH(MIN(OrderDate));

-- Reporting and Dashboard Queries


-- Summary report for churn analysis
SELECT 
    COUNT(CASE WHEN ChurnStatus = 'Churned' THEN 1 END) AS TotalChurned,
    COUNT(CASE WHEN ChurnStatus = 'Active' THEN 1 END) AS TotalActive,
    AVG(SatisfactionScore) AS AvgSatisfaction,
    AVG(OrderAmountHikeFromLastYear) AS AvgOrderAmountHike
FROM your_table_name;
-- Churn Heatmap: Create a heatmap of churn rates by city, product category, and payment mode.

-- Churn rate by city tier and preferred order category
SELECT CityTier, PreferredOrderCat, 
       COUNT(CASE WHEN ChurnStatus = 'Churned' THEN 1 END) / COUNT(*) AS ChurnRate
FROM your_table_name
GROUP BY CityTier, PreferredOrderCat;

