
CREATE INDEX IF NOT EXISTS idx_props_lookup
ON item_properties_trimmed (itemid, property, timestamp_ms);


DROP TABLE IF EXISTS events_enriched;

CREATE TABLE events_enriched AS
SELECT
    
    e.visitorid,
    e.itemid,
    e.event,
    e.transactionid,
    e.timestamp_ms,

    
    to_timestamp(e.timestamp_ms / 1000) AT TIME ZONE 'UTC'                          AS event_time,
    EXTRACT(HOUR FROM to_timestamp(e.timestamp_ms / 1000) AT TIME ZONE 'UTC')::int  AS event_hour,
    EXTRACT(DOW  FROM to_timestamp(e.timestamp_ms / 1000) AT TIME ZONE 'UTC')::int  AS event_dow,

    
    COALESCE(cat_asof.value, cat_first.value) AS categoryid,

    
    COALESCE(avl_asof.value, avl_first.value) AS available

FROM raw_events AS e


LEFT JOIN LATERAL (
    SELECT p.value
    FROM item_properties_trimmed AS p
    WHERE p.itemid = e.itemid
      AND p.property = 'categoryid'
      AND p.timestamp_ms <= e.timestamp_ms
    ORDER BY p.timestamp_ms DESC
    LIMIT 1
) AS cat_asof ON true


LEFT JOIN LATERAL (
    SELECT p.value
    FROM item_properties_trimmed AS p
    WHERE p.itemid = e.itemid
      AND p.property = 'categoryid'
    ORDER BY p.timestamp_ms ASC
    LIMIT 1
) AS cat_first ON true


LEFT JOIN LATERAL (
    SELECT p.value
    FROM item_properties_trimmed AS p
    WHERE p.itemid = e.itemid
      AND p.property = 'available'
      AND p.timestamp_ms <= e.timestamp_ms
    ORDER BY p.timestamp_ms DESC
    LIMIT 1
) AS avl_asof ON true


LEFT JOIN LATERAL (
    SELECT p.value
    FROM item_properties_trimmed AS p
    WHERE p.itemid = e.itemid
      AND p.property = 'available'
    ORDER BY p.timestamp_ms ASC
    LIMIT 1
) AS avl_first ON true;



-- Verification

SELECT
    COUNT(*)                                        AS total,
    COUNT(*) FILTER (WHERE categoryid IS NULL)      AS null_category,
    ROUND(100.0 * COUNT(*) FILTER (WHERE categoryid IS NULL) / COUNT(*), 2) AS pct_null_cat
FROM events_enriched;