USE BaraaData;

SELECT *
FROM customers;

SELECT*
FROM sales;

-----------------------------------------------------------------------------------------------------------------
-- CHANGE OVER TIME -> TRENDS
-- helps us to track trends and identify seasonality in data
-----------------------------------------------------------------------------------------------------------------
-- Do time analysis of total Sales over time

--1. Do analysis daywise

SELECT
	Order_date,
	SUM(sales_amount) AS total_sales_amount
FROM sales
WHERE Order_date IS NOT NULL
GROUP by order_date
ORDER BY order_date;

--2. Year Wise

SELECT
	year(Order_date) AS Order_year,
	SUM(sales_amount) AS toal_sales_amount
FROM sales
WHERE Order_date IS NOT NULL
GROUP by year(Order_date)
ORDER BY year(Order_date);

--3. Total number of customers (unique) dealt each year

SELECT
	year(Order_date) AS Order_year,
	SUM(sales_amount) AS total_sales_amount,
	Count(Distinct customer_key) AS total_customers
FROM sales
WHERE Order_date IS NOT NULL
GROUP by year(Order_date)
ORDER BY year(Order_date);

--4. Total number of Quntities sold each year
SELECT
	year(Order_date) AS Order_year,
	SUM(sales_amount) AS total_sales_amount,
	SUM(quantity) AS total_quantity,
	Count(Distinct customer_key) AS total_customers
FROM sales
WHERE Order_date IS NOT NULL
GROUP by year(Order_date)
ORDER BY year(Order_date);

-- 5. Do analysis for each month

SELECT
	month(Order_date) AS order_month,
	SUM(sales_amount) AS total_sales_amount,
	SUM(quantity) AS total_quantity,
	Count(Distinct customer_key) AS total_customers
FROM sales
WHERE Order_date IS NOT NULL
GROUP by month(Order_date)
ORDER BY month(Order_date);

-- 6. Do analysis for both month and year wise
-- 1 way
SELECT
	year(order_date) AS order_year,
	month(Order_date) AS order_month,
	SUM(sales_amount) AS total_sales_amount,
	SUM(quantity) AS total_quantity,
	Count(Distinct customer_key) AS total_customers
FROM sales
WHERE Order_date IS NOT NULL
GROUP by year(order_date), month(Order_date)
ORDER BY year(order_date), month(Order_date)

-- 2nd way
-- 6. Do analysis for both month and year wise
SELECT
	Datetrunc(month, order_date) AS order_year,
	SUM(sales_amount) AS total_sales_amount,
	SUM(quantity) AS total_quantity,
	Count(Distinct customer_key) AS total_customers
FROM sales
WHERE Order_date IS NOT NULL
GROUP by Datetrunc(month, order_date)
ORDER BY Datetrunc(month, order_date)

-- for year
SELECT
	Datetrunc(year, order_date) AS order_year,
	SUM(sales_amount) AS total_sales_amount,
	SUM(quantity) AS total_quantity,
	Count(Distinct customer_key) AS total_customers
FROM sales
WHERE Order_date IS NOT NULL
GROUP by Datetrunc(year, order_date) 
ORDER BY Datetrunc(year, order_date);

-- 3rd way
SELECT
	FORMAT(order_date, 'yyyy-MMM' ) AS order_year,
	SUM(sales_amount) AS total_sales_amount,
	SUM(quantity) AS total_quantity,
	Count(Distinct customer_key) AS total_customers
FROM sales
WHERE Order_date IS NOT NULL
GROUP by FORMAT(order_date, 'yyyy-MMM') ;
-- ORDER BY FORMAT(order_date, 'yyyy-MMM' ) 


-----------------------------------------------------------------------------------------------------------------
-- CUMULATIVE ANALYSIS
-- Helps us to understand whether our business is growing or declining over the time
-----------------------------------------------------------------------------------------------------------------
--  Calculate the total sales per month and the running total of sales over time.

WITH CTE_Date_order AS (
	SELECT
		CONVERT(DATE,DATETRUNC(month, order_date)) as order_date,
		SUM(Sales_amount) as total_sales
	FROM sales
	WHERE order_date is NOT NULL
	GROUP By DATETRUNC(month, order_date)
)
SELECT
	order_date,
	total_sales,
	SUM(total_sales) Over(Order by order_date) as running_total_sales
