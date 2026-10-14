-- 1. Monthly MRR bridge, churn, GRR / NRR
WITH m AS (
 SELECT month,SUM(mrr_start) AS opening_mrr,SUM(new_mrr) AS new_mrr,
        SUM(expansion_mrr) AS expansion_mrr,SUM(contraction_mrr) AS contraction_mrr,
        SUM(churn_mrr) AS churn_mrr,SUM(mrr_end) AS ending_mrr,
        SUM(churned_customers) AS churned,SUM(new_customers) AS new_customers,
        SUM(CASE WHEN mrr_start>0 THEN 1 ELSE 0 END) AS opening_customers
 FROM fact_subscription_monthly GROUP BY month
)
SELECT month,opening_mrr,new_mrr,expansion_mrr,contraction_mrr,churn_mrr,ending_mrr,
       ROUND(100.0*churned/NULLIF(opening_customers,0),2) AS customer_churn_pct,
       ROUND(100.0*(opening_mrr-contraction_mrr-churn_mrr)/NULLIF(opening_mrr,0),2) AS grr_pct,
       ROUND(100.0*(opening_mrr+expansion_mrr-contraction_mrr-churn_mrr)/NULLIF(opening_mrr,0),2) AS nrr_pct
FROM m ORDER BY month;

-- 2. Monthly plan mix (ending MRR of active subscribers)
SELECT month,p.plan_name,COUNT(*) AS active_customers,SUM(mrr_end) AS ending_mrr
FROM fact_subscription_monthly f JOIN dim_plans p USING(plan_id)
WHERE f.active_end=1 GROUP BY month,p.plan_id ORDER BY month,p.monthly_price;

-- 3. Churn by acquisition channel
SELECT c.acquisition_channel,SUM(f.churned_customers) AS total_churns,
       SUM(CASE WHEN f.mrr_start>0 THEN 1 ELSE 0 END) AS customer_months_at_risk,
       ROUND(100.0*SUM(f.churned_customers)/NULLIF(SUM(CASE WHEN f.mrr_start>0 THEN 1 ELSE 0 END),0),2) AS monthly_exposure_churn_pct
FROM fact_subscription_monthly f JOIN dim_customers c USING(customer_id)
GROUP BY c.acquisition_channel ORDER BY monthly_exposure_churn_pct DESC;

-- 4. Cohort retention: active customers by months since acquisition
SELECT c.acquisition_month,
       ((CAST(substr(f.month,1,4) AS INTEGER)-CAST(substr(c.acquisition_month,1,4) AS INTEGER))*12
         + CAST(substr(f.month,6,2) AS INTEGER)-CAST(substr(c.acquisition_month,6,2) AS INTEGER)) AS cohort_age_months,
       SUM(f.active_end) AS retained_customers,
       (SELECT COUNT(*) FROM dim_customers c2 WHERE c2.acquisition_month=c.acquisition_month) AS cohort_size,
       ROUND(100.0*SUM(f.active_end)/(SELECT COUNT(*) FROM dim_customers c2 WHERE c2.acquisition_month=c.acquisition_month),2) AS retention_pct
FROM fact_subscription_monthly f JOIN dim_customers c USING(customer_id)
GROUP BY c.acquisition_month,cohort_age_months ORDER BY c.acquisition_month,cohort_age_months;
