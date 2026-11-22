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

-- enunciado 14
-- Enunciado 14
-- Crie a procedure dw.carrega_dw(), nos moldes da Secao 13 da apostila.
-- a) esvazia a fato e as quatro dimensoes da Fase 6, reiniciando as
--    sequencias; a dw.dim_date nao e esvaziada;
-- b) carrega cada dimensao com exatamente uma linha por chave natural;
--    quando o Enunciado 12 mostrar mais de um valor de atributo para a
--    mesma chave, usa o menor valor, em ordem alfabetica, e explica
--    essa escolha em comentario;
-- c) carrega a fato trocando os atributos naturais pelas surrogate keys
--    por JOIN; as duas chaves de data sao obtidas por formatacao das
--    datas, sem JOIN com a dw.dim_date; ship_days e a diferenca, em
--    dias, entre a data de envio e a do pedido, por subtracao de datas;
-- d) apos cada carga, obtem a quantidade de linhas inseridas com
--    GET DIAGNOSTICS e a informa com RAISE NOTICE;
-- e) ao final, compara a quantidade de linhas da fato com a da staging
--    e, se forem diferentes, interrompe a carga com RAISE EXCEPTION,
--    informando as duas quantidades.
-- Em seguida, chame a procedure e confira, em uma unica consulta com
-- UNION ALL, a quantidade de linhas das quatro dimensoes e da fato.
-- Registre os numeros em comentario.

CREATE OR REPLACE PROCEDURE dw.carrega_dw()
LANGUAGE plpgsql
AS $$
DECLARE
  v_linhas INTEGER;
  v_fato INTEGER;
  v_staging INTEGER;
BEGIN
  -- a
  TRUNCATE TABLE dw.fact_sales, dw.dim_customer, dw.dim_product,
    dw.dim_location, dw.dim_ship_mode
  RESTART IDENTITY CASCADE;
  RAISE NOTICE 'Modelo dimensional limpo';

  -- b
  INSERT INTO dw.dim_customer (customer_id, customer_name, segment)
  SELECT customer_id, MIN(customer_name), MIN(segment)
  FROM staging.sales
  GROUP BY customer_id;
  GET DIAGNOSTICS v_linhas = ROW_COUNT;
  RAISE NOTICE 'dim_customer: % linhas', v_linhas;

  INSERT INTO dw.dim_product (product_id, product_name, category, sub_category)
  SELECT product_id, MIN(product_name), MIN(category), MIN(sub_category)
  FROM staging.sales
  GROUP BY product_id;
  GET DIAGNOSTICS v_linhas = ROW_COUNT;
  RAISE NOTICE 'dim_product: % linhas', v_linhas;

  INSERT INTO dw.dim_location (country, state, city, postal_code, region)
  SELECT country, state, city, postal_code, MIN(region)
  FROM staging.sales
  GROUP BY country, state, city, postal_code;
  GET DIAGNOSTICS v_linhas = ROW_COUNT;
  RAISE NOTICE 'dim_location: % linhas', v_linhas;

  INSERT INTO dw.dim_ship_mode (ship_mode)
  SELECT DISTINCT ship_mode
  FROM staging.sales;
  GET DIAGNOSTICS v_linhas = ROW_COUNT;
  RAISE NOTICE 'dim_ship_mode: % linhas', v_linhas;

  -- c
  INSERT INTO dw.fact_sales (row_nk, order_nk, order_date_sk, ship_date_sk,
    customer_sk, product_sk, location_sk, ship_mode_sk, sales, ship_days)
  SELECT
    s.row_id,
    s.order_id,
    CAST(TO_CHAR(s.order_date, 'YYYYMMDD') AS INTEGER),
    CAST(TO_CHAR(s.ship_date, 'YYYYMMDD') AS INTEGER),
    c.customer_sk,
    p.product_sk,
    l.location_sk,
    m.ship_mode_sk,
    s.sales,
    s.ship_date - s.order_date
  FROM staging.sales s
  JOIN dw.dim_customer c ON c.customer_id = s.customer_id
  JOIN dw.dim_product p ON p.product_id = s.product_id
  JOIN dw.dim_location l ON l.country = s.country
    AND l.state = s.state
    AND l.city = s.city
    AND l.postal_code = s.postal_code
  JOIN dw.dim_ship_mode m ON m.ship_mode = s.ship_mode;
  GET DIAGNOSTICS v_linhas = ROW_COUNT;
  RAISE NOTICE 'fact_sales: % linhas', v_linhas;

  -- e
  SELECT COUNT(*) INTO v_fato FROM dw.fact_sales;
  SELECT COUNT(*) INTO v_staging FROM staging.sales;
  IF v_fato <> v_staging THEN
    RAISE EXCEPTION 'Carga interrompida: fato tem % linhas e staging tem %',
      v_fato, v_staging;
  END IF;
  RAISE NOTICE 'Carga concluida com sucesso';
END;
$$;

CALL dw.carrega_dw();

SELECT 'dim_customer' AS tabela, COUNT(*) AS linhas FROM dw.dim_customer
UNION ALL
SELECT 'dim_product', COUNT(*) FROM dw.dim_product
UNION ALL
SELECT 'dim_location', COUNT(*) FROM dw.dim_location
UNION ALL
SELECT 'dim_ship_mode', COUNT(*) FROM dw.dim_ship_mode
UNION ALL
SELECT 'fact_sales', COUNT(*) FROM dw.fact_sales;

-- Resultado das consultas:
-- dim_customer = 793
-- dim_product = 1861
-- dim_location = 628
-- dim_ship_mode = 4
-- fact_sales = 9800