FROM
CTE_Date_order;

-- Partition the data by each year such that running total sales value is given for each year individually

WITH CTE_Date_order AS (
	SELECT
		CONVERT(DATE,DATETRUNC(month, order_date)) as order_date,
		SUM(Sales_amount) as total_sales
	FROM sales
	WHERE order_date is NOT NULL
	GROUP By DATETRUNC(month, order_date)
)
SELECT
	order_date,
	total_sales,
	SUM(total_sales) Over(Partition by year(order_date) order by order_date) as running_total_sales
FROM
CTE_Date_order;

-- year wise only

WITH CTE_Date_order AS (
	SELECT
		Convert(date,DATETRUNC(year, order_date)) as order_date,
		SUM(Sales_amount) as total_sales
	FROM sales
	WHERE order_date is NOT NULL
	GROUP By DATETRUNC(year, order_date)
)
SELECT
	order_date,
	total_sales,
	SUM(total_sales) Over(order by order_date) as running_total_sales
FROM
CTE_Date_order;

-- Calculate average sales as well
WITH CTE_Date_order AS (
	SELECT
		Convert(date,DATETRUNC(year, order_date)) as order_date,
		SUM(Sales_amount) as total_sales,
		Avg(price) as average_price
	FROM sales
	WHERE order_date is NOT NULL
	GROUP By DATETRUNC(year, order_date)
)
SELECT
	order_date,
	total_sales,
	SUM(total_sales) over(order by order_date) as running_total_sales,
	Round(avg(average_price) over(order by order_date),2) as moving_average_price
FROM
CTE_Date_order;



-----------------------------------------------------------------------------------------------------------------
-- PERFORMANCE ANALYSIS
-- Helps us to measure success and compare performace 
-----------------------------------------------------------------------------------------------------------------
/*--  analyze the yearly perofrmace of products by comparing their sales to both the average sales performance
of the product and the previous year's sales*/

WITH yearly_product_sales AS(
SELECT
	YEAR(s.order_date) AS order_year,
	p.product_name,
	SUM(s.sales_amount) AS current_sales
FROM sales s
JOIN products p
	ON s.product_key = p.product_key
WHERE s.order_date is NOT NULL
GROUP BY YEAR(s.order_date), p.product_name	
)

SELECT
	order_year,
	product_name,
	current_sales,
	AVG(current_sales) over(partition by product_name order by product_name) As avg_sales_products,
	current_sales - AVG(current_sales) over(partition by product_name order by product_name) AS diff_avg,
	CASE
		WHEN current_sales - AVG(current_sales) over(partition by product_name order by product_name)>0 THEN 'Above Avg'
		WHEN current_sales - AVG(current_sales) over(partition by product_name order by product_name)<0 THEN 'Below Avg'
		ELSE 'Avg'
	END AS 'avg_indiciator',
	-- Year over year analysis
	LAG(current_sales) over(partition by product_name order by order_year) AS py_sales,
	current_sales - LAG(current_sales) over(partition by product_name order by order_year) AS diff_py,
	CASE
		WHEN current_sales - LAG(current_sales) over(partition by product_name order by order_year)>0 THEN 'Increase'
		WHEN current_sales - LAG(current_sales) over(partition by product_name order by order_year)<0 THEN 'Decrease'
		ELSE 'No change'
	END AS 'py_change'

FROM
	yearly_product_sales;



-----------------------------------------------------------------------------------------------------------------
-- PARTS -TO - WHole analysis
-- Help us ot analyze how an individual part is performing compared to the overall, allowing us to understand
-- which category has the greatest impact on the business
-----------------------------------------------------------------------------------------------------------------

-- Which category contribute to most sales
WITH sales_category AS(
SELECT
	p.category,
	SUM(s.sales_amount) AS sales_amount
FROM sales s
JOIN products p
	ON s.product_key = p.product_key
GROUP BY p.category)

SELECT
	category,
	sales_amount,
	SUM(sales_amount) OVER() AS total_sales,
	CONCAT (Round(sales_amount/SUM(sales_amount) OVER()*100, 2),'%') AS total_sale_contribution
	--SUM(sales_amount) AS total_contibution
