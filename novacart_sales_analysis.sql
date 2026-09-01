-- ==============================================================================================================================
--                                                   NOVACART SALES ANALYSIS
-- ==============================================================================================================================

CREATE DATABASE novacart;

USE novacart;


-- ==============================================================================================================================
--                                                   PHASE 1: DATA VALIDATION
-- ==============================================================================================================================
-- Objective:
-- Validate the structure, completeness, consistency, and integrity of the NovaCart dataset
-- before performing business analysis.
-- ==============================================================================================================================


-- ==============================================================================================================================
-- STEP 1: CREATE CUSTOMERS TABLE
-- ==============================================================================================================================

CREATE TABLE customers (
    customer_id VARCHAR(10) PRIMARY KEY,
    customer_name VARCHAR(100),
    city VARCHAR(50),
    state VARCHAR(50),
    customer_segment VARCHAR(30)
);


-- ==============================================================================================================================
-- STEP 2: CREATE PRODUCTS TABLE
-- ==============================================================================================================================

CREATE TABLE products (
    product_id VARCHAR(10) PRIMARY KEY,
    product_name VARCHAR(150),
    category VARCHAR(50),
    sub_category VARCHAR(50),
    unit_cost DECIMAL(10,2),
    unit_price DECIMAL(10,2)
);


-- ==============================================================================================================================
-- STEP 3: CREATE ORDERS TABLE
-- ==============================================================================================================================

CREATE TABLE orders (
    order_id VARCHAR(10) PRIMARY KEY,
    customer_id VARCHAR(10),
    product_id VARCHAR(10),
    order_date DATE,
    quantity INT,
    discount DECIMAL(5,2),
    revenue DECIMAL(12,2),
    profit DECIMAL(12,2),

    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);


-- ==============================================================================================================================
-- STEP 4: CHECK TOTAL RECORDS IN EACH TABLE
-- ==============================================================================================================================
-- Purpose:
-- Confirm that the expected number of customers, products, and orders exist.
-- ==============================================================================================================================

SELECT COUNT(*) AS total_customers
FROM customers;

SELECT COUNT(*) AS total_products
FROM products;

SELECT COUNT(*) AS total_orders
FROM orders;


-- ==============================================================================================================================
-- STEP 5: CHECK UNIQUE CUSTOMERS AND PRODUCTS IN ORDERS
-- ==============================================================================================================================
-- Purpose:
-- Determine how many unique customers and products are represented in the order data.
-- ==============================================================================================================================

SELECT
    COUNT(*) AS total_orders,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(DISTINCT product_id) AS unique_products
FROM orders;


-- ==============================================================================================================================
-- STEP 6: CHECK INVALID CUSTOMER REFERENCES
-- ==============================================================================================================================
-- Purpose:
-- Verify that every customer_id in orders exists in the customers table.
-- Expected result: 0
-- ==============================================================================

SELECT
    COUNT(*) AS invalid_customer_references
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


-- ==============================================================================================================================
-- STEP 7: CHECK INVALID PRODUCT REFERENCES
-- ==============================================================================================================================
-- Purpose:
-- Verify that every product_id in orders exists in the products table.
-- Expected result: 0
-- ==============================================================================

SELECT
    COUNT(*) AS invalid_product_references
FROM orders o
LEFT JOIN products p
    ON o.product_id = p.product_id
WHERE p.product_id IS NULL;


-- ==============================================================================================================================
-- STEP 8: CHECK DUPLICATE ORDER IDs
-- ==============================================================================================================================
-- Purpose:
-- Confirm that every order has a unique order_id.
-- Expected result:
-- total_rows = 50000
-- unique_order_ids = 50000
-- ==============================================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_order_ids
FROM orders;


-- ==============================================================================================================================
-- STEP 9: CHECK ORDER DATE COVERAGE
-- ==============================================================================================================================
-- Purpose:
-- Verify that orders cover the complete expected year of 2025.
-- Expected:
-- earliest_date = 2025-01-01
-- latest_date = 2025-12-31
-- unique_dates = 365
-- ==============================================================================

SELECT
    MIN(order_date) AS earliest_date,
    MAX(order_date) AS latest_date,
    COUNT(DISTINCT order_date) AS unique_dates
FROM orders;


-- ==============================================================================================================================
-- STEP 10: CHECK MISSING VALUES
-- ==============================================================================================================================
-- Purpose:
-- Identify NULL values in important order fields.
-- Expected result: all values should be 0.
-- ==============================================================================

