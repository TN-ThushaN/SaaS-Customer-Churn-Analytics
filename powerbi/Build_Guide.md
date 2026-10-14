# Power BI build guide — SaaS Retention & Revenue BI

**100% synthetic B2B SaaS simulation.** Currency is illustrative USD.

1. Import `dim_plans.csv`, `dim_customers.csv`, and `fact_subscription_monthly.csv` and rename `Dim_Plans`, `Dim_Customers`, `Fact_Subscription_Monthly`.
2. Relationships: both dimensions connect one-to-many to the monthly fact by their ID (single-direction).
3. Month field is **YYYY-MM text** for easy chronological text sorting. For date intelligence, make a `MonthDate` column in Power Query using `Date.FromText([month] & "-01")` and a month-level date dimension. Choose a single month for headline stock-like KPIs.
4. Add all measures in `Measures.dax` one at a time. Format NRR/GRR/churn as %.
5. **Page 1: SaaS Executive KPI:** select a single month. Cards: Ending MRR, Active Customers, New MRR, Churned MRR, NRR %, Customer Churn %. Line chart: Ending MRR by month; waterfall: Opening MRR + New MRR + Expansion MRR − Contraction MRR − Churned MRR (use a disconnected bridge table if needed).
6. **Page 2: Retention & Growth:** monthly customer churn, acquisition channels, active users by plan, cohort age retention heatmap from `sql/02_business_queries.sql`.
7. **Critical metric note:** MRR is **semi-additive over time**; show latest MRR in KPI cards, never sum MRR across months. NRR excludes new revenue. Churn denominator is opening paid customers, not total accounts.

**MRR bridge identity per month:** Ending MRR = Opening MRR + New MRR + Expansion MRR − Contraction MRR − Churned MRR.