FROM sales_category
ORDER BY total_sale_contribution DESC;


-----------------------------------------------------------------------------------------------------------------
--Data Segmentation
-- Group a data based on a specific range
-- Helps to understand the correlation between two measures
-----------------------------------------------------------------------------------------------------------------

-- Segment products into cost ranges and count how many products fall into each segment

WITH product_cost_category AS(
SELECT
	product_key,
	product_name,
	category,
	cost,
	CASE
		WHEN cost < 100 THEN 'Below 100'
		WHEN cost BETWEEN 100 AND 500 THEN '100 - 500'
		WHEN cost BETWEEN 500 AND 1000 THEN '500 - 1000'
		ELSE 'Above 1000'
	END AS cost_category
FROM products)

SELECT
	cost_category,
	COUNT(product_key) as total_products
FROM product_cost_category
GROUP BY cost_category
ORDER BY total_products DESC;


/* GROUP customers into three segments based on their spending behavior
 -VIP: at least 12 months of history and spending more than $5000
 - Regular: at least 12 months of history but spending <=$5000
 - new: life span <12 months */

 WITH customer_spending AS(
 SELECT
	-- year( s.order_date) AS order_date,
	c.customer_id,
	SUM(s.sales_amount) AS total_spending,
	MIN(order_date) AS first_order,
	MAX(order_date) AS last_order,
	DATEDIFF(month, MIN(order_date),MAX(order_date)) AS customer_lifespan
 FROM customers c
 JOIN sales s
 ON c.customer_key = s.customer_key
 GROUP BY customer_id
 )
 
 SELECT
	customer_id,
	total_spending,
	customer_lifespan,
	CASE
		WHEN total_spending>5000 AND customer_lifespan>=12 THEN 'VIP'
		WHEN total_spending<=5000 AND customer_lifespan>=12 THEN 'Regular'
		ELSE 'New'
	END as customer_category
FROM customer_spending
ORDER BY total_spending DESC;


 -- find the total numbe rof customer by each group

 WITH customer_spending AS(
 SELECT
	-- year( s.order_date) AS order_date,
	c.customer_id,
	SUM(s.sales_amount) AS total_spending,
	MIN(order_date) AS first_order,
	MAX(order_date) AS last_order,
	DATEDIFF(month, MIN(order_date),MAX(order_date)) AS customer_lifespan
 FROM customers c
 JOIN sales s
 ON c.customer_key = s.customer_key
 GROUP BY customer_id
 ),

 customer_category AS(
 
 SELECT
	customer_id,
	CASE
		WHEN total_spending>5000 AND customer_lifespan>=12 THEN 'VIP'
		WHEN total_spending<=5000 AND customer_lifespan>=12 THEN 'Regular'
		ELSE 'New'
	END as customer_category
FROM customer_spending)

SELECT 
	customer_category,
	Count(customer_id) AS customer_count
FROM customer_category
GROUP BY customer_category
ORDER BY customer_count DESC;


/*

-----------------------------------------------------------------------------------------------------------------
Customer Report
-----------------------------------------------------------------------------------------------------------------

Purpose : 
	- This report consolidates key customer metrics and behaviors 
Highlights : 
1. Gathers essential fields such as names, ages, and transaction details. 
2. Segments customers into categories (VIP, Regular, New) and age groups.
3. Aggregates customer-level metrics: 
- total orders 
- total sales 
- total quantity purchased 
- total products 
- lifespan (in months) 
4. Calculates valuable KPIs:
- recency (months since last order) 
- average order value 
- average monthly spend 
*/

-------------------------------------------------------------------------------------------------------------------
 -- 1. Gathers essential fields such as names, ages, and transaction details. 


 WITH base_query AS(
 SELECT
	c.customer_key,
	c.customer_number,
	CONCAT(c.first_name,' ', c.last_name) AS customer_name,
	DATEDIFF (year, c.birthdate, GETDATE()) AS age,
	c.gender,
	s.order_date,
	s.order_number,
	s.product_key,
	s.sales_amount,
	s.quantity


 FROM customers c
 JOIN sales s
	ON c.customer_key = s.customer_key
WHERE order_date IS NOT NULL),

