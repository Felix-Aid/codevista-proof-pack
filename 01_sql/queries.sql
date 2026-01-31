/* =========================================================
   Banking Analytics SQL Proof Pack (MySQL) — bank database
   Tables: tblCUSTOMER, tblACCOUNT, tblTRANSACTION, tblBRANCH, tblSTAFF
   Author: Felix (Portfolio)
   ========================================================= */

USE bank;

-- ---------------------------------------------------------
-- 1) DATA QUALITY CHECKS
-- ---------------------------------------------------------

/* 1.1 Row counts */
SELECT 'tblCUSTOMER' AS table_name, COUNT(*) AS row_count FROM tblCUSTOMER
UNION ALL
SELECT 'tblACCOUNT', COUNT(*) FROM tblACCOUNT
UNION ALL
SELECT 'tblTRANSACTION', COUNT(*) FROM tblTRANSACTION
UNION ALL
SELECT 'tblBRANCH', COUNT(*) FROM tblBRANCH
UNION ALL
SELECT 'tblSTAFF', COUNT(*) FROM tblSTAFF;

/* 1.2 Null checks (critical columns) */
SELECT
  SUM(cusid IS NULL) AS null_cusid,
  SUM(sname IS NULL) AS null_sname,
  SUM(fname IS NULL) AS null_fname,
  SUM(dob IS NULL) AS null_dob
FROM tblCUSTOMER;

SELECT
  SUM(accnu IS NULL) AS null_accnu,
  SUM(cusid IS NULL) AS null_cusid_fk,
  SUM(acctype IS NULL) AS null_acctype,
  SUM(amount IS NULL) AS null_amount
FROM tblACCOUNT;

SELECT
  SUM(tranid IS NULL) AS null_tranid,
  SUM(accnu IS NULL) AS null_accnu_fk,
  SUM(dot IS NULL) AS null_dot,
  SUM(tranamount IS NULL) AS null_tranamount,
  SUM(staffid IS NULL) AS null_staffid
FROM tblTRANSACTION;

/* 1.3 Duplicate checks (primary keys should be unique) */
SELECT cusid, COUNT(*) AS cnt
FROM tblCUSTOMER
GROUP BY cusid
HAVING COUNT(*) > 1;

SELECT accnu, COUNT(*) AS cnt
FROM tblACCOUNT
GROUP BY accnu
HAVING COUNT(*) > 1;

SELECT tranid, COUNT(*) AS cnt
FROM tblTRANSACTION
GROUP BY tranid
HAVING COUNT(*) > 1;

SELECT staffid, COUNT(*) AS cnt
FROM tblSTAFF
GROUP BY staffid
HAVING COUNT(*) > 1;

SELECT bcode, COUNT(*) AS cnt
FROM tblBRANCH
GROUP BY bcode
HAVING COUNT(*) > 1;

/* 1.4 Range checks */
-- Transactions with non-positive amounts (often invalid; depends on design)
SELECT *
FROM tblTRANSACTION
WHERE tranamount <= 0;

-- Accounts with negative balance/amount (should usually not happen unless allowed)
SELECT *
FROM tblACCOUNT
WHERE amount < 0;

-- ---------------------------------------------------------
-- 2) CORE KPIs (DESCRIPTIVE ANALYTICS)
-- ---------------------------------------------------------

/* 2.1 Totals */
SELECT
  (SELECT COUNT(*) FROM tblCUSTOMER) AS total_customers,
  (SELECT COUNT(*) FROM tblACCOUNT) AS total_accounts,
  (SELECT COUNT(*) FROM tblTRANSACTION) AS total_transactions,
  (SELECT COUNT(*) FROM tblSTAFF) AS total_staff,
  (SELECT COUNT(*) FROM tblBRANCH) AS total_branches;

/* 2.2 Average transaction amount */
SELECT AVG(tranamount) AS avg_transaction_amount
FROM tblTRANSACTION;

/* 2.3 Transaction type distribution */
SELECT
  trantype,
  COUNT(*) AS tx_count,
  SUM(tranamount) AS total_amount,
  AVG(tranamount) AS avg_amount
FROM tblTRANSACTION
GROUP BY trantype
ORDER BY total_amount DESC;

/* 2.4 Active accounts in last 60 days */
SELECT
  COUNT(DISTINCT accnu) AS active_accounts_last_60d
FROM tblTRANSACTION
WHERE dot >= (CURRENT_DATE - INTERVAL 60 DAY);

