--Запрос для правильного заполнения 1
SELECT  
	curr.account_rk,
	curr.effective_date,
	COALESCE(prev.account_out_sum, curr.account_in_sum) AS account_in_sum,
	curr.account_out_sum
FROM rd.account_balance curr
LEFT JOIN rd.account_balance prev 
	ON curr.account_rk = prev.account_rk AND prev.effective_date = curr.effective_date - interval '1 day';

-- Запрос для правильного заполнения 2
SELECT  
	curr.account_rk,
	curr.effective_date,
	curr.account_in_sum,
	COALESCE(nex.account_in_sum, curr.account_out_sum) AS account_out_sum
FROM rd.account_balance curr
LEFT JOIN rd.account_balance nex 
	ON curr.account_rk = nex.account_rk AND nex.effective_date = curr.effective_date + interval '1 day';


-- Запрос для изменения rd.account_balance
WITH correct_values AS (
	SELECT  
	curr.account_rk,
	curr.effective_date,
	COALESCE(prev.account_out_sum, curr.account_in_sum) AS account_in_sum,
	curr.account_out_sum
FROM rd.account_balance curr
LEFT JOIN rd.account_balance prev 
	ON curr.account_rk = prev.account_rk AND prev.effective_date = curr.effective_date - interval '1 day'
)
UPDATE rd.account_balance ab
SET account_in_sum = correct_values.account_in_sum
FROM correct_values
WHERE ab.account_rk = correct_values.account_rk AND ab.effective_date = correct_values.effective_date;


--Процедура для заполнения витрины
CREATE OR REPLACE PROCEDURE dm.account_balance_turnover_fill()
LANGUAGE plpgsql
AS $$
BEGIN
	DELETE FROM dm.account_balance_turnover;
	
	INSERT INTO dm.account_balance_turnover
	SELECT a.account_rk,
		 COALESCE(dc.currency_name, '-1'::TEXT) AS currency_name,
		 a.department_rk,
		 ab.effective_date,
		 ab.account_in_sum,
		 ab.account_out_sum
	FROM rd.account a
	LEFT JOIN rd.account_balance ab ON a.account_rk = ab.account_rk
	LEFT JOIN dm.dict_currency dc ON a.currency_cd = dc.currency_cd;
END $$;

CALL dm.account_balance_turnover_fill();