SELECT
    SUM(order_id IS NULL) AS missing_order_id,
    SUM(customer_id IS NULL) AS missing_customer_id,
    SUM(product_id IS NULL) AS missing_product_id,
    SUM(order_date IS NULL) AS missing_order_date,
    SUM(quantity IS NULL) AS missing_quantity,
    SUM(discount IS NULL) AS missing_discount,
    SUM(revenue IS NULL) AS missing_revenue,
    SUM(profit IS NULL) AS missing_profit
FROM orders;


-- ==============================================================================================================================
-- STEP 11: CHECK QUANTITY RANGE
-- ==============================================================================================================================
-- Purpose:
-- Check the minimum and maximum quantity values in the orders.
-- ==============================================================================================================================

SELECT
    MIN(quantity) AS minimum_quantity,
    MAX(quantity) AS maximum_quantity,
    COUNT(*) AS total_orders
FROM orders;


-- ==============================================================================================================================
-- STEP 12: CHECK DISCOUNT RANGE
-- ==============================================================================================================================
-- Purpose:
-- Check the minimum and maximum discount values.
-- ==============================================================================================================================

SELECT
    MIN(discount) AS minimum_discount,
    MAX(discount) AS maximum_discount,
    COUNT(*) AS total_orders
FROM orders;


-- ==============================================================================================================================
-- STEP 13: CHECK REVENUE AND PROFIT RANGES
-- ==============================================================================================================================
-- Purpose:
-- Review the minimum and maximum revenue and profit values.
-- ==============================================================================================================================

SELECT
    MIN(revenue) AS minimum_revenue,
    MAX(revenue) AS maximum_revenue,
    MIN(profit) AS minimum_profit,
    MAX(profit) AS maximum_profit,
    COUNT(*) AS total_orders
FROM orders;


-- ==============================================================================================================================
-- STEP 14: IDENTIFY LOWEST-PROFIT ORDERS
-- ==============================================================================================================================
-- Purpose:
-- Identify the 10 orders with the lowest profit for data-quality inspection.
-- ==============================================================================================================================

SELECT
    order_id,
    product_id,
    quantity,
    discount,
    revenue,
    profit
FROM orders
ORDER BY profit ASC
LIMIT 10;


-- ==============================================================================================================================
-- STEP 15: CHECK QUANTITY DISTRIBUTION
-- ==============================================================================================================================
-- Purpose:
-- Understand how order quantities are distributed across the dataset.
-- ==============================================================================================================================

SELECT
    quantity,
    COUNT(*) AS order_count
FROM orders
GROUP BY quantity
ORDER BY quantity;


-- ==============================================================================================================================
-- STEP 16: CHECK DISCOUNT DISTRIBUTION
-- ==============================================================================================================================
-- Purpose:
-- Understand how frequently each discount level is used.
-- ==============================================================================================================================

SELECT
    discount,
    COUNT(*) AS order_count
FROM orders
GROUP BY discount
ORDER BY discount;


-- ==============================================================================================================================
-- STEP 17: VALIDATE REVENUE CALCULATION
-- ==============================================================================================================================
-- Revenue formula:
-- Revenue = Unit Price × Quantity × (1 - Discount / 100)
--
-- Expected result: 0 invalid revenue records.
-- ==============================================================================

SELECT
    COUNT(*) AS invalid_revenue
FROM orders o
JOIN products p
    ON o.product_id = p.product_id
WHERE ABS(
    o.revenue -
    ROUND(
        p.unit_price * o.quantity * (1 - o.discount / 100),
        2
    )
) > 0.01;


-- ==============================================================================================================================
-- STEP 18: VALIDATE PROFIT CALCULATION
-- ==============================================================================================================================
-- Profit formula:
-- Profit = Revenue - (Unit Cost × Quantity)
--
-- Expected result: 0 invalid profit records.
-- ==============================================================================

SELECT
    COUNT(*) AS invalid_profit
FROM orders o
JOIN products p
    ON o.product_id = p.product_id
WHERE ABS(
    o.profit -
    ROUND(
        o.revenue - (p.unit_cost * o.quantity),
        2
    )
) > 0.01;


-- ==============================================================================================================================
-- STEP 19: CHECK CUSTOMERS WITH ORDERS
-- ==============================================================================================================================
-- Purpose:
-- Count the number of unique customers who placed at least one order.
-- ==============================================================================

SELECT
    COUNT(DISTINCT customer_id) AS customers_with_orders
FROM orders;


-- ==============================================================================================================================
-- STEP 20: CHECK PRODUCTS WITH ORDERS
-- ==============================================================================================================================
-- Purpose:
-- Count the number of unique products that were ordered.
-- ==============================================================================