/*
3. Aggregates customer-level metrics: 
- total orders 
- total sales 
- total quantity purchased 
- total products 
- lifespan (in months) 
*/

aggregate_query AS(
SELECT
	customer_key,
	customer_number,
	customer_name,
	age,
	COUNT(DISTINCT order_number) AS total_orders,
	SUM(sales_amount) as total_sales,
	SUM(quantity) as total_quantity,
	COUNT(DISTINCT product_key) as total_products,
	MAX(order_date) AS last_order_date,
	DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan

	FROM base_query
	GROUP BY customer_key, customer_number, customer_name, age)

	
SELECT 
	customer_key,
	customer_number,
	customer_name,
	age,
	-- Segment customers into AGE GROUP
	CASE
		WHEN age < 20 THEN 'Under 20'
		WHEN  age BETWEEN 20 AND 30 THEN '20-30'
		WHEN  age BETWEEN 30 AND 40 THEN '30-40'
		WHEN  age BETWEEN 40 AND 50 THEN '40-50'
		ELSE 'Above 50'
	END AS age_group,
	lifespan,

	-- Segment customers into spending categories
	CASE
		WHEN total_sales>5000 AND lifespan>=12 THEN 'VIP'
		WHEN total_sales<=5000 AND lifespan>=12 THEN 'Regular'
		ELSE 'New'
	END as customer_category,
	total_orders,
	total_sales,
	total_quantity,
	total_products,
	last_order_date,

	-- recency (months since last order) 
	DATEDIFF(month, last_order_date, GETDATE()) AS recency,

	-- average order value 
	CASE
		WHEN total_sales = 0 THEN 0
		ELSE total_sales/total_orders 
	END AS average_order_value,

	-- average monthly spend 
	CASE
		WHEN lifespan = 0 THEN total_sales
		ELSE total_sales/lifespan
	END AS average_monthly_spend

FROM aggregate_query;


-------------------------------------------------------------------------------------------------------------------------------------
-- CREATE VIEW

CREATE VIEW report_customers AS
SELECT 
    customer_key,
    customer_number,
    customer_name,
    age,
    -- Segment customers into AGE GROUP
    CASE
        WHEN age < 20 THEN 'Under 20'
        WHEN age BETWEEN 20 AND 30 THEN '20-30'
        WHEN age BETWEEN 30 AND 40 THEN '30-40'
        WHEN age BETWEEN 40 AND 50 THEN '40-50'
        ELSE 'Above 50'
    END AS age_group,
    lifespan,

    -- Segment customers into spending categories
    CASE
        WHEN total_sales > 5000 AND lifespan >= 12 THEN 'VIP'
        WHEN total_sales <= 5000 AND lifespan >= 12 THEN 'Regular'
        ELSE 'New'
    END AS customer_category,
    total_orders,
    total_sales,
    total_quantity,
    total_products,
    last_order_date,

    -- recency (months since last order) 
    DATEDIFF(month, last_order_date, GETDATE()) AS recency,

    -- average order value 
    CASE
        WHEN total_sales = 0 THEN 0
        ELSE total_sales / total_orders 
    END AS average_order_value,

    -- average monthly spend 
    CASE
        WHEN lifespan = 0 THEN total_sales
        ELSE total_sales / lifespan
    END AS average_monthly_spend
FROM (
    SELECT
        c.customer_key,
        c.customer_number,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        DATEDIFF(year, c.birthdate, GETDATE()) AS age,
        COUNT(DISTINCT s.order_number) AS total_orders,
        SUM(s.sales_amount) AS total_sales,
        SUM(s.quantity) AS total_quantity,
        COUNT(DISTINCT s.product_key) AS total_products,
        MAX(s.order_date) AS last_order_date,
        DATEDIFF(month, MIN(s.order_date), MAX(s.order_date)) AS lifespan
    FROM customers c
    JOIN sales s ON c.customer_key = s.customer_key
    WHERE s.order_date IS NOT NULL
    GROUP BY c.customer_key, c.customer_number, c.first_name, c.last_name, c.birthdate
) AS aggregate_query;




