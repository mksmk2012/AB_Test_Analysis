# A/B Test Analysis: Statistical Significance

Analysis of four A/B tests on an e-commerce checkout funnel. For each test, the control and experimental groups are compared on four conversion metrics using a two-proportion z-test.

**Tools:** BigQuery (SQL) · Python (pandas, NumPy, statsmodels) · Google Colab · Tableau

## Links

- [Tableau dashboard](https://public.tableau.com/views/Book1_17841370064470/Dashboard3?:language=en-US&publish=yes&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)
- [Data set](https://github.com/mksmk2012/AB_Test_Analysis/blob/main/results/ab_test_reslts%20-%20ab_test_reslts.csv)
- [Notebook](https://github.com/mksmk2012/AB_Test_Analysis/blob/main/Project_AB_test.ipynb)

## Project stages

1. **BigQuery.** Session, event, account and order data are joined with the A/B test assignment table into one dataset. Granularity: one row per date, country, device, continent, channel, test, test group and event.
2. **Python.** For each of the 4 tests and each of the 4 metrics, the conversion rates of the control and experimental groups are compared with a two-proportion z-test (α = 0.05).
3. **Tableau.** The results CSV is visualized on a dashboard with metric cards, a conversion rate comparison, a p-value chart and a test selector.

## Metrics

Conversion rate = number of events / number of sessions in the group.

| Metric | Source event |
|---|---|
| `add_payment_info` | `add_payment_info` |
| `add_shipping_info` | `add_shipping_info` |
| `begin_checkout` | `begin_checkout` |
| `new_accounts` | `new_account` |

Group 1 is the control, group 2 is the experimental variant. `metric_change` is the relative change of the experimental rate versus the control rate.

## Results

| Test | add_payment_info | add_shipping_info | begin_checkout | new_accounts |
|---|---|---|---|---|
| 1 | significant, +12.54% | significant, +6.56% | significant, +6.66% | not significant (-3.35%) |
| 2 | not significant | not significant | not significant | not significant |
| 3 | not significant | not significant | significant, -3.35% | not significant |
| 4 | not significant | not significant | significant, -2.35% | significant, -3.36% |

- **Test 1** is the only test with a clear positive effect: three checkout-funnel metrics increased significantly, while new accounts did not change significantly.
- **Test 2** shows no significant change in any metric.
- **Test 3** significantly decreased `begin_checkout`; the other metrics did not change significantly.
- **Test 4** significantly decreased `begin_checkout` and `new_accounts`.

**Recommendation:** roll out the variant from test 1, and reject the variants from tests 3 and 4, as they hurt key metrics. Test 2 is inconclusive and would need a larger sample or a different hypothesis.

## Limitations and next steps

- 16 hypotheses are tested at α = 0.05 without a multiple-comparison correction (e.g. Bonferroni or Benjamini–Hochberg). Results with p-values close to 0.05 should be treated with caution.
- Test 1 shows a non-significant decrease in `new_accounts` (-3.35%); worth monitoring after rollout.
- No power analysis or sample ratio mismatch check was performed.
- Event counts in SQL should be counted per distinct session so that each session contributes at most once to a conversion.

## Repository structure

```
A-B-Test-Analysis/
├── README.md
├── Project_AB_test.ipynb      # BigQuery query + z-tests
├── sql/
│   └── ab_test_dataset.sql    # the BigQuery query from the notebook
├── results/
│   └── ab_test_results.csv    # output used in Tableau
└── dashboard/
    └── dashboard.png          # dashboard screenshot
```

## How to run

1. Open `Project_AB_test.ipynb` in Google Colab.
2. Authenticate with Google (`auth.authenticate_user()`) and set your own BigQuery project in `bigquery.Client(project=...)`. The source tables (`DA.ab_test`, `DA.session`, `DA.session_params`, `DA.event_params`, `DA.order`, `DA.account_session`) must be available in that project.
3. Run all cells. The results are saved to `ab_test_results.csv`.
