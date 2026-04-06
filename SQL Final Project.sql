# Cписок клиентов с непрерывной историей за год
# Клиент должен делать хотя бы 1 покупку каждый месяц за период 06.2015–05.2016
WITH monthly_clients AS (
    SELECT 
        ID_client,
        DATE_FORMAT(date_new, '%Y-%m') AS month_num
    FROM transactions
    WHERE date_new >= '2015-06-01'
      AND date_new < '2016-06-01'
    GROUP BY ID_client, DATE_FORMAT(date_new, '%Y-%m')
),
continuous_clients AS (
    SELECT 
        ID_client
    FROM monthly_clients
    GROUP BY ID_client
    HAVING COUNT(DISTINCT month_num) = 12
)
SELECT
    t.ID_client,
    ROUND(AVG(t.Sum_payment), 2) AS avg_check,     
    ROUND(SUM(t.Sum_payment) / 12, 2) AS avg_monthly_sum,
    COUNT(*) AS total_operations
FROM transactions t
JOIN continuous_clients c
    ON t.ID_client = c.ID_client
WHERE t.date_new >= '2015-06-01'
  AND t.date_new < '2016-06-01'
GROUP BY t.ID_client;


# Средняя сумма чека в месяц
SELECT 
    DATE_FORMAT(date_new, '%Y-%m') AS month_num,
    ROUND(AVG(Sum_payment), 2) AS avg_check
FROM transactions
GROUP BY month_num
ORDER BY month_num;


# Количество всех операций в месяц
SELECT 
    DATE_FORMAT(date_new, '%Y-%m') AS month_num,
    COUNT(*) AS total_operations
FROM transactions
GROUP BY month_num
ORDER BY month_num;


# Количество активных клиентов по месяцам
SELECT 
    DATE_FORMAT(date_new, '%Y-%m') AS month_num,
    COUNT(DISTINCT ID_client) AS active_clients
FROM transactions
GROUP BY month_num
ORDER BY month_num;


# Доля операций и доля суммы по каждому месяцу от общего года
WITH monthly_stats AS (
    SELECT 
        DATE_FORMAT(date_new, '%Y-%m') AS month_num,
        COUNT(*) AS total_operations,
        SUM(Sum_payment) AS total_sum
    FROM transactions
    GROUP BY month_num
)
SELECT 
    month_num,
    total_operations,
    ROUND(total_operations * 100.0 / SUM(total_operations) OVER(), 2) AS operations_share_year,
    ROUND(total_sum * 100.0 / SUM(total_sum) OVER(), 2) AS revenue_share_year
FROM monthly_stats
ORDER BY month_num;


# % соотношение M / F / NA в каждом месяце + доля затрат
SELECT 
    DATE_FORMAT(t.date_new, '%Y-%m') AS month_num,
    COALESCE(c.Gender, 'NA') AS gender,
    COUNT(DISTINCT t.ID_client) AS clients,
    ROUND(SUM(t.Sum_payment), 2) AS total_spent,
    ROUND(
        COUNT(DISTINCT t.ID_client) * 100.0 /
        SUM(COUNT(DISTINCT t.ID_client)) OVER(
            PARTITION BY DATE_FORMAT(t.date_new, '%Y-%m')
        ),
        2
    ) AS gender_share_percent
FROM transactions t
LEFT JOIN customers c
    ON t.ID_client = c.Id_client
GROUP BY month_num, gender
ORDER BY month_num, gender;


# Возрастные группы клиентов за весь период (шаг 10 лет)
SELECT
    CASE
        WHEN Age IS NULL THEN 'NA'
        WHEN Age < 10 THEN '0-9'
        WHEN Age < 20 THEN '10-19'
        WHEN Age < 30 THEN '20-29'
        WHEN Age < 40 THEN '30-39'
        WHEN Age < 50 THEN '40-49'
        WHEN Age < 60 THEN '50-59'
        WHEN Age < 70 THEN '60-69'
        WHEN Age < 80 THEN '70-79'
        WHEN Age < 90 THEN '80-89'
        WHEN Age < 100 THEN '90-99'
    END AS age_group,
    SUM(t.Sum_payment) AS total_sum,
    COUNT(*) AS total_operations
FROM transactions t
LEFT JOIN customers c
    ON t.ID_client = c.Id_client
GROUP BY age_group
ORDER BY age_group;


# Возрастные группы поквартально
# Средний чек, количество операций и % от квартала
SELECT
    CONCAT(YEAR(date_new), '-Q', QUARTER(date_new)) AS quarter_num,
    CASE
        WHEN Age IS NULL THEN 'NA'
        WHEN Age < 10 THEN '0-9'
        WHEN Age < 20 THEN '10-19'
        WHEN Age < 30 THEN '20-29'
        WHEN Age < 40 THEN '30-39'
        WHEN Age < 50 THEN '40-49'
        WHEN Age < 60 THEN '50-59'
        WHEN Age < 70 THEN '60-69'
        WHEN Age < 80 THEN '70-79'
        WHEN Age < 90 THEN '80-89'
        WHEN Age < 100 THEN '90-99'
    END AS age_group,
    ROUND(AVG(Sum_payment), 2) AS avg_sum,
    COUNT(*) AS total_operations,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER(
            PARTITION BY CONCAT(YEAR(date_new), '-Q', QUARTER(date_new))
        ),
        2
    ) AS operation_share_percent
FROM transactions t
LEFT JOIN customers c
    ON t.ID_client = c.Id_client
GROUP BY quarter_num, age_group
ORDER BY quarter_num, age_group;