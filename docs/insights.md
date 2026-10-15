# Business Insights

## Purpose

This report answers the five business questions using the views in the `curated` schema. The SQL definitions are maintained in `sql/02_curated.sql`, and the results can be reproduced with:

```bash
python -m src.insights
```

All monetary values are expressed in the source dataset's units. Product revenue is based on item prices, excludes canceled orders, and does not include freight. No currency conversion has been applied.

## 1. Monthly revenue

**Finding:** November 2017 had the highest monthly product revenue in the dataset, at **1,003,862.14**, across 7,421 orders.

Revenue increased substantially as monthly order volume grew through 2017 and early 2018. Monthly revenue reflects both the number of orders and the value of products purchased; it should not be interpreted as average order value.

**Business implication:** Revenue planning should consider order volume and order value separately to understand what drives changes in total sales.

## 2. Average order value trend

**Definition:** Monthly product revenue divided by the number of distinct non-canceled orders represented in order-item records. Freight is excluded.

**Finding:** Monthly AOV was **152.60** in January 2017 and **135.27** in November 2017, the highest-revenue month. During 2018, AOV varied across months rather than following a consistent upward trend.

**Business implication:** Higher total revenue does not necessarily mean customers are spending more per order. Monitoring AOV alongside order volume provides a clearer view of sales performance.

Months with very few orders, including September 2016, December 2016, and September 2018, should be interpreted cautiously.

## 3. Customer repeat-purchase rate

**Definition:** Customers with at least two distinct non-canceled orders divided by the distinct customers represented in the repeat-rate view. Customer identity is based on `customer_unique_id`.

**Finding:** The view reports **2,924 repeat customers out of 95,560 customers**, giving a repeat-purchase rate of approximately **3.06%**.

**Business implication:** Repeat purchasing is a useful area for further investigation. Before drawing conclusions about retention, validate the observation window and consider that customers acquired near the end of the dataset have had less time to make another purchase.

## 4. Top product categories

**Definition:** Product categories ranked by item-price revenue from non-canceled orders.

**Finding:** `health_beauty` ranked first, with **1,255,695.13** in product revenue. It was followed by `watches_gifts` at **1,198,185.21** and `bed_bath_table` at **1,035,964.06**.

**Business implication:** These categories are candidates for deeper analysis of product assortment, inventory, and merchandising. Revenue ranking alone does not establish profitability because costs and margins are not included.

## 5. On-time delivery performance

**Definition:** The percentage of delivered orders whose actual customer-delivery timestamp is on or before the estimated delivery timestamp. Orders missing either timestamp are excluded.

**Finding:** On-time delivery performance varied by purchase month. The rate was **85.69%** in November 2017, **84.01%** in February 2018, and **78.64%** in March 2018. March 2018 was the lowest month among those with reported results.

**Business implication:** These months merit further investigation into logistics and delivery operations. The observed trend alone does not establish the cause of delays.

Eight orders marked `delivered` lack an actual customer-delivery timestamp and are excluded from this KPI.

## Methodological notes

- Monthly metrics use the purchase timestamp as stored in the source data; no explicit timezone conversion is applied.
- Canceled orders are excluded from commercial metrics based on `order_status`.
- Product revenue and payment value are separate measures and are not added together.
- The dataset contains no explicit refund ledger in the modeled sources used for this report.
- These findings are descriptive and do not establish causation.