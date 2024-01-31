/*							///////////////////////////
 							/E-COMMERCE SALES ANALYSIS/
							///////////////////////////
*/
-----------------------------------------------------------------
--1. Memfilter bulan dengan total nilai transaksi paling besar --
-----------------------------------------------------------------

select
	EXTRACT(MONTH FROM order_date) AS bulan,
	SUM(after_discount) AS total_transaksi_terbesar
from
	order_detail
where
	EXTRACT(YEAR FROM order_date) = 2021
	and is_valid = 1
GROUP by
	bulan
ORDER BY
	total_transaksi_terbesar desc
limit 1

--------------------------------------------------------------
--2. Memfilter kategori dengan nilai transaksi paling besar --
--------------------------------------------------------------

select
	sku_detail.category,
	SUM(order_detail.after_discount) AS total_transaksi_terbesar
from
	order_detail
join
	sku_detail ON order_detail.sku_id = sku_detail.id
where
	EXTRACT(YEAR FROM order_detail.order_date) = 2022
and
	order_detail.is_valid = 1
GROUP by
	sku_detail.category
ORDER by
	total_transaksi_terbesar desc
limit 1

----------------------------------------------------------------------------------------------
-- 3. Membandingkan nilai transaksi dari masing-masing kategori pada tahun 2021 dengan 2022 --
-- dan kategori apa saja yang mengalami peningkatan dan penurunan                           --
----------------------------------------------------------------------------------------------

select
    category,
    	MAX(CASE WHEN tahun = 2021 THEN total_transaksi END) AS total_2021,
    	MAX(CASE WHEN tahun = 2022 THEN total_transaksi END) AS total_2022,
CASE
    WHEN MAX(CASE WHEN tahun = 2022 THEN total_transaksi END) > 
    	MAX(CASE WHEN tahun = 2021 THEN total_transaksi END) THEN 'Peningkatan'
    WHEN MAX(CASE WHEN tahun = 2022 THEN total_transaksi END) < 
    	MAX(CASE WHEN tahun = 2021 THEN total_transaksi END) THEN 'Penurunan'
    ELSE 'Tidak Berubah' END AS status_perubahan
FROM (
    SELECT
        sd.category,
        EXTRACT(YEAR FROM od.order_date) AS tahun,
        ROUND(SUM(od.after_discount * od.qty_ordered)::numeric, 0) AS total_transaksi
    FROM
        order_detail od
    JOIN
        sku_detail sd ON od.sku_id = sd.id
    WHERE
        od.is_valid = 1
        AND EXTRACT(YEAR FROM od.order_date) IN (2021, 2022)
    GROUP BY
        sd.category, EXTRACT(YEAR FROM od.order_date)) AS TransaksiPerKategori
	GROUP BY
    	category
    order by
    	status_perubahan asc;

---------------------
--3. Query With CTE--
---------------------

 WITH TransaksiPerKategori AS (
    SELECT
        sd.category,
        EXTRACT(YEAR FROM od.order_date) AS tahun,
        ROUND(SUM(od.after_discount * od.qty_ordered)::numeric, 0) AS total_transaksi
    FROM
        order_detail od
    JOIN
        sku_detail sd ON od.sku_id = sd.id
    WHERE
        od.is_valid = 1
        AND EXTRACT(YEAR FROM od.order_date) IN (2021, 2022)
    GROUP BY
        sd.category, EXTRACT(YEAR FROM od.order_date)
)

SELECT
    category,
    MAX(CASE WHEN tahun = 2021 THEN total_transaksi END) AS total_2021,
    MAX(CASE WHEN tahun = 2022 THEN total_transaksi END) AS total_2022,
    CASE
        WHEN MAX(CASE WHEN tahun = 2022 THEN total_transaksi END) > 
            MAX(CASE WHEN tahun = 2021 THEN total_transaksi END) THEN 'Peningkatan'
        WHEN MAX(CASE WHEN tahun = 2022 THEN total_transaksi END) < 
            MAX(CASE WHEN tahun = 2021 THEN total_transaksi END) THEN 'Penurunan'
        ELSE 'Tidak Berubah'
    END AS status_perubahan
FROM TransaksiPerKategori
GROUP BY category
ORDER BY status_perubahan ASC;

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
LIMIT 5;

---------------------------------------------------------
--5. Memfilter top 5 produk dengan transaksi terbanyak --
---------------------------------------------------------

select
    product_category,
    total_sales
FROM (
    SELECT
        CASE
            WHEN LOWER(sd.sku_name) LIKE '%samsung%' THEN 'Samsung'
            WHEN LOWER(sd.sku_name) LIKE '%apple%' THEN 'Apple'
            WHEN LOWER(sd.sku_name) LIKE '%sony%' THEN 'Sony'
            WHEN LOWER(sd.sku_name) LIKE '%huawei%' THEN 'Huawei'
            WHEN LOWER(sd.sku_name) LIKE '%lenovo%' THEN 'Lenovo'
            ELSE sd.sku_name
        END AS product_category,
        ROUND(SUM(od.after_discount * od.qty_ordered)::numeric, 0) AS total_sales
    FROM
        order_detail od
    JOIN
        sku_detail sd ON od.sku_id = sd.id
    WHERE
        od.is_valid = 1
        AND sd.sku_name ILIKE ANY (ARRAY['%Samsung%', '%Apple%', '%Sony%', '%Huawei%', '%Lenovo%'])
    GROUP BY
        product_category) AS ProductSales
	ORDER BY
    	total_sales DESC;

---------------------
--5. Query with CTE--
---------------------

WITH ProductSales AS (
    SELECT
        CASE
            WHEN LOWER(sd.sku_name) LIKE '%samsung%' THEN 'Samsung'
            WHEN LOWER(sd.sku_name) LIKE '%apple%' THEN 'Apple'
            WHEN LOWER(sd.sku_name) LIKE '%sony%' THEN 'Sony'
            WHEN LOWER(sd.sku_name) LIKE '%huawei%' THEN 'Huawei'
            WHEN LOWER(sd.sku_name) LIKE '%lenovo%' THEN 'Lenovo'
            ELSE sd.sku_name
        END AS product_category,
        ROUND(SUM(od.after_discount * od.qty_ordered)::numeric, 0) AS total_sales
    FROM
        order_detail od
    JOIN
        sku_detail sd ON od.sku_id = sd.id
    WHERE
        od.is_valid = 1
        AND sd.sku_name ILIKE ANY (ARRAY['%Samsung%', '%Apple%', '%Sony%', '%Huawei%', '%Lenovo%'])
    GROUP BY
        product_category
)

SELECT
    product_category,
    total_sales
FROM ProductSales
ORDER BY total_sales DESC;
