-- enunciado 05

CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS dw;

DROP TABLE IF EXISTS staging.sales CASCADE;
CREATE TABLE staging.sales (
    row_id        INTEGER       NOT NULL PRIMARY KEY,
    order_id      VARCHAR(20)   NOT NULL,
    order_date    DATE          NOT NULL,
    ship_date     DATE          NOT NULL,
    ship_mode     VARCHAR(20)   NOT NULL,
    customer_id   VARCHAR(20)   NOT NULL,
    customer_name VARCHAR(60)   NOT NULL,
    segment       VARCHAR(20)   NOT NULL,
    country       VARCHAR(40)   NOT NULL,
    city          VARCHAR(60)   NOT NULL,
    state         VARCHAR(40)   NOT NULL,
    postal_code   VARCHAR(10)   NOT NULL,
    region        VARCHAR(20)   NOT NULL,
    product_id    VARCHAR(20)   NOT NULL,
    category      VARCHAR(30)   NOT NULL,
    sub_category  VARCHAR(30)   NOT NULL,
    product_name  VARCHAR(200)  NOT NULL,
    sales         NUMERIC(12,2) NOT NULL
);


-- enunciado 9
SELECT
    cast(trim(row_id) AS int) AS row_id,
    trim(order_id) AS order_id,
    to_date(trim(order_date), 'dd/MM/yyyy') AS order_date,
    to_date(trim(ship_date),  'dd/MM/yyyy') AS ship_date,
    trim(ship_mode) AS ship_mode,
    trim(customer_id) AS customer_id,
    trim(customer_name) AS customer_name,
    trim(segment) AS segment,
    trim(country) AS country,
    trim(city) AS city,
    trim(state) AS state,
    coalesce(nullif(trim(postal_code), ''), 'N/D') AS postal_code,
    trim(region) AS region,
    trim(product_id) AS product_id,
    trim(category) AS category,
    trim(sub_category) AS sub_category,
    trim(product_name) AS product_name,
    cast(trim(sales) AS decimal(12,2)) AS sales
FROM myDataSource;

-- enunciado 10
SELECT
  COUNT(*) AS linhas,
  SUM(sales) AS soma_sales,
  MIN(order_date) AS menor_data_pedido,
  MAX(ship_date) AS maior_data_envio,
  COUNT(*) FILTER (WHERE postal_code = 'N/D') AS codigos_nd,
  COUNT(*) FILTER (WHERE ship_date < order_date) AS envio_antes_pedido
FROM staging.sales;

-- enunciado 11
DROP TABLE IF EXISTS dw.dim_date CASCADE;
CREATE TABLE dw.dim_date (
    date_sk INTEGER PRIMARY KEY,
    full_date DATE NOT NULL UNIQUE,
    day SMALLINT NOT NULL,
    month SMALLINT NOT NULL,
    month_name VARCHAR(15) NOT NULL,
    quarter SMALLINT NOT NULL,
    year SMALLINT NOT NULL,
    day_of_week VARCHAR(15) NOT NULL,
    is_weekend BOOLEAN NOT NULL
);

INSERT INTO dw.dim_date
SELECT
    CAST(TO_CHAR(d, 'YYYYMMDD') AS INTEGER),
    d::DATE,
    EXTRACT(DAY FROM d)::SMALLINT,
    EXTRACT(MONTH FROM d)::SMALLINT,
    TO_CHAR(d, 'TMMonth'),
    EXTRACT(QUARTER FROM d)::SMALLINT,
    EXTRACT(YEAR FROM d)::SMALLINT,
    TO_CHAR(d, 'TMDay'),
    EXTRACT(DOW FROM d) IN (0, 6)
FROM generate_series(
         (SELECT date_trunc('year', MIN(order_date)) FROM staging.sales),
         (SELECT date_trunc('year', MAX(ship_date)) + INTERVAL '1 year - 1 day'
            FROM staging.sales),
         INTERVAL '1 day') g(d);

SELECT MIN(full_date), MAX(full_date), COUNT(*) FROM dw.dim_date;

