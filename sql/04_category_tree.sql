DROP TABLE IF EXISTS dim_category;

CREATE TABLE dim_category AS
WITH RECURSIVE tree AS (
    
    SELECT categoryid,
           parentid,
           categoryid AS root_id
    FROM raw_category_tree
    WHERE parentid IS NULL

    UNION ALL

  
    SELECT c.categoryid,
           c.parentid,
           t.root_id
    FROM raw_category_tree AS c
    JOIN tree AS t
      ON c.parentid = t.categoryid
)
SELECT categoryid,
       root_id
FROM tree;




-- Verification

SELECT
    (SELECT COUNT(*)                    FROM raw_category_tree) AS total_categories,
    (SELECT COUNT(*)                    FROM dim_category)      AS mapped_categories,
    (SELECT COUNT(DISTINCT root_id)     FROM dim_category)      AS num_roots;



