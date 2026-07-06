DROP TABLE IF EXISTS visitor_features;

CREATE TABLE visitor_features AS
SELECT
    visitorid,

    -- VOLUME
    COUNT(*)                                              AS total_events,
    COUNT(DISTINCT session_id)                            AS total_sessions,
    COUNT(DISTINCT DATE(event_time))                      AS active_days,

    -- BEHAVIOUR MIX
    COUNT(*) FILTER (WHERE event = 'view')                AS views,
    COUNT(*) FILTER (WHERE event = 'addtocart')           AS carts,
    COUNT(*) FILTER (WHERE event = 'transaction')         AS purchases,
    ROUND(COUNT(*) FILTER (WHERE event = 'view') * 1.0
          / COUNT(*), 3)                                  AS view_ratio,

    -- REPETITION
    COUNT(DISTINCT itemid)                                AS unique_items,
    ROUND(COUNT(DISTINCT itemid) * 1.0 / COUNT(*), 3)     AS item_diversity,
    COUNT(DISTINCT categoryid)                            AS unique_categories,

    -- SPEED
    MIN(gap_ms)                                           AS min_gap_ms,
    ROUND(AVG(gap_ms))                                    AS avg_gap_ms,

    -- TIMING (off-hours = 1-5am UTC)
    COUNT(*) FILTER (WHERE event_hour BETWEEN 1 AND 5)    AS offhours_events,
    ROUND(COUNT(*) FILTER (WHERE event_hour BETWEEN 1 AND 5) * 1.0
          / COUNT(*), 3)                                  AS offhours_ratio,

    -- INTENSITY
    ROUND(COUNT(*) * 1.0
          / NULLIF(COUNT(DISTINCT DATE(event_time)), 0), 2) AS events_per_day

FROM events_sessionized
GROUP BY visitorid;