-- o fim do calendario usa a data de envio porque o envio só acontece depois do pedido.




-- enunciado 12
-- 01
SELECT COUNT(*) AS produtos_com_nomes_diferentes
FROM (
    SELECT product_id
    FROM staging.sales
    GROUP BY product_id
    HAVING COUNT(DISTINCT product_name) > 1
) t;
-- Resultado: 32 produtos com nomes diferentes

-- 02
SELECT COUNT(*) AS clientes_com_atributos_diferentes
FROM (
    SELECT customer_id
    FROM staging.sales
    GROUP BY customer_id
    HAVING COUNT(DISTINCT customer_name) > 1
        OR COUNT(DISTINCT segment) > 1
) t;
-- Resultado: 0, nenhum cliente com atributo diferente

-- 03
SELECT COUNT(*) AS locais_com_regioes_diferentes
FROM (
    SELECT city, state, postal_code
    FROM staging.sales
    GROUP BY city, state, postal_code
    HAVING COUNT(DISTINCT region) > 1
) t;
-- Resultado: 0, nenhum local com região diferente


-- enunciad 13
DROP TABLE IF EXISTS dw.fact_sales CASCADE;
DROP TABLE IF EXISTS dw.dim_customer CASCADE;
DROP TABLE IF EXISTS dw.dim_product CASCADE;
DROP TABLE IF EXISTS dw.dim_location CASCADE;
DROP TABLE IF EXISTS dw.dim_ship_mode CASCADE;

CREATE TABLE dw.dim_customer (
    customer_sk SERIAL PRIMARY KEY,
    customer_id VARCHAR(20) NOT NULL UNIQUE,
    customer_name VARCHAR(60) NOT NULL,
    segment VARCHAR(20) NOT NULL
);

CREATE TABLE dw.dim_product (
    product_sk SERIAL PRIMARY KEY,
    product_id VARCHAR(20) NOT NULL UNIQUE,
    product_name VARCHAR(200) NOT NULL,
    category VARCHAR(30) NOT NULL,
    sub_category VARCHAR(30) NOT NULL
);

CREATE TABLE dw.dim_location (
    location_sk SERIAL PRIMARY KEY,
    country VARCHAR(40) NOT NULL,
    state VARCHAR(40) NOT NULL,
    city VARCHAR(60) NOT NULL,
    postal_code VARCHAR(10) NOT NULL,
    region VARCHAR(20) NOT NULL,
    UNIQUE (country, state, city, postal_code)
);

CREATE TABLE dw.dim_ship_mode (
    ship_mode_sk SERIAL PRIMARY KEY,
    ship_mode VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE dw.fact_sales (
    sale_sk SERIAL PRIMARY KEY,
    row_nk INTEGER NOT NULL UNIQUE,
    order_nk VARCHAR(20) NOT NULL,
    order_date_sk INTEGER NOT NULL REFERENCES dw.dim_date(date_sk),
    ship_date_sk INTEGER NOT NULL REFERENCES dw.dim_date(date_sk),
    customer_sk INTEGER NOT NULL REFERENCES dw.dim_customer(customer_sk),
    product_sk INTEGER NOT NULL REFERENCES dw.dim_product(product_sk),
    location_sk INTEGER NOT NULL REFERENCES dw.dim_location(location_sk),
    ship_mode_sk INTEGER NOT NULL REFERENCES dw.dim_ship_mode(ship_mode_sk),
    sales NUMERIC(12,2) NOT NULL,
    ship_days INTEGER NOT NULL
);

CREATE INDEX ix_fs_order_date ON dw.fact_sales(order_date_sk);
CREATE INDEX ix_fs_ship_date ON dw.fact_sales(ship_date_sk);
CREATE INDEX ix_fs_customer ON dw.fact_sales(customer_sk);
CREATE INDEX ix_fs_product ON dw.fact_sales(product_sk);
CREATE INDEX ix_fs_location ON dw.fact_sales(location_sk);
CREATE INDEX ix_fs_ship_mode ON dw.fact_sales(ship_mode_sk);
