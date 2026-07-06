DROP TABLE IF EXISTS item_properties_trimmed;

CREATE TABLE item_properties_trimmed AS
SELECT timestamp_ms,
       itemid,
       property,
       value
FROM raw_item_properties
WHERE property IN ('categoryid', 'available');