/*							///////////////////////////
 							/E-COMMERCE SALES ANALYSIS/
							///////////////////////////
*/
-------------------------------------------------------------------------
--1. Memfilter bulan dengan total nilai transaksi paling besar di 2021 --
-------------------------------------------------------------------------

select
    TO_CHAR(order_date, 'Month') AS bulan,
    ROUND(SUM(after_discount)) AS total_transaksi_terbesar
FROM
    order_detail
WHERE
    EXTRACT(YEAR FROM order_date) = 2021
    AND is_valid = 1
GROUP BY
    bulan
ORDER BY
    total_transaksi_terbesar DESC;

---------------------------------------------------------------------
--2. Memfilter kategori dengan nilai transaksi paling besar di 2022--
---------------------------------------------------------------------

select
	sku_detail.category,
	Round(SUM(order_detail.after_discount)) AS total_transaksi_terbesar
from
	order_detail
join
	sku_detail ON order_detail.sku_id = sku_detail.id
where
	EXTRACT(YEAR FROM order_detail.order_date) = 2022
	and order_detail.is_valid = 1
GROUP by
	sku_detail.category
ORDER by
	total_transaksi_terbesar desc

----------------------------------------------------------------------------------------------
-- 3. Membandingkan nilai transaksi dari masing-masing kategori pada tahun 2021 dengan 2022 --
-- dan kategori apa saja yang mengalami peningkatan dan penurunan                           --
----------------------------------------------------------------------------------------------
	
with TransaksiPerKategori AS (
    SELECT
        sd.category AS category,
        EXTRACT(YEAR FROM od.order_date) AS tahun,
        ROUND(SUM(od.after_discount)) AS total_transaksi
    FROM
        order_detail od	
    LEFT JOIN
        sku_detail sd ON od.sku_id = sd.id
    WHERE
        od.is_valid = 1
        AND EXTRACT(YEAR FROM od.order_date) BETWEEN 2021 AND 2022
    GROUP BY
        sd.category,
        EXTRACT(YEAR FROM od.order_date)
),
Total2021_2022 AS (
    SELECT
        category,
        MAX(total_transaksi) FILTER (WHERE tahun = 2021) AS total_2021,
        MAX(total_transaksi) FILTER (WHERE tahun = 2022) AS total_2022
    FROM TransaksiPerKategori
    GROUP BY category
)
SELECT
    category,
    total_2021,
    total_2022,
    CASE
        WHEN total_2022 > total_2021 THEN 'Meningkat'
        WHEN total_2022 < total_2021 THEN 'Menurun'
    END AS volume_transaksi,
    	(CASE WHEN total_2022 > total_2021 THEN '+' ELSE '' END || 
    	TO_CHAR(total_2022 - total_2021, 'FM999,999,999')) AS YoY,
		ROUND((total_2022 - total_2021) / total_2021 * 100) || '%,' AS growth
	from
		Total2021_2022
	ORDER by
		total_2022 DESC;

------------------------------------------------------------------------------------
-- 4. Memfilter top 5 metode pembayaran yang paling populer digunakan selama 2022 --
------------------------------------------------------------------------------------

select
    payment_method,
    COUNT(DISTINCT id) AS total_payment
FROM (
    SELECT
        od.id,
        pd.payment_method
    FROM
        order_detail od
    JOIN
        payment_detail pd ON od.payment_id = pd.id
    WHERE
        od.is_valid = 1
        AND EXTRACT(YEAR FROM od.order_date) = 2022) AS OrderPayments
GROUP BY
    payment_method
ORDER BY
    total_payment DESC
limit 5

---------------------------------------------------------
--5. Memfilter top 5 produk dengan transaksi terbanyak --
---------------------------------------------------------

with ProductSales AS (
    SELECT
        CASE
            WHEN LOWER(sd.sku_name) LIKE '%samsung%' THEN 'Samsung'
            WHEN LOWER(sd.sku_name) LIKE '%apple%' or
            	 LOWER(sd.sku_name) LIKE '%iphone%' or
            	 LOWER(sd.sku_name) LIKE '%macbook%' or
            	 LOWER(sd.sku_name) LIKE '%ipad%' THEN 'Apple'
            WHEN LOWER(sd.sku_name) LIKE '%sony%' THEN 'Sony'
            WHEN LOWER(sd.sku_name) LIKE '%huawei%' THEN 'Huawei'
            WHEN LOWER(sd.sku_name) LIKE '%lenovo%' THEN 'Lenovo'
        END AS product_category,
        ROUND(SUM(od.after_discount)) AS total_sales
    FROM
        order_detail od
    JOIN
        sku_detail sd ON od.sku_id = sd.id
    WHERE
        od.is_valid = 1
    GROUP BY
        product_category
)
SELECT
    product_category,
    total_sales
	FROM
    	ProductSales
    where product_category is not null
	ORDER BY
    	total_sales DESC;
