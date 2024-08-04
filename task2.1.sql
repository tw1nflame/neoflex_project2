WITH DuplicateRecords AS (
    SELECT 
        client_rk,
        effective_from_date,
        ROW_NUMBER() OVER (PARTITION BY client_rk, effective_from_date ORDER BY client_id) AS row_num
    FROM 
        dm.client
)
DELETE FROM dm.client
WHERE (client_rk, effective_from_date) IN (
    SELECT 
        client_rk, 
        effective_from_date
    FROM 
        DuplicateRecords
    WHERE 
        row_num > 1
);

