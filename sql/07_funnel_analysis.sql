
-- 1) Overall funnel
SELECT
    COUNT(*) FILTER (WHERE event = 'view')        AS views,
    COUNT(*) FILTER (WHERE event = 'addtocart')   AS carts,
    COUNT(*) FILTER (WHERE event = 'transaction') AS purchases,
    ROUND(100.0 * COUNT(*) FILTER (WHERE event = 'addtocart')
          / NULLIF(COUNT(*) FILTER (WHERE event = 'view'), 0), 2)      AS view_to_cart_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE event = 'transaction')
          / NULLIF(COUNT(*) FILTER (WHERE event = 'addtocart'), 0), 2) AS cart_to_purchase_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE event = 'transaction')
          / NULLIF(COUNT(*) FILTER (WHERE event = 'view'), 0), 2)      AS overall_conversion_pct
FROM events_sessionized;


-- 2) Funnel by day of week (0 = Sunday ... 6 = Saturday)
SELECT
    event_dow,
    COUNT(*) FILTER (WHERE event = 'view')        AS views,
    COUNT(*) FILTER (WHERE event = 'addtocart')   AS carts,
    COUNT(*) FILTER (WHERE event = 'transaction') AS purchases,
    ROUND(100.0 * COUNT(*) FILTER (WHERE event = 'addtocart')
          / NULLIF(COUNT(*) FILTER (WHERE event = 'view'), 0), 2)      AS view_to_cart_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE event = 'transaction')
          / NULLIF(COUNT(*) FILTER (WHERE event = 'addtocart'), 0), 2) AS cart_to_purchase_pct
FROM events_sessionized
GROUP BY event_dow
ORDER BY event_dow;


-- 3) Funnel by hour of day (UTC, 0-23; store's local tz unknown)
SELECT
    event_hour,
    COUNT(*) FILTER (WHERE event = 'view')        AS views,
    COUNT(*) FILTER (WHERE event = 'addtocart')   AS carts,
    COUNT(*) FILTER (WHERE event = 'transaction') AS purchases,
    ROUND(100.0 * COUNT(*) FILTER (WHERE event = 'addtocart')
          / NULLIF(COUNT(*) FILTER (WHERE event = 'view'), 0), 2)      AS view_to_cart_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE event = 'transaction')
          / NULLIF(COUNT(*) FILTER (WHERE event = 'addtocart'), 0), 2) AS cart_to_purchase_pct
FROM events_sessionized
GROUP BY event_hour
ORDER BY event_hour;


