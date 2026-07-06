
-- 1) Funnel by availability 
SELECT
    available,
    COUNT(*) FILTER (WHERE event = 'view')        AS views,
    COUNT(*) FILTER (WHERE event = 'addtocart')   AS carts,
    COUNT(*) FILTER (WHERE event = 'transaction') AS purchases,
    ROUND(100.0 * COUNT(*) FILTER (WHERE event = 'addtocart')
          / NULLIF(COUNT(*) FILTER (WHERE event = 'view'), 0), 2)      AS view_to_cart_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE event = 'transaction')
          / NULLIF(COUNT(*) FILTER (WHERE event = 'addtocart'), 0), 2) AS cart_to_purchase_pct
FROM events_sessionized
WHERE available IS NOT NULL
GROUP BY available
ORDER BY available;

-- 2) How much view demand is wasted on out-of-stock items?
SELECT
    available,
    COUNT(*) FILTER (WHERE event = 'view')     AS views,
    COUNT(DISTINCT itemid)                     AS distinct_items_viewed,
    ROUND(100.0 * COUNT(*) FILTER (WHERE event = 'view')
          / SUM(COUNT(*) FILTER (WHERE event = 'view')) OVER (), 1) AS pct_of_all_views
FROM events_sessionized
WHERE available IS NOT NULL AND event = 'view'
GROUP BY available
ORDER BY available;

-- 3) Which departments are worst? 
SELECT
    d.root_id,
    COUNT(*) FILTER (WHERE e.event = 'view')                         AS total_views,
    COUNT(*) FILTER (WHERE e.event = 'view' AND e.available = '0')   AS oos_views,
    ROUND(100.0 * COUNT(*) FILTER (WHERE e.event = 'view' AND e.available = '0')
          / NULLIF(COUNT(*) FILTER (WHERE e.event = 'view'), 0), 1)  AS oos_view_pct
FROM events_sessionized AS e
JOIN dim_category AS d ON d.categoryid = e.categoryid::int
WHERE e.available IS NOT NULL
GROUP BY d.root_id
HAVING COUNT(*) FILTER (WHERE e.event = 'view') > 5000
ORDER BY oos_view_pct DESC
LIMIT 15;