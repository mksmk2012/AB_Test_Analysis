-- ============================================================
-- A/B Test Analysis: dataset for z-tests and Tableau
-- Platform: BigQuery
-- Output grain: date, country, device, continent, channel,
--               test, test_group, event_name -> value
-- event_name values: session, session_with_orders,
--                    new_account and checkout funnel events
--                    (begin_checkout, add_shipping_info, add_payment_info, ...)
-- ============================================================

WITH session_info AS (
  -- Sessions that took part in an A/B test, with their attributes
  SELECT
    s.date,
    s.ga_session_id,
    sp.country,
    sp.device,
    sp.continent,
    sp.channel,
    ab.test,
    ab.test_group
  FROM `DA.ab_test` ab
  JOIN `DA.session` s
    ON ab.ga_session_id = s.ga_session_id
  JOIN `DA.session_params` sp
    ON sp.ga_session_id = ab.ga_session_id
),

session_with_orders AS (
  -- Sessions that ended with an order
  SELECT
    si.date,
    si.country,
    si.device,
    si.continent,
    si.channel,
    si.test,
    si.test_group,
    COUNT(DISTINCT o.ga_session_id) AS session_with_orders
  FROM `DA.order` o
  JOIN session_info si
    ON o.ga_session_id = si.ga_session_id
  GROUP BY
    si.date, si.country, si.device, si.continent,
    si.channel, si.test, si.test_group
),

events AS (
  -- Funnel events (begin_checkout, add_shipping_info, add_payment_info, ...)
  -- NOTE: COUNT(ep.ga_session_id) counts events. To count sessions
  -- with at least one event, use COUNT(DISTINCT ep.ga_session_id).
  SELECT
    si.date,
    si.country,
    si.device,
    si.continent,
    si.channel,
    si.test,
    si.test_group,
    ep.event_name,
    COUNT(ep.ga_session_id) AS event_cnt
  FROM `DA.event_params` ep
  JOIN session_info si
    ON ep.ga_session_id = si.ga_session_id
  GROUP BY
    si.date, si.country, si.device, si.continent,
    si.channel, si.test, si.test_group, ep.event_name
),

session AS (
  -- Total sessions per group (denominator for conversion rates)
  SELECT
    si.date,
    si.country,
    si.device,
    si.continent,
    si.channel,
    si.test,
    si.test_group,
    COUNT(DISTINCT si.ga_session_id) AS session_cnt
  FROM session_info si
  GROUP BY
    si.date, si.country, si.device, si.continent,
    si.channel, si.test, si.test_group
),

account AS (
  -- Sessions in which a new account was created
  SELECT
    si.date,
    si.country,
    si.device,
    si.continent,
    si.channel,
    si.test,
    si.test_group,
    COUNT(DISTINCT acs.ga_session_id) AS new_account
  FROM `DA.account_session` acs
  JOIN session_info si
    ON acs.ga_session_id = si.ga_session_id
  GROUP BY
    si.date, si.country, si.device, si.continent,
    si.channel, si.test, si.test_group
)

-- Final dataset: all metrics stacked into one table (long format)
SELECT
  date, country, device, continent, channel, test, test_group,
  'session_with_orders' AS event_name,
  session_with_orders   AS value
FROM session_with_orders

UNION ALL

SELECT
  date, country, device, continent, channel, test, test_group,
  event_name,
  event_cnt AS value
FROM events

UNION ALL

SELECT
  date, country, device, continent, channel, test, test_group,
  'session'   AS event_name,
  session_cnt AS value
FROM session

UNION ALL

SELECT
  date, country, device, continent, channel, test, test_group,
  'new_account' AS event_name,
  new_account   AS value
FROM account;
