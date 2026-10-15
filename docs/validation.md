# Data validation

## Purpose and execution

Validation checks the modeled data against the raw source and checks key relationships before the curated outputs are trusted. The checks are defined in [`sql/03_validation.sql`](../sql/03_validation.sql) and run by [`src/validate.py`](../src/validate.py):

```bash
python -m src.validate
```

The command opens `data/nearshift.duckdb` in read-only mode, executes the SQL, and prints one row per check with the expected value, actual value, and `PASS` or `FAIL` status. It exits unsuccessfully if any check fails. The database must already contain the raw and modeled schemas and the `curated.monthly_sales` view, which the eligible-revenue check queries. Run ingestion, modeling, and curation before validation.

## Checks

| Check | What it verifies |
|---|---|
| Raw/model row counts | Orders, customers, products, order items, and payments retain the same number of rows in their modeled tables as in their raw tables. |
| Item value reconciliation | The sum of raw item prices, cast to decimal, matches the modeled `fact_order_items.price` sum. |
| Payment value reconciliation | The sum of raw payment values matches the modeled `fact_payments.payment_value` sum. |
| Eligible product revenue reconciliation | Raw item prices for orders whose status is not `canceled` match the sum of `curated.monthly_sales.product_revenue`. |
| Orders without customers | Every modeled order's `customer_id` resolves to `modeled.dim_customers`. |
| Items without orders or products | Every modeled item resolves to a modeled order and product. |
| Payments without orders | Every modeled payment resolves to a modeled order. |

Monetary reconciliations use an absolute difference strictly below 0.01. A missing value that makes a comparison unknown does not pass: the final status is `FAIL` unless the condition evaluates to true.

## Latest run

The validation suite completed successfully: all 12 checks passed.

| Reconciliation | Result |
|---|---:|
| Customers | 99,441 rows |
| Products | 32,951 rows |
| Orders | 99,441 rows |
| Order items | 112,650 rows |
| Payments | 103,886 rows |
| Raw vs. modeled item value | 13,591,643.70 |
| Raw vs. modeled payment value | 16,008,872.12 |
| Raw vs. curated eligible product revenue | 13,496,408.43 |

All four referential-integrity checks returned zero orphan records. Monetary amounts are expressed in the source dataset's units; no currency conversion was applied.

## Additional data quality findings

* Missing delivery timestamps: 2,965 orders have no customer delivery timestamp. Eight of these are marked delivered; they are excluded from the on-time delivery metric because the actual delivery date is unavailable.

* Canceled orders with delivery dates: Six canceled orders contain delivery-related timestamps. Their source values are preserved, and canceled orders are excluded from commercial metrics based on their status.

* Missing product weights: Two products have a null product_weight_g value after casting. These values are not imputed.

* Monetary fields: No null values were found after casting item prices, freight values, or payment values in the modeled tables.

* Key uniqueness: Separate checks found no duplicate keys at the declared grain of the five modeled tables. These checks were performed separately and are not included in the 12 automated validation checks.

* Timestamps: Source timestamps are used as stored, without explicit timezone conversion or UTC normalization.

## Scope and interpretation

These are reconciliation and referential-integrity checks, not a complete data-quality audit. They do not test uniqueness of modeled keys, timestamp validity, completeness of every source field, or business plausibility. The row-count checks can still pass when values fail to cast in the modeled layer; inspect the SQL casts and source data if a wider quality assessment is needed.

The eligible-revenue check uses the same status predicate and item-level revenue basis as `curated.monthly_sales`, so canceled orders are excluded and freight is not included. SQL's `<> 'canceled'` predicate also excludes rows with a null status.
