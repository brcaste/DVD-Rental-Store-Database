-----------------------------------------------------------------------------------------
--Part B Creating original function for concatenating customer name
CREATE OR REPLACE FUNCTION concat_name(first_name VARCHAR, last_name VARCHAR)
	RETURNS Text
	LANGUAGE plpgsql
AS
$$
BEGIN
	 if first_name is null and last_name is null then 
	 	return null;
     elsif first_name is null and last_name is not null then
		return last_name;
	 elsif first_name is not null and last_name is null then
		 return first_name;
	 else
	 	return first_name || ' ' || last_name;
	 end if;
END;
$$
--Testing custom concat function for part B  
SELECT concat_name('Brandon', 'Castellanos')
SELECT concat_name('Brandon', null)
SELECT concat_name(null, 'Castellanos')
SELECT concat_name(null, null)
SELECT concat_name(first_name, last_name) AS full_name FROM customer;

-----------------------------------------------------------------------------
DROP TABLE Customer_Performance_Overview;
--Part C-1 creating a detailed view of report
CREATE TABLE Customer_Performance_Overview AS
--Part D-1 
SELECT 
	concat_name(first_name, last_name) AS full_name,
	address,
	city,
	postal_code,
	country,
	email,
	store_id,
	amount as sale_amount
FROM
	customer
	INNER JOIN address using (address_id)
	INNER JOIN city using (city_id)
	INNER JOIN country using (country_id)
	INNER JOIN payment using (customer_id);

--DISPLAYING DETAILED VIEW
SELECT * FROM Customer_Performance_Overview;
--------------------------------------------------------------------------------------	
DROP TABLE Customer_Perf_Summary_id_1;
--Part C-2 creating top 5 customer summary report for store 1
CREATE TABLE Customer_Perf_Summary_id_1 AS
--Part D-2
SELECT 
	full_name, address, city, postal_code, country, email, store_id, SUM(sale_amount) AS total_sales
FROM Customer_Performance_Overview
WHERE store_id = '1'
GROUP BY 1,2,3,4,5,6,7
ORDER BY total_sales DESC;

--Displaying store 1 summary report
SELECT * FROM Customer_Perf_Summary_id_1 LIMIT 10;
------------------------------------------------------------------------------------
DROP TABLE Customer_Perf_Summary_id_2;
--Part C-2 creating a top 5 summary report for store 2
CREATE TABLE Customer_Perf_Summary_id_2 AS
--Part D-2 
SELECT 
	full_name, address, city, postal_code, country, email, store_id, SUM(sale_amount) AS total_sales 
FROM Customer_Performance_Overview
WHERE store_id = '2'
GROUP BY 1,2,3,4,5,6,7
ORDER BY total_sales DESC;

--Displaying store 2 summary report
SELECT * FROM Customer_Perf_Summary_id_2 LIMIT 10;	
----------------------------------------------------------------------------------------	
--Part E-1  Creating a trigger function 
CREATE OR REPLACE FUNCTION summary_table_update_trigger()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
	DELETE FROM Customer_Perf_Summary_id_1;
	INSERT INTO Customer_Perf_Summary_id_1
	SELECT 
		full_name, address, city, postal_code, country, email, store_id, SUM(sale_amount) AS total_sales
		FROM Customer_Performance_Overview
	WHERE store_id = '1'
	GROUP BY 1,2,3,4,5,6,7
	ORDER BY total_sales DESC;

	DELETE FROM Customer_Perf_Summary_id_2;
	INSERT INTO Customer_Perf_Summary_id_2
	SELECT 
		full_name, address, city, postal_code, country, email, store_id, SUM(sale_amount) AS total_sales
		FROM Customer_Performance_Overview
	WHERE store_id = '2'
	GROUP BY 1,2,3,4,5,6,7
	ORDER BY total_sales DESC;

	RETURN NEW;	
END;
$$;

--Part E-2 initiating trigger on detailed table
CREATE OR REPLACE TRIGGER new_customer_sale
AFTER INSERT
ON Customer_Performance_Overview
FOR EACH STATEMENT
EXECUTE PROCEDURE summary_table_update_trigger();

--Testing trigger functionality 
SELECT COUNT(*) FROM Customer_Performance_Overview;
INSERT INTO Customer_Performance_Overview(full_name, address, city, postal_code, country, email, store_id, sale_amount) 
	VALUES
	('Peter Test', '111 spooner st', 'Rhode Island', '10234', 'United States', 'p.test@website.com', '1', '500.43'),
	('Homer Test', '212 Evergreen Terrace', 'Portland', '90912', 'United States', 'h.test@website.org', '2', '423.21');

SELECT COUNT(*) FROM Customer_Performance_Overview;
SELECT * FROM Customer_Perf_Summary_id_1 ORDER BY total_sales DESC LIMIT 10;
SELECT * FROM Customer_Perf_Summary_id_2 ORDER BY total_sales DESC LIMIT 10;

--Part F
CREATE OR REPLACE PROCEDURE refresh_customer_performance_reports()
LANGUAGE plpgsql    
AS $$
BEGIN
	DELETE FROM Customer_Performance_Overview;
	INSERT INTO Customer_Performance_Overview
	SELECT 
	concat_name(first_name, last_name) AS full_name,
	address,
	city,
	postal_code,
	country,
	email,
	store_id,
	amount as sale_amount
	FROM
	customer
	INNER JOIN address using (address_id)
	INNER JOIN city using (city_id)
	INNER JOIN country using (country_id)
	INNER JOIN payment using (customer_id);

	DELETE FROM Customer_Perf_Summary_id_1;
	INSERT INTO Customer_Perf_Summary_id_1
	SELECT full_name, address, city, postal_code, country, email, store_id, SUM(sale_amount) AS total_sales 
		FROM Customer_Performance_Overview
	WHERE store_id = '1'
	GROUP BY 1,2,3,4,5,6,7
	ORDER BY total_sales DESC;

	DELETE FROM Customer_Perf_Summary_id_2;
	INSERT INTO Customer_Perf_Summary_id_2
	SELECT full_name, address, city, postal_code, country, email, store_id, SUM(sale_amount) AS total_sales  
		FROM Customer_Performance_Overview
	WHERE store_id = '2'
	GROUP BY 1,2,3,4,5,6,7
	ORDER BY total_sales DESC;
	 
RETURN;
END;
$$; 

--Testing refresh_customer_performance_reports() procedure
CALL refresh_customer_performance_reports();
SELECT * FROM Customer_Performance_Overview;
SELECT * FROM Customer_Perf_Summary_id_1 ORDER BY total_sales DESC LIMIT 10;
SELECT * FROM Customer_Perf_Summary_id_2 ORDER BY total_sales DESC LIMIT 10;