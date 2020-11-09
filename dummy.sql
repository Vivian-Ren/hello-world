SELECT
  *,
  purchase_credited - IFNULL(payment_refunded, 0) AS purchase_credited_net,
  FORMAT_DATE("%E4Y-%m", purchase_date) AS year_month,
  IF(redemption_date IS NULL, FALSE, TRUE) AS is_redeemed
-- Purchases
FROM (
  SELECT
    event_date AS purchase_date,
    invoice_id,
    order_id,
    user_id,
    payment_credited AS purchase_credited,
    country_code
  FROM
    `bloomon-bi-prod.dh__bi__v1.bi__payment_events`
  WHERE
    event='authorised'
    AND payment_src = 'money'
    AND payment_dest = 'code_a') purchase
-- Redemptions
LEFT JOIN (
  SELECT
    ANY_VALUE(event_date) AS redemption_date,
    invoice_id,
    SUM(payment_debited) AS redemption_debited
  FROM
    `bloomon-bi-prod.dh__bi__v1.bi__payment_events`
  WHERE
    event='authorised'
    AND payment_src = 'code_a'
    AND payment_dest = 'credit_a'
  GROUP BY invoice_id) redemption
USING
  (invoice_id)
-- Refunds
LEFT JOIN (
  SELECT
    ANY_VALUE(event_date) AS refund_date,
    invoice_id,
    SUM(payment_debited) AS payment_refunded
  FROM
    `bloomon-bi-prod.dh__bi__v1.bi__payment_events`
  WHERE
    event='refunded'
    AND payment_src = 'code_a'
    AND payment_dest = 'money'
  GROUP BY invoice_id) refund
USING
  (invoice_id)
