SELECT
  date,
  user_country_code AS country_code,
  user_id,
  r.state_bouquet_size AS most_recent_product_size,
  LAG(r.state_bouquet_size)
    OVER (PARTITION BY user_id ORDER BY date ASC) AS previous_size,
  LEAD(r.state_bouquet_size)
    OVER (PARTITION BY user_id ORDER BY date ASC) AS next_size,
  state_active,
  state_alive,
  state_segment,
  previous_different_size
FROM
  `bloomon-bi-prod.dh__bi__v1.bi__bloomon_registry` r
LEFT JOIN
(
  SELECT
    state_bouquet_size,
    user_id,
    date,
    LEAD(state_bouquet_size) OVER (PARTITION BY user_id ORDER BY rnk ASC)
      AS previous_different_size
  FROM (
    SELECT
      *,
      RANK() OVER (PARTITION BY user_id ORDER BY date DESC) AS rnk
    FROM (
      SELECT
        MAX(date) AS date, user_id, state_bouquet_size
      FROM
        `bloomon-bi-prod.dh__bi__v1.bi__bloomon_registry`
    WHERE
        date <= DATE_TRUNC(CURRENT_DATE(), WEEK(SUNDAY))
        AND EXTRACT(DAYOFWEEK FROM date) = 1 -- SUNDAY
      GROUP BY
        user_id, state_bouquet_size
    )
  )
) p USING(user_id, date)
WHERE
  date <= DATE_TRUNC(CURRENT_DATE(), WEEK(SUNDAY))
  AND EXTRACT(DAYOFWEEK FROM date) = 1 -- SUNDAY
Limit 1000
