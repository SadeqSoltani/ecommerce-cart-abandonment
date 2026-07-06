-- Q1: how many visitors, how many events?

SELECT COUNT(DISTINCT visitorid) AS unique_visitors,
       COUNT(*)                  AS total_events
FROM raw_events;

--------------------------------------------------------------------------------------------

-- Q2: how many visitors exceed 1 / 5 / 10 events?

SELECT
    COUNT(*)                        AS total_visitors,
    COUNT(*) FILTER (WHERE n > 1)   AS more_than_1,
    COUNT(*) FILTER (WHERE n > 5)   AS more_than_5,
    COUNT(*) FILTER (WHERE n > 10)  AS more_than_10
FROM (
    SELECT visitorid, COUNT(*) AS n
    FROM raw_events
    GROUP BY visitorid
) AS visitor_counts;

--------------------------------------------------------------------------------------------

-- Q3: How many add-to-cart events exist?

SELECT COUNT(*) AS addtocart_events
FROM raw_events
WHERE event = 'addtocart';

-------------------------------------------------------------------------------------------------

-- Q4: How many carts are followed by a purchase of the SAME item by the SAME visitor (at any later time)?

SELECT COUNT(*) AS carts_followed_by_purchase
FROM raw_events AS cart
WHERE cart.event = 'addtocart'
  AND EXISTS (
        SELECT 1
        FROM raw_events AS txn
        WHERE txn.event = 'transaction'
          AND txn.visitorid    = cart.visitorid
          AND txn.itemid       = cart.itemid
          AND txn.timestamp_ms >= cart.timestamp_ms
  );

---------------------------------------------------------------------------------------------

-- Q5: Events-per-visitor distribution

SELECT
    MIN(n)                                          AS min_events,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY n) AS median,
    PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY n) AS p90,
    PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY n) AS p99,
    MAX(n)                                          AS max_events,
    AVG(n)                                          AS mean_events
FROM (
    SELECT visitorid, COUNT(*) AS n
    FROM raw_events
    GROUP BY visitorid
) AS visitor_counts;