SELECT
    COUNT(DISTINCT product_id) AS products_with_orders
FROM orders;


-- ==============================================================================================================================
-- STEP 21: CHECK TOTAL UNITS SOLD
-- ==============================================================================================================================
-- Purpose:
-- Calculate the total number of individual units sold.
-- ==============================================================================

SELECT
    SUM(quantity) AS total_units_sold
FROM orders;


-- ==============================================================================================================================
-- STEP 22: CALCULATE AVERAGE ORDER VALUE
-- ==============================================================================================================================
-- Purpose:
-- Calculate the average revenue generated per order.
-- ==============================================================================

SELECT
    ROUND(AVG(revenue), 2) AS average_order_value
FROM orders;


-- ==============================================================================================================================
-- STEP 23: CALCULATE OVERALL PROFIT MARGIN
-- ==============================================================================================================================
-- Purpose:
-- Calculate profit as a percentage of total revenue.
-- ==============================================================================

SELECT
    ROUND(
        SUM(profit) / SUM(revenue) * 100,
        2
    ) AS profit_margin_percent
FROM orders;


-- ==============================================================================================================================
-- STEP 24: CALCULATE TOTAL DISCOUNT AMOUNT
-- ==============================================================================================================================
-- Purpose:
-- Estimate the total monetary discount given across all orders.
-- ==============================================================================

SELECT
    ROUND(
        SUM(
            revenue / (1 - discount / 100) - revenue
        ),
        2
    ) AS total_discount_amount
FROM orders
WHERE discount < 100;


-- ==============================================================================================================================
-- STEP 25: CALCULATE AVERAGE DISCOUNT
-- ==============================================================================================================================
-- Purpose:
-- Calculate the average discount percentage across all orders.
-- ==============================================================================

SELECT
    ROUND(AVG(discount), 2) AS average_discount
FROM orders;


-- ==============================================================================================================================
-- STEP 26: CHECK ORDERS BY MONTH
-- ==============================================================================================================================
-- Purpose:
-- Check the number of orders received in each month.
-- ==============================================================================

SELECT
    MONTH(order_date) AS month_number,
    COUNT(*) AS total_orders
FROM orders
GROUP BY MONTH(order_date)
ORDER BY month_number;


-- ==============================================================================================================================
-- STEP 27: CHECK REVENUE BY MONTH
-- ==============================================================================================================================
-- Purpose:
-- Calculate total revenue generated in each month.
-- ==============================================================================

SELECT
    MONTH(order_date) AS month_number,
    ROUND(SUM(revenue), 2) AS total_revenue
FROM orders
GROUP BY MONTH(order_date)
ORDER BY month_number;


-- ==============================================================================================================================
-- STEP 28: CHECK PROFIT BY MONTH
-- ==============================================================================================================================
-- Purpose:
-- Calculate total profit generated in each month.
-- ==============================================================================

SELECT
    MONTH(order_date) AS month_number,
    ROUND(SUM(profit), 2) AS total_profit
FROM orders
GROUP BY MONTH(order_date)
ORDER BY month_number;


-- ==============================================================================================================================
-- STEP 29: FINAL TABLE RECORD COUNT CHECK
-- ==============================================================================================================================
-- Purpose:
-- Confirm the final number of customers, products, and orders.
-- Expected:
-- customers = 2000
-- products = 200
-- orders = 50000
-- ==============================================================================

SELECT
    (SELECT COUNT(*) FROM customers) AS total_customers,
    (SELECT COUNT(*) FROM products) AS total_products,
    (SELECT COUNT(*) FROM orders) AS total_orders;


-- ==============================================================================================================================
-- STEP 30: FINAL DATA QUALITY CHECK
-- ==============================================================================================================================
-- Purpose:
-- Perform one final validation of order completeness, uniqueness,
-- relationships, quantities, and missing values.
-- ==============================================================================

SELECT
    COUNT(*) AS total_orders,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(DISTINCT customer_id) AS customers_with_orders,
    COUNT(DISTINCT product_id) AS products_with_orders,
    SUM(quantity) AS total_quantity_sold,

    SUM(order_id IS NULL) AS missing_order_ids,
    SUM(customer_id IS NULL) AS missing_customer_ids,
    SUM(product_id IS NULL) AS missing_product_ids,
    SUM(order_date IS NULL) AS missing_dates,
    SUM(quantity IS NULL) AS missing_quantities,
    SUM(discount IS NULL) AS missing_discounts,
    SUM(revenue IS NULL) AS missing_revenue,
    SUM(profit IS NULL) AS missing_profit

