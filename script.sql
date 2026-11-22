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
