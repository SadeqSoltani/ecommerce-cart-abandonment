
DROP TABLE IF EXISTS events_sessionized;

CREATE TABLE events_sessionized AS
WITH gaps AS (
    
    SELECT *,
           timestamp_ms - LAG(timestamp_ms) OVER (
               PARTITION BY visitorid ORDER BY timestamp_ms
           ) AS gap_ms
    FROM events_enriched
),
flags AS (
    
    SELECT *,
           CASE WHEN gap_ms IS NULL OR gap_ms > 1800000 THEN 1 ELSE 0 END
               AS is_new_session
    FROM gaps
)

SELECT *,
       visitorid::text || '_' ||
       SUM(is_new_session) OVER (
           PARTITION BY visitorid ORDER BY timestamp_ms
       )::text AS session_id
FROM flags;


-- Verification

SELECT
    COUNT(*)                   AS total_events,
    COUNT(DISTINCT session_id) AS total_sessions,
    ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT session_id), 2) AS events_per_session
FROM events_sessionized;