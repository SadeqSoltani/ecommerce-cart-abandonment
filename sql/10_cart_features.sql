-- Spine: cart events + label
DROP TABLE IF EXISTS cart_features;
CREATE TABLE cart_features AS
SELECT
    c.session_id, c.visitorid, c.itemid,
    c.timestamp_ms AS cart_ts, c.event_time AS cart_time,
    c.event_hour, c.event_dow, c.categoryid, c.available,
    CASE WHEN EXISTS (
        SELECT 1 FROM events_sessionized AS t
        WHERE t.session_id = c.session_id AND t.itemid = c.itemid
          AND t.event = 'transaction' AND t.timestamp_ms >= c.timestamp_ms
    ) THEN 1 ELSE 0 END AS purchased
FROM events_sessionized AS c
WHERE c.event = 'addtocart';

-- 1: session context (events strictly before the cart)
ALTER TABLE cart_features ADD COLUMN IF NOT EXISTS prior_events INT;
ALTER TABLE cart_features ADD COLUMN IF NOT EXISTS prior_views INT;
ALTER TABLE cart_features ADD COLUMN IF NOT EXISTS prior_carts INT;
ALTER TABLE cart_features ADD COLUMN IF NOT EXISTS prior_unique_items INT;
ALTER TABLE cart_features ADD COLUMN IF NOT EXISTS prior_unique_cats INT;
ALTER TABLE cart_features ADD COLUMN IF NOT EXISTS mins_into_session NUMERIC;
UPDATE cart_features AS cf
SET prior_events = s.prior_events, prior_views = s.prior_views,
    prior_carts = s.prior_carts, prior_unique_items = s.prior_unique_items,
    prior_unique_cats = s.prior_unique_cats, mins_into_session = s.mins_into_session
FROM (
    SELECT c.session_id, c.itemid, c.cart_ts,
        COUNT(*) AS prior_events,
        COUNT(*) FILTER (WHERE e.event = 'view') AS prior_views,
        COUNT(*) FILTER (WHERE e.event = 'addtocart') AS prior_carts,
        COUNT(DISTINCT e.itemid) AS prior_unique_items,
        COUNT(DISTINCT e.categoryid) AS prior_unique_cats,
        ROUND(EXTRACT(EPOCH FROM (to_timestamp(c.cart_ts/1000)
            - to_timestamp(MIN(e.timestamp_ms)/1000)))/60.0, 2) AS mins_into_session
    FROM cart_features AS c
    JOIN events_sessionized AS e
      ON e.session_id = c.session_id AND e.timestamp_ms < c.cart_ts
    GROUP BY c.session_id, c.itemid, c.cart_ts
) AS s
WHERE cf.session_id = s.session_id AND cf.itemid = s.itemid AND cf.cart_ts = s.cart_ts;

-- 2: this-item engagement before the cart
ALTER TABLE cart_features ADD COLUMN IF NOT EXISTS item_prior_views INT;
ALTER TABLE cart_features ADD COLUMN IF NOT EXISTS mins_since_first_view NUMERIC;
UPDATE cart_features AS cf
SET item_prior_views = s.item_prior_views, mins_since_first_view = s.mins_since_first_view
FROM (
    SELECT c.session_id, c.itemid, c.cart_ts,
        COUNT(*) FILTER (WHERE e.event = 'view') AS item_prior_views,
        ROUND(EXTRACT(EPOCH FROM (to_timestamp(c.cart_ts/1000)
            - to_timestamp(MIN(e.timestamp_ms)/1000)))/60.0, 2) AS mins_since_first_view
    FROM cart_features AS c
    JOIN events_sessionized AS e
      ON e.session_id = c.session_id AND e.itemid = c.itemid AND e.timestamp_ms < c.cart_ts
    GROUP BY c.session_id, c.itemid, c.cart_ts
) AS s
WHERE cf.session_id = s.session_id AND cf.itemid = s.itemid AND cf.cart_ts = s.cart_ts;

-- 3: item popularity  (AS-OF: views of this item anywhere, strictly before the cart)
ALTER TABLE cart_features ADD COLUMN IF NOT EXISTS item_popularity INT;
UPDATE cart_features AS cf
SET item_popularity = s.pop
FROM (
    SELECT c.session_id, c.itemid, c.cart_ts,
           COUNT(*) FILTER (WHERE e.event = 'view') AS pop
    FROM cart_features AS c
    JOIN events_sessionized AS e
      ON e.itemid = c.itemid AND e.timestamp_ms < c.cart_ts
    GROUP BY c.session_id, c.itemid, c.cart_ts
) AS s
WHERE cf.session_id = s.session_id AND cf.itemid = s.itemid AND cf.cart_ts = s.cart_ts;

-- Fill NULLs (carts with no qualifying prior events → 0)
UPDATE cart_features SET
    prior_events = COALESCE(prior_events,0), prior_views = COALESCE(prior_views,0),
    prior_carts = COALESCE(prior_carts,0), prior_unique_items = COALESCE(prior_unique_items,0),
    prior_unique_cats = COALESCE(prior_unique_cats,0), mins_into_session = COALESCE(mins_into_session,0),
    item_prior_views = COALESCE(item_prior_views,0), mins_since_first_view = COALESCE(mins_since_first_view,0),
    item_popularity = COALESCE(item_popularity,0);


-- Sanity check: base rate + feature population

SELECT
    COUNT(*)                          AS cart_rows,
    ROUND(AVG(purchased), 4)          AS purchase_rate,
    ROUND(AVG(prior_views), 2)        AS avg_prior_views,
    ROUND(AVG(item_prior_views), 2)   AS avg_item_prior_views,
    ROUND(AVG(item_popularity), 1)    AS avg_item_pop
FROM cart_features;