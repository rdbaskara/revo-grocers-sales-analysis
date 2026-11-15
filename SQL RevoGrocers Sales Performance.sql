-- 1. Identify the product categories with highest revenue (after discount)


SELECT
  c.categoryname AS product_category,
  ROUND(SUM((1-s.Discount)*(p.price*s.Quantity))) AS total_revenue

FROM `fsda-sql-01.grocery_dataset.sales` AS s
JOIN `fsda-sql-01.grocery_dataset.products` AS p
  ON s.ProductID = p.productid
JOIN  `fsda-sql-01.grocery_dataset.categories` AS c
  ON c.categoryid = p.categoryid
WHERE s.Quantity IS NOT NULL
  AND p.price IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1


-- 2. Assess the relation between revenue after discount and total unit sold for each product category

SELECT
  c.categoryname AS product_category,
  SUM(s.Quantity) AS total_sold,
  ROUND(SUM((1-s.Discount)*(p.price*s.Quantity))) AS total_revenue

FROM `fsda-sql-01.grocery_dataset.sales` AS s
JOIN `fsda-sql-01.grocery_dataset.products` AS p
  ON s.ProductID = p.productid
JOIN  `fsda-sql-01.grocery_dataset.categories` AS c
  ON c.categoryid = p.categoryid
WHERE s.Quantity IS NOT NULL
  AND p.price IS NOT NULL
GROUP BY 1
ORDER BY 3 DESC

-- 3. Find relation between revenue after discount and the number of unique customers for each product category

SELECT
  c.categoryname AS product_category,
  COUNT(DISTINCT s.CustomerID) AS unique_customer,
  ROUND(SUM((1-s.Discount)*(p.price*s.Quantity))) AS total_revenue

FROM `fsda-sql-01.grocery_dataset.sales` AS s
JOIN `fsda-sql-01.grocery_dataset.products` AS p
  ON s.ProductID = p.productid
JOIN  `fsda-sql-01.grocery_dataset.categories` AS c
  ON c.categoryid = p.categoryid
WHERE s.Quantity IS NOT NULL
  AND p.price IS NOT NULL
GROUP BY 1
ORDER BY 3 DESC

-- 4. Calculate the average unit price for each product category in catalogue

SELECT
  c.categoryname AS product_category,
  ROUND(AVG(p.price)) AS avg_price,
  ROUND(SUM((1-s.Discount)*(p.price*s.Quantity))) AS total_revenue

FROM `fsda-sql-01.grocery_dataset.sales` AS s
JOIN `fsda-sql-01.grocery_dataset.products` AS p
  ON s.ProductID = p.productid
JOIN  `fsda-sql-01.grocery_dataset.categories` AS c
  ON c.categoryid = p.categoryid
WHERE s.Quantity IS NOT NULL
  AND p.price IS NOT NULL
GROUP BY 1
ORDER BY 3 DESC

-- 5. Evaluate the relation between the average of unit price and the number of buyers (unique customer) per product category

SELECT
  c.categoryname AS product_category,
  ROUND(AVG(p.price)) AS avg_price,
  COUNT(DISTINCT s.CustomerID) AS unique_customer,

FROM `fsda-sql-01.grocery_dataset.sales` AS s
JOIN `fsda-sql-01.grocery_dataset.products` AS p
  ON s.ProductID = p.productid
JOIN  `fsda-sql-01.grocery_dataset.categories` AS c
  ON c.categoryid = p.categoryid
WHERE s.Quantity IS NOT NULL
  AND p.price IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC

-- 6. Which category contribute the most to overall revenue after discount (percentage-wise)

SELECT
  c.categoryname AS product_category,
  ROUND(SUM((1-s.Discount)*(p.price*s.Quantity))) AS total_revenue,
  ROUND
  (
    100*
    (SUM((1-s.Discount)*(p.price*s.Quantity)))/
    SUM(SUM((1-s.Discount)*(p.price*s.Quantity))) OVER ()
  ,1) AS contribution

FROM `fsda-sql-01.grocery_dataset.sales` AS s
JOIN `fsda-sql-01.grocery_dataset.products` AS p
  ON s.ProductID = p.productid
JOIN  `fsda-sql-01.grocery_dataset.categories` AS c
  ON c.categoryid = p.categoryid
WHERE s.Quantity IS NOT NULL
  AND p.price IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC


-- 7. Which product categories have the highest repeat purchase rate

WITH sales AS 
  (SELECT
    c.categoryname AS product_category,
    s.CustomerID AS customer,
    COUNT(s.SalesID) AS total_transaction

  FROM `fsda-sql-01.grocery_dataset.sales` AS s
  JOIN `fsda-sql-01.grocery_dataset.products` AS p
    ON s.ProductID = p.productid
  JOIN  `fsda-sql-01.grocery_dataset.categories` AS c
    ON c.categoryid = p.categoryid
  WHERE s.Quantity IS NOT NULL
    AND p.price IS NOT NULL
  GROUP BY 1,2
  )
SELECT
    product_category AS product_category,
    COUNT(DISTINCT customer) AS unique_customer,
    COUNT(DISTINCT CASE WHEN total_transaction > 1
      THEN customer END) AS repeat_customer,
    ROUND
    ( 
      100*
      COUNT(DISTINCT CASE WHEN total_transaction > 1 THEN customer END)
      / COUNT(customer)
    ,2) AS repeat_rate

FROM sales
GROUP BY 1
ORDER BY 4 DESC

--9. Cumulative total of transaction of top user (user with highest transaction value, window function)

WITH sales AS 
  (SELECT
    s.CustomerID AS customer_id,
    DATE(DATE_TRUNC (s.SalesDate,DAY)) AS  order_date, 
    SUM((1-s.Discount)*(p.price*s.Quantity)) AS total_revenue

  FROM `fsda-sql-01.grocery_dataset.sales` AS s
  JOIN `fsda-sql-01.grocery_dataset.products` AS p
    ON s.ProductID = p.productid
  JOIN  `fsda-sql-01.grocery_dataset.categories` AS c
    ON c.categoryid = p.categoryid
  WHERE s.Quantity IS NOT NULL
    AND p.price IS NOT NULL
  GROUP BY 1,2
  ),
  customer AS 
  ( SELECT
      customer_id AS customer_id,
      SUM(total_revenue) AS total_revenue
    FROM sales
    GROUP BY 1
    ORDER BY 2 DESC
    LIMIT 1
  )
SELECT
  s.customer_id AS customer_id,
  s.order_date AS order_date,
  ROUND(s.total_revenue) AS revenue,
  ROUND(SUM(s.total_revenue) 
    OVER(PARTITION BY s.customer_id 
    ORDER BY s.order_date)) AS cumulative_revenue

FROM sales AS s
JOIN customer AS c
  ON s.customer_id = c.customer_id
ORDER BY 2 DESC

  