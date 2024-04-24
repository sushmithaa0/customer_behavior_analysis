SELECT * 
FROM Customer_Data 

----------------------------------------------DATA CLEANING------------------------------------------------
--To know the data type of each column

SELECT 
TABLE_CATALOG,
TABLE_SCHEMA,
TABLE_NAME, 
COLUMN_NAME, 
DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Customer_Data' 

--Altering data type of columns and droping redundent columns

ALTER TABLE Customer_Data ALTER COLUMN purchase_date date

ALTER TABLE Customer_Data
	DROP COLUMN Total_Purchase_Amount, Customer_Age

ALTER TABLE Customer_Data
ADD Total_Purchase_Amount int;

--To find accurate value of total purchase amount

UPDATE Customer_Data
SET Total_Purchase_Amount = Product_Price * Quantity

--Clearing null values in the return column

SELECT  Product_Category,Customer_Name,Returns
FROM Customer_Data
WHERE Returns is null


SELECT returns, 
COUNT(*) as total_null_count
FROM Customer_Data
WHERE Returns IS NULL
GROUP BY Returns


UPDATE Customer_Data
SET Returns =
	CASE 
		when Returns is null then 0
		else Returns
	END;

SElECT * 
FROM Customer_Data
ORDER BY Purchase_Date

----------------------------------------------DATA ANALYSIS------------------------------------------------

SELECT Total_Purchase_Amount,Purchase_Date,Customer_ID,Customer_Name
FROM Customer_Data

--revenue by year

SELECT '2020' AS YEAR,
       SUM(CASE WHEN YEAR(Purchase_Date) = 2020 THEN Total_Purchase_Amount ELSE 0 END) AS revenue
FROM customer_data
WHERE YEAR(Purchase_Date) = 2020

UNION ALL

SELECT '2021' AS YEAR,
       SUM(CASE WHEN YEAR(Purchase_Date) = 2021 THEN Total_Purchase_Amount ELSE 0 END) AS revenue
FROM customer_data
WHERE YEAR(Purchase_Date) = 2021

UNION ALL

SELECT '2022' AS YEAR,
       SUM(CASE WHEN YEAR(Purchase_Date) = 2022 THEN Total_Purchase_Amount ELSE 0 END) AS revenue
FROM customer_data
WHERE YEAR(Purchase_Date) = 2022

UNION ALL

SELECT '2023' AS YEAR,
       SUM(CASE WHEN YEAR(Purchase_Date) = 2023 THEN Total_Purchase_Amount ELSE 0 END) AS revenue
FROM customer_data
WHERE YEAR(Purchase_Date) = 2023;

--total amount spent by each customer

SELECT Customer_ID,Customer_Name,
       SUM(Total_Purchase_Amount) AS spent
FROM Customer_Data
GROUP BY Customer_ID,Customer_Name;

--purchase frequency

SELECT  COUNT(Purchase_Date) / COUNT(DISTINCT Customer_ID)   AS purchse_frequency
FROM Customer_Data;

--purchase frequncy by gender

SELECT  COUNT(Purchase_Date) / COUNT(DISTINCT Customer_ID) AS purchse_frequency,Gender
FROM Customer_Data
GROUP BY Gender

--purchase frequency of each customer

SELECT Customer_ID, Customer_Name,Age,Gender,
       COUNT(*) AS purchase_frequency
FROM Customer_Data
GROUP BY Customer_ID,Customer_Name,Age,Gender
ORDER BY purchase_frequency DESC;

--pecentage frequent customers

WITH Total_Customers AS (
    SELECT 
        COUNT(DISTINCT Customer_ID) AS total_customers
    FROM 
        Customer_Data
),
Frequent_Customers AS (
    SELECT 
        COUNT(*) AS frequent_customers
    FROM 
        (
        SELECT 
            Customer_ID
        FROM 
            Customer_Data
        GROUP BY 
            Customer_ID
        HAVING 
            COUNT(*) > 3
        ) AS subquery
)
SELECT 
    (frequent_customers * 100.0 / total_customers) AS percent_frequent_customers
FROM 
    Total_Customers, Frequent_Customers;


--average order value

SELECT AVG(Total_Purchase_Amount)
FROM Customer_Data

--customer retention BY YEAR

