# Case Study #1: Danny's Diner

🔗 [Case study brief](https://8weeksqlchallenge.com/case-study-1/)

Danny's Diner wants to understand customer visiting patterns, spend, and favourite menu items, and to evaluate whether a loyalty program is worth building.

<table align="center">
<tr>
<td align="center"><a href="#erd">ERD</a></td>
<td align="center"><a href="#setup-a-materialized-view-for-the-recurring-join">Setup</a></td>
<td align="center"><a href="#1-what-is-the-total-amount-each-customer-spent-at-the-restaurant">Q1</a></td>
<td align="center"><a href="#2-how-many-days-has-each-customer-visited-the-restaurant">Q2</a></td>
<td align="center"><a href="#3-what-was-the-first-item-from-the-menu-purchased-by-each-customer">Q3</a></td>
<td align="center"><a href="#4-what-is-the-most-purchased-item-on-the-menu-and-how-many-times-was-it-purchased-by-all-customers">Q4</a></td>
<td align="center"><a href="#5-which-item-was-the-most-popular-for-each-customer">Q5</a></td>
</tr>
<tr>
<td align="center"><a href="#6-which-item-was-purchased-first-by-the-customer-after-they-became-a-member">Q6</a></td>
<td align="center"><a href="#7-which-item-was-purchased-just-before-the-customer-became-a-member">Q7</a></td>
<td align="center"><a href="#8-what-is-the-total-items-and-amount-spent-for-each-member-before-they-became-a-member">Q8</a></td>
<td align="center"><a href="#9-if-each-1-spent-equates-to-10-points-and-sushi-has-a-2x-points-multiplier-how-many-points-would-each-customer-have">Q9</a></td>
<td align="center"><a href="#10-in-the-first-week-after-a-customer-joins-the-program-including-their-join-date-they-earn-2x-points-on-all-items-not-just-sushi-what-are-the-total-points-for-a-and-b-by-the-end-of-january">Q10</a></td>
<td align="center"><a href="#bonus-rank-all-the-things">Bonus</a></td>
</tr>
</table>

<p align="center"><img src="./images/Image1.png" width="400" alt="Danny's Diner"></p>

## ERD

```mermaid
erDiagram
    MENU ||--o{ SALES : "ordered in"
    MEMBERS ||--o{ SALES : "placed by"

    MENU {
        int product_id PK
        string product_name
        int price
    }
    SALES {
        string customer_id FK
        date order_date
        int product_id FK
    }
    MEMBERS {
        string customer_id PK
        date join_date
    }
```

## Setup: a materialized view for the recurring join

Every question below needs `menu` (for `product_name`, `price`) and `members` (for `join_date`) joined to `sales`. One materialized view, `sales_menu_members`, does that join once. Every query after this just selects from it.

```sql
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
```

**Why a materialized view, not a plain view:** BigQuery materialized views can only reference base tables directly. No nested views, no window functions, no `ORDER BY`, restricted join patterns. This join fits inside those limits.

**Honest caveat:** this is a static 15-row dataset. It never changes, so the refresh never triggers. No real performance win over a plain view here, just extra storage. Used it anyway to show the pattern correctly.

## Questions

### 1. What is the total amount each customer spent at the restaurant?

```sql
SELECT
  customer_id,
  SUM(price) AS total_amount
FROM `dannys_diner.sales_menu_members`
GROUP BY customer_id
ORDER BY customer_id;
```

| customer_id | total_amount |
|---|---|
| A | 76 |
| B | 74 |
| C | 36 |

**Result:** A and B spend roughly the same ($76 vs $74), C spends about half. Build the loyalty program around A/B's habits, C isn't the target customer yet.

### 2. How many days has each customer visited the restaurant?

```sql
SELECT
  customer_id,
  COUNT(DISTINCT order_date) AS visit_count
FROM `dannys_diner.sales_menu_members`
GROUP BY customer_id
ORDER BY customer_id;
```

| customer_id | visit_count |
|---|---|
| A | 4 |
| B | 6 |
| C | 2 |

**Result:** B visits 6 times to A's 4, but they spend about the same total, B just spends less per visit. A frequency-based reward would favor B; a spend-based one would favor A, worth deciding which behavior to reward.

### 3. What was the first item from the menu purchased by each customer?

```sql
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
```

| customer_id | product_name | order_date |
|---|---|---|
| A | sushi | 2021-01-01 |
| B | curry | 2021-01-01 |
| C | ramen | 2021-01-01 |

**Result:** all 3 customers' first orders were different dishes (sushi, curry, ramen). No single item drives first visits, so a "first order free" promo shouldn't be built around one dish.

**The tie:** A ordered sushi and curry both on 2021-01-01. C ordered ramen twice on the same day. No natural tiebreaker exists in the data.

**Two options considered:**
- `ROW_NUMBER()` + `ORDER BY order_date, product_id`: one deterministic answer, but the tiebreak (lowest `product_id` wins) is arbitrary, not a real signal of order.
- `DENSE_RANK()`: shows all tied rows, more honest, but returns multiple rows per customer.

**Went with:** `ROW_NUMBER()` + the tiebreak. One deterministic answer beats exposing the tie.

### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

```sql
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
```

| product_name | order_count |
|---|---|
| ramen | 8 |

**Result:** ramen leads with 8 orders, more than sushi and curry combined. Keep ramen stocked first if supply ever gets tight.

### 5. Which item was the most popular for each customer?

```sql
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
```

| customer_id | product_name | purchase_count |
|---|---|---|
| A | ramen | 3 |
| B | sushi | 2 |
| B | curry | 2 |
| B | ramen | 2 |
| C | ramen | 3 |

**Result:** ramen is the clear favorite for A and C, but B is split evenly across all three dishes. A single "recommended for you" item won't work for B.

### 6. Which item was purchased first by the customer after they became a member?

```sql
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
```

| customer_id | product_name |
|---|---|
| A | curry |
| B | sushi |

C never joined the loyalty program, so C has no rows here.

**Result:** neither A nor B ordered their own favorite dish as their first purchase after joining. Membership shifts what people try, not just how often they show up, worth testing a "welcome dish" recommendation.

### 7. Which item was purchased just before the customer became a member?

```sql
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
```

| customer_id | product_name |
|---|---|
| A | sushi |
| B | sushi |

**Result:** both A and B ordered sushi right before joining. Small sample, but worth testing sushi as a signup trigger in a follow-up promo.

### 8. What is the total items and amount spent for each member before they became a member?

```sql
SELECT
  customer_id,
  COUNT(*) AS order_count,
  SUM(price) AS total_amount
FROM `dannys_diner.sales_menu_members`
WHERE order_date < join_date
GROUP BY customer_id
ORDER BY customer_id;
```

| customer_id | order_count | total_amount |
|---|---|---|
| A | 2 | 25 |
| B | 3 | 40 |

**Result:** both A and B were already ordering multiple times before they joined (A: 2 orders/$25, B: 3 orders/$40). The program rewards existing loyalty, it isn't what's creating it, so acquisition and retention need separate strategies.

### 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier, how many points would each customer have?

```sql
SELECT
  customer_id,
  SUM(CASE
    WHEN product_name = 'sushi' THEN price*20
    ELSE price*10
  END) AS total_points
FROM `dannys_diner.sales_menu_members`
GROUP BY customer_id
ORDER BY customer_id;
```

| customer_id | total_points |
|---|---|
| A | 860 |
| B | 940 |
| C | 360 |

**Result:** B ends up with more points than A (940 vs 860) despite spending less overall, the sushi multiplier is doing the work. If Danny wants points to track actual spend, the multiplier needs a cap.

### 10. In the first week after a customer joins the program (including their join date), they earn 2x points on all items, not just sushi. What are the total points for A and B by the end of January?

```sql
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
```

| customer_id | total_points |
|---|---|
| A | 1370 |
| B | 820 |

C is excluded. C never joined, and this question only applies to members.

**Result:** the first-week bonus flips the leaderboard again, A jumps to 1,370 points against B's 820. The bonus is effective at driving early engagement, but it's also volatile enough to swing rankings on its own.

## Bonus: Rank All The Things

Ranking of customer products, but no ranking for purchases made before someone became a member. Those get `NULL`.

```sql
SELECT
  *,
  CASE
    WHEN is_member = 'Y' THEN DENSE_RANK()
      OVER (PARTITION BY customer_id, is_member ORDER BY order_date)
    ELSE NULL
  END AS ranking
FROM `dannys_diner.sales_menu_members`;
```

**Result:** one table with pre-member orders ranked separately from member orders. Gives a clean base for any future loyalty analysis without rebuilding the join.

## Full script

Runnable end-to-end version of everything above: [`solution.sql`](./solution.sql)
