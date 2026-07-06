CREATE TABLE raw_events (
    timestamp_ms   BIGINT,   
    visitorid      BIGINT,
    event          TEXT,     
    itemid         BIGINT,
    transactionid  BIGINT    
);

CREATE TABLE raw_category_tree (
    categoryid     BIGINT,
    parentid       BIGINT    
);

CREATE TABLE raw_item_properties (
    timestamp_ms   BIGINT,
    itemid         BIGINT,
    property       TEXT,     
    value          TEXT      
);