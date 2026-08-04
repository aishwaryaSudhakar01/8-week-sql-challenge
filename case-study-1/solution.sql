#Creating a view that combines: sales, menu and member tables
CREATE MATERIALIZED VIEW `dannys_diner.sales_menu_members` AS
SELECT
  s.customer_id,
  s.order_date,
  s.product_id,
  m.product_name,
  m.price,
  mem.join_date,
  CASE 
    WHEN s.order_date >= mem.join_date AND mem.join_date IS NOT NULL THEN 'Y'
    ELSE 'N'
  END AS is_member
FROM `dannys_diner.sales` s
JOIN `dannys_diner.menu` m
  ON s.product_id = m.product_id
LEFT JOIN `dannys_diner.members` mem
  ON s.customer_id = mem.customer_id;

#What is the total amount each customer spent at the restaurant?
SELECT
  customer_id,
  SUM(price) AS total_amount
FROM `dannys_diner.sales_menu_members`
GROUP BY customer_id
ORDER BY customer_id;

#How many days has each customer visited the restaurant?
SELECT 
  customer_id,
  COUNT(DISTINCT order_date) AS visit_count
FROM `dannys_diner.sales_menu_members`
GROUP BY customer_id
ORDER BY customer_id;

#What was the first item from the menu purchased by each customer?
WITH cte AS (
  SELECT
    customer_id,
    product_name,
    order_date,
    ROW_NUMBER() OVER (PARTITION BY customer_id 
      ORDER BY order_date, product_id) AS rn
  FROM `dannys_diner.sales_menu_members`
)

SELECT 
  customer_id,
  product_name,
  order_date
FROM cte
WHERE rn = 1;

#What is the most purchased item on the menu and how many times was it purchased by all customers?
WITH cte AS (
  SELECT 
    product_name,
    COUNT(*) AS order_count,
    DENSE_RANK() OVER (ORDER BY COUNT(product_name) DESC) AS rn
  FROM `dannys_diner.sales_menu_members`
  GROUP BY product_name
)

SELECT 
  product_name,
  order_count
FROM cte
WHERE rn = 1;

#Which item was the most popular for each customer?
WITH cte AS (
  SELECT 
    customer_id,
    product_name,
    COUNT(product_name) AS purchase_count,
    DENSE_RANK() OVER (PARTITION BY customer_id 
      ORDER BY COUNT(product_name) DESC) AS rn
  FROM `dannys_diner.sales_menu_members`
  GROUP BY 
    customer_id,
    product_name
)

SELECT 
  customer_id,
  product_name,
  purchase_count
FROM cte
WHERE rn = 1;

#Which item was purchased first by the customer after they became a member?
WITH cte AS (
  SELECT 
    customer_id,
    product_name,
    order_date,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) AS rn
  FROM `dannys_diner.sales_menu_members`
  WHERE is_member = 'Y'
)

SELECT 
  customer_id,
  product_name
FROM cte
WHERE rn = 1;

#Which item was purchased just before the customer became a member?
WITH cte AS (
  SELECT 
    customer_id,
    product_name,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS rn
  FROM `dannys_diner.sales_menu_members`
  WHERE order_date < join_date
)

SELECT 
  customer_id,
  product_name
FROM cte
WHERE rn = 1;

#What is the total items and amount spent for each member before they became a member?
SELECT 
  customer_id,
  COUNT(*) AS order_count,
  SUM(price) AS total_amount
FROM `dannys_diner.sales_menu_members`
WHERE order_date < join_date
GROUP BY customer_id
ORDER BY customer_id;

#If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT 
  customer_id,
  SUM(CASE 
    WHEN product_name = 'sushi' THEN price*20
    ELSE price*10
  END) AS total_points
FROM `dannys_diner.sales_menu_members`
GROUP BY customer_id
ORDER BY customer_id;

#In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT 
  customer_id,
  SUM(CASE
    WHEN order_date BETWEEN join_date AND 
      DATE_ADD(join_date, INTERVAL 6 DAY) THEN price*20
    WHEN product_name = 'sushi' THEN price*20 
    ELSE price*10 
  END) AS total_points
FROM `dannys_diner.sales_menu_members`
WHERE join_date IS NOT NULL
  AND order_date <= '2021-01-31'
GROUP BY customer_id
ORDER BY customer_id;

#Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.
SELECT
  *,
  CASE 
    WHEN is_member = 'Y' THEN DENSE_RANK() 
      OVER (PARTITION BY customer_id, is_member ORDER BY order_date)
    ELSE NULL
  END AS ranking
FROM `dannys_diner.sales_menu_members`;