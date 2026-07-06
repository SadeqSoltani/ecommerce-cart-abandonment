DROP TABLE IF EXISTS session_summary;

CREATE TABLE session_summary AS
SELECT
    session_id,
    visitorid,
    COUNT(*)                                              AS events,
    COUNT(DISTINCT itemid)                                AS unique_items,
    COUNT(DISTINCT categoryid)                            AS unique_categories,
    COUNT(*) FILTER (WHERE event = 'view')                AS views,
    COUNT(*) FILTER (WHERE event = 'addtocart')           AS carts,
    COUNT(*) FILTER (WHERE event = 'transaction')         AS purchases,
    (COUNT(*) FILTER (WHERE event = 'transaction') > 0)   AS is_purchasing_session,
    ROUND(EXTRACT(EPOCH FROM (MAX(event_time) - MIN(event_time))) / 60.0, 2) AS duration_min,
    MIN(event_time)                                       AS session_start
FROM events_sessionized
GROUP BY session_id, visitorid;


-- Engaged buyer vs non-buyer comparison 
SELECT
    is_purchasing_session,
    COUNT(*)                          AS sessions,
    ROUND(AVG(events), 2)             AS avg_events,
    ROUND(AVG(views), 2)              AS avg_views,
    ROUND(AVG(carts), 2)              AS avg_carts,
    ROUND(AVG(unique_items), 2)       AS avg_unique_items,
    ROUND(AVG(unique_categories), 2)  AS avg_unique_categories,
    ROUND(AVG(duration_min), 2)       AS avg_duration_min
FROM session_summary
WHERE events >= 2
GROUP BY is_purchasing_session
ORDER BY is_purchasing_session;