FROM orders;


-- ==============================================================================================================================
-- PHASE 1 COMPLETE
-- ==============================================================================================================================


-- ==============================================================================================================================
--                                                   PHASE 2: BUSINESS ANALYSIS
-- ==============================================================================================================================

-- ==============================================================================================================================
-- STEP 1: OVERALL BUSINESS KPIs
-- ==============================================================================================================================
-- Purpose:
-- Calculate the key performance indicators for the entire business.
--
-- KPIs:
-- 1. Total Orders
-- 2. Total Units Sold
-- 3. Total Revenue
-- 4. Total Profit
-- 5. Average Order Value
-- 6. Overall Profit Margin
-- ==============================================================================================================================

select
count(*) as total_orders,
sum(quantity) as total_unit_sold,
round(sum(revenue),2) as total_revenue,
round(sum(profit),2) as total_profit,
round(sum(profit)/sum(revenue)*100,2) as profit_margin_percent
from orders;

-- ==============================================================================================================================
-- STEP 2: MONTHLY BUSINESS PERFORMANCE
-- ==============================================================================================================================
-- Purpose:
-- Analyze monthly orders, revenue, profit, and profit margin.
-- ==============================================================================

select
count(*) as total_orders,
sum(quantity) as unit_sold,
month(order_date) as month_number,
round(sum(revenue),2) as monthly_revenue,
round(sum(profit),2) as monthly_profit,
round(sum(profit)/sum(revenue)*100,2) as profit_margin
from orders
group by month(order_date)
order by month_number;

-- ==============================================================================================================================
-- STEP 3: CATEGORY PERFORMANCE
-- ==============================================================================================================================
-- Purpose:
-- Analyze orders, units sold, revenue, profit, and profit margin by product category.
-- ================================================================================================================================================

select p.category,
count(*) as total_order,
sum(o.quantity) as total_unit_sold,
round(sum(o.revenue),2) as total_revenue,
round(sum(o.profit),2) as total_profit,
round(sum(o.profit)/sum(o.revenue)*100,2) as total_margin_profit
from orders o
join products p
on o.product_id = p.product_id
group by category
order by total_revenue DESC ;

-- ==============================================================================================================================
-- STEP 4: SUB-CATEGORY PERFORMANCE
-- ==============================================================================================================================
-- Purpose:
-- Analyze orders, units sold, revenue, profit, and profit margin
-- for each product sub-category.
-- ==============================================================================

select p.sub_category,
count(*) as total_order,
sum(o.quantity) as total_unit_sold,
round(sum(o.revenue),2) as total_revenue,
round(sum(o.profit),2) as total_profit,
round(sum(o.profit)/sum(o.revenue)*100,2) as total_margin_profit
from orders o
join products p
on o.product_id = p.product_id
group by sub_category
order by total_revenue DESC ;


-- ==============================================================================================================================
-- STEP 5: PRODUCT PERFORMANCE
-- ==============================================================================================================================
-- Purpose:
-- Identify the products generating the highest revenue and profit.
-- ==============================================================================

select
p.product_id,
p.product_name,
p.category,
p.sub_category,
count(*) as total_order,
sum(o.quantity) as total_unit_sold,
round(sum(o.revenue),2) as total_revenue,
round(sum(o.profit),2) as total_profit,
round(sum(o.profit)/sum(o.revenue)*100,2) as profit_margin_percent
from orders o
join products p
on o.product_id = p.product_id
group by 
p.product_id,
p.product_name,
p.category,
p.sub_category
order by total_revenue DESC 
limit 10;


-- ==============================================================================================================================
-- STEP 6: CUSTOMER PERFORMANCE
-- ==============================================================================================================================
-- Purpose:
-- Identify the customers generating the highest revenue and profit.
-- ==============================================================================

select
 c.customer_id,
    c.customer_name,
    c.city,
    c.state,
    c.customer_segment,
count(*) as total_order,
sum(o.quantity) as total_unit_sold,
round(sum(o.revenue),2) as total_revenue,
round(sum(o.profit),2) as total_profit,
round(sum(o.profit)/sum(o.revenue)*100,2) as profit_margin_percent
from orders o
JOIN customers c
    ON o.customer_id = c.customer_id
GROUP BY
    c.customer_id,
    c.customer_name,
    c.city,
    c.state,
    c.customer_segment
    ORDER BY total_revenue DESC
LIMIT 10;


-- ==============================================================================================================================
-- STEP 7: CUSTOMER SEGMENT PERFORMANCE
-- ==============================================================================================================================
-- Purpose:
-- Compare business performance across Consumer, Corporate, and Small Business customers.
-- ==============================================================================

select
c.customer_segment,
count(distinct c.customer_id) as total_custoer,
count(*) as total_order,
sum(o.quantity) as total_unit_sold,
round(sum(o.revenue),2) as total_revenue,
round(sum(o.profit),2) as total_profit,
round(sum(o.profit)/sum(o.revenue)*100,2) as profit_margin_percent
from orders o
JOIN customers c
ON o.customer_id = c.customer_id
group by c.customer_segment
order by total_revenue;



-- ==============================================================================================================================
-- STEP 8: STATE-LEVEL PERFORMANCE
-- ==============================================================================================================================
-- Purpose:
-- Analyze orders, revenue, profit, and profit margin by customer state.
-- ==============================================================================

select
c.state,
count(distinct c.customer_id) as total_customer,
count(*) as total_order,
sum(o.quantity) as total_unit_sold,
round(sum(o.revenue),2) as total_revenue,
round(sum(o.profit),2) as total_profit,
round(sum(o.profit)/sum(o.revenue)*100,2) as profit_margin_percent
from orders o
JOIN customers c
ON o.customer_id = c.customer_id
group by c.state
order by total_revenue DESC;



-- ==============================================================================================================================
-- STEP 9: DISCOUNT IMPACT ANALYSIS
-- ==============================================================================================================================
-- Purpose:
-- Analyze how different discount levels affect orders, revenue, profit,
-- and profit margin.
-- ==============================================================================

select
discount,
count(*) as total_order,
sum(quantity) as total_unit_sold,
round(sum(revenue),2) as total_revenue,
round(sum(profit),2) as total_profit,
round(sum(profit)/sum(revenue)*100,2) as profit_margin_percent
from orders
group by discount
order by total_revenue desc;


-- ==============================================================================================================================
-- STEP 10: QUANTITY & ORDER VALUE ANALYSIS
-- ==============================================================================================================================
-- Purpose:
-- Analyze how order quantity affects revenue, profit, and profit margin.
-- ==============================================================================

select
quantity,
count(*) as total_order,
round(AVG(revenue),2) as avg_order_revenue,
round(sum(revenue),2) as total_revenue,
round(sum(profit),2) as total_profit,
round(sum(profit)/sum(revenue)*100,2) as profit_margin_percent
from orders
group by quantity
order by quantity ;


-- ==============================================================================================================================
-- STEP 11: TOP PRODUCTS BY PROFIT
-- ==============================================================================================================================
-- Purpose:
-- Identify the products generating the highest total profit.
-- ==============================================================================

select
p.product_id,
p.product_name,
p.category,
p.sub_category,
count(*) as total_order,
sum(o.quantity) as total_unit_sold,
round(sum(o.revenue),2) as total_revenue,
round(sum(o.profit),2) as total_profit,
round(sum(o.profit)/sum(o.revenue)*100,2) as profit_margin_percent
from orders o
join products p
on o.product_id = p.product_id
group by 
p.product_id,
p.product_name,
p.category,
p.sub_category
order by total_profit DESC 
limit 10;


-- ==============================================================================================================================
-- STEP 12: LOW-MARGIN PRODUCTS
-- ==============================================================================================================================
-- Purpose:
-- Identify products with the lowest profit margins.
-- These products may require pricing, cost, or discount optimization.
-- ==============================================================================

select
p.product_id,
p.product_name,
p.category,
p.sub_category,
count(*) as total_order,
sum(o.quantity) as total_unit_sold,
round(sum(o.revenue),2) as total_revenue,
round(sum(o.profit),2) as total_profit,
round(sum(o.profit)/sum(o.revenue)*100,2) as profit_margin_percent
from orders o
join products p
on o.product_id = p.product_id
group by 
p.product_id,
p.product_name,
p.category,
p.sub_category
having sum(o.revenue)>1000000
order by profit_margin_percent asc 
limit 10;

-- ==============================================================================================================================
-- STEP 13: REVENUE CONCENTRATION
-- ==============================================================================================================================
-- Purpose:
-- Measure how much of total business revenue is generated by the top 10 products.
-- ==============================================================================


select
round(sum(total_revenue),2) as top_10_revenue,
round(sum(total_revenue/ (select sum(revenue)from orders))*100,2) as top_10_revenue_percent,
round((select sum(revenue) from orders),2) AS total_business_revenue

from(
select
o.product_id,
sum(o.revenue) as total_revenue
from orders o
group by o.product_id
order by total_revenue desc
limit 10) as top_product;