SELECT YEAR(Purchase_Date) AS purchase_year,
       COUNT(DISTINCT CASE WHEN YEAR(Purchase_Date) = 2020 THEN Customer_ID END) AS customer_count_2020,
       COUNT(DISTINCT CASE WHEN YEAR(Purchase_Date) = 2021 THEN Customer_ID END) AS customer_count_2021,
       COUNT(DISTINCT CASE WHEN YEAR(Purchase_Date) = 2022 THEN Customer_ID END) AS customer_count_2022,
       COUNT(DISTINCT CASE WHEN YEAR(Purchase_Date) = 2023 THEN Customer_ID END) AS customer_count_2023
FROM Customer_Data
WHERE YEAR(Purchase_Date) BETWEEN 2020 AND 2023
GROUP BY YEAR(Purchase_Date);


--prefered payment method by age group

WITH group_by_age AS(
SELECT 
    CASE 
        WHEN Age BETWEEN 18 AND 24 THEN '18-24'
        WHEN Age BETWEEN 25 AND 34 THEN '25-34'
        WHEN Age BETWEEN 35 AND 44 THEN '35-44'
        WHEN Age BETWEEN 45 AND 54 THEN '45-54'
        ELSE '55+'
    END AS age_group,
    Payment_Method
FROM 
    Customer_Data
)
SELECT 
	age_group,
	Payment_Method,
	COUNT(*) AS method_count
FROM 
	group_by_age
GROUP BY 
    age_group, Payment_Method
ORDER BY 
     method_count DESC;

--popular product catogory

WITH product_rank AS (
    SELECT Product_Category,
           COUNT(*) AS total_purchased,
           RANK() OVER (ORDER BY COUNT(*) DESC) AS category_rank
    FROM Customer_Data
    GROUP BY Product_Category
)
SELECT Product_Category, total_purchased, category_rank
FROM product_rank
WHERE category_rank <= 4;

--popular product catogory by age and gender group
WITH popular AS (
    SELECT CASE 
               WHEN Age BETWEEN 18 AND 24 THEN '18-24'
               WHEN Age BETWEEN 25 AND 34 THEN '25-34'
               WHEN Age BETWEEN 35 AND 44 THEN '35-44'
               WHEN Age BETWEEN 45 AND 54 THEN '45-54'
               ELSE '55+'
           END AS age_group,
		   Gender,
           Product_Category
    FROM Customer_Data
)
SELECT age_group,
	   Gender,
       Product_Category,
       COUNT(*) AS category_count
FROM popular
GROUP BY age_group,Gender, product_category
ORDER BY Gender, category_count DESC;

--purchase frequency and churn

WITH customer_purchase_frequency AS (
    SELECT
        Customer_ID,
        COUNT(*) AS total_purchases,
        DATEDIFF(MONTH, MIN(Purchase_Date), MAX(Purchase_Date)) AS purchase_span, 
        CASE
            WHEN COUNT(*) > 1 THEN DATEDIFF(MONTH, MIN(Purchase_Date), MAX(Purchase_Date)) / (COUNT(*) - 1) 
            ELSE 0 
        END AS purchase_frequency
    FROM
        Customer_Data
    GROUP BY
        Customer_ID
)
SELECT
    cpf.Customer_ID,
    cpf.total_purchases,
    cpf.purchase_span,
    cpf.purchase_frequency,
    c.churn
FROM
    customer_purchase_frequency cpf
LEFT JOIN
    Customer_Data c ON cpf.Customer_ID = c.Customer_ID
ORDER BY c.Churn DESC;

--churn percentage

SELECT COUNT(CASE WHEN Churn = 1 THEN Churn END) * 100 / COUNT(Churn) AS churn_percentage
FROM Customer_Data

--churned customer's purchased product catogory

SELECT Product_Category,COUNT(CASE WHEN Churn = 1 THEN Product_Category END)
FROM Customer_Data
GROUP BY Product_Category

--return percentage

SELECT COUNT(CASE WHEN Returns = 1 THEN Returns END) * 100 / COUNT(Returns) AS returns_percentage
FROM Customer_Data

--Return count by product catogory 

SELECT Product_Category,COUNT(CASE WHEN Returns = 1 THEN Product_Category END)
FROM Customer_Data
GROUP BY Product_Category
ORDER BY Product_Category