/* 2.5 Active customers in last 60 days (via accounts) */
SELECT
  COUNT(DISTINCT a.cusid) AS active_customers_last_60d
FROM tblTRANSACTION t
JOIN tblACCOUNT a ON a.accnu = t.accnu
WHERE t.dot >= (CURRENT_DATE - INTERVAL 60 DAY);

-- ---------------------------------------------------------
-- 3) TRENDS (MONTHLY)
-- ---------------------------------------------------------

/* 3.1 Monthly transaction count */
SELECT
  DATE_FORMAT(dot, '%Y-%m-01') AS month_start,
  COUNT(*) AS tx_count
FROM tblTRANSACTION
GROUP BY DATE_FORMAT(dot, '%Y-%m-01')
ORDER BY month_start;

/* 3.2 Monthly totals by transaction type */
SELECT
  DATE_FORMAT(dot, '%Y-%m-01') AS month_start,
  trantype,
  COUNT(*) AS tx_count,
  SUM(tranamount) AS total_amount
FROM tblTRANSACTION
GROUP BY DATE_FORMAT(dot, '%Y-%m-01'), trantype
ORDER BY month_start, total_amount DESC;

-- ---------------------------------------------------------
-- 4) CUSTOMER / ACCOUNT / STAFF / BRANCH INSIGHTS
-- ---------------------------------------------------------

/* 4.1 Top 10 customers by total transaction amount */
SELECT
  a.cusid,
  SUM(t.tranamount) AS total_amount,
  COUNT(*) AS tx_count
FROM tblTRANSACTION t
JOIN tblACCOUNT a ON a.accnu = t.accnu
GROUP BY a.cusid
ORDER BY total_amount DESC
LIMIT 10;

/* 4.2 Accounts per customer */
SELECT
  cusid,
  COUNT(*) AS accounts_count,
  SUM(amount) AS total_account_balance
FROM tblACCOUNT
GROUP BY cusid
ORDER BY accounts_count DESC, total_account_balance DESC;

/* 4.3 Transaction volume by staff */
SELECT
  t.staffid,
  COUNT(*) AS tx_count,
  SUM(t.tranamount) AS total_amount,
  AVG(t.tranamount) AS avg_amount
FROM tblTRANSACTION t
GROUP BY t.staffid
ORDER BY total_amount DESC;

/* 4.4 Branch performance: transactions by branch (via staff -> branch) */
SELECT
  b.bcode,
  b.bname,
  COUNT(*) AS tx_count,
  SUM(t.tranamount) AS total_amount
FROM tblTRANSACTION t
JOIN tblSTAFF s ON s.staffid = t.staffid
JOIN tblBRANCH b ON b.bcode = s.bcode
GROUP BY b.bcode, b.bname
ORDER BY total_amount DESC;

-- ---------------------------------------------------------
-- 5) REPORTING TABLE (CTE) — Monthly KPI table (MySQL 8+)
-- ---------------------------------------------------------

WITH monthly_kpis AS (
  SELECT
    DATE_FORMAT(dot, '%Y-%m-01') AS month_start,
    COUNT(*) AS tx_count,
    COUNT(DISTINCT accnu) AS active_accounts,
    SUM(tranamount) AS total_amount,
    AVG(tranamount) AS avg_tx_amount
  FROM tblTRANSACTION
  GROUP BY DATE_FORMAT(dot, '%Y-%m-01')
)
SELECT
  month_start,
  tx_count,
  active_accounts,
  total_amount,
  avg_tx_amount
FROM monthly_kpis
ORDER BY month_start;

-- ---------------------------------------------------------
-- 6) INTERMEDIATE TOUCH: Top 10 customers per month (Window function)
-- ---------------------------------------------------------

WITH customer_monthly AS (
  SELECT
    DATE_FORMAT(t.dot, '%Y-%m-01') AS month_start,
    a.cusid,
    SUM(t.tranamount) AS total_amount
  FROM tblTRANSACTION t
  JOIN tblACCOUNT a ON a.accnu = t.accnu
  GROUP BY DATE_FORMAT(t.dot, '%Y-%m-01'), a.cusid
),
ranked AS (
  SELECT
    month_start,
    cusid,
    total_amount,
    DENSE_RANK() OVER (PARTITION BY month_start ORDER BY total_amount DESC) AS rnk
  FROM customer_monthly
)
SELECT *
FROM ranked
WHERE rnk <= 10
ORDER BY month_start, rnk;
