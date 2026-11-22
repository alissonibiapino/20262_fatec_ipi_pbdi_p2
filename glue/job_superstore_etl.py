import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue import DynamicFrame

def sparkSqlQuery(glueContext, query, mapping, transformation_ctx) -> DynamicFrame:
    for alias, frame in mapping.items():
        frame.toDF().createOrReplaceTempView(alias)
    result = spark.sql(query)
    return DynamicFrame.fromDF(result, glueContext, transformation_ctx)
args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Script generated for node AWS Glue Data Catalog
AWSGlueDataCatalog_node1795380781802 = glueContext.create_dynamic_frame.from_catalog(database="superstore_catalog", table_name="bruto", transformation_ctx="AWSGlueDataCatalog_node1795380781802")

# Script generated for node Change Schema
ChangeSchema_node1795380889900 = ApplyMapping.apply(frame=AWSGlueDataCatalog_node1795380781802, mappings=[("row id", "long", "row_id", "string"), ("order id", "string", "order_id", "string"), ("order date", "string", "order_date", "string"), ("ship date", "string", "ship_date", "string"), ("ship mode", "string", "ship_mode", "string"), ("customer id", "string", "customer_id", "string"), ("customer name", "string", "customer_name", "string"), ("segment", "string", "segment", "string"), ("country", "string", "country", "string"), ("city", "string", "city", "string"), ("state", "string", "state", "string"), ("postal code", "long", "postal_code", "string"), ("region", "string", "region", "string"), ("product id", "string", "product_id", "string"), ("category", "string", "category", "string"), ("sub-category", "string", "sub_category", "string"), ("product name", "string", "product_name", "string"), ("sales", "double", "sales", "string")], transformation_ctx="ChangeSchema_node1795380889900")

# Script generated for node SQL Query
SqlQuery350 = '''
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
'''
SQLQuery_node1795381004234 = sparkSqlQuery(glueContext, query = SqlQuery350, mapping = {"myDataSource":ChangeSchema_node1795380889900}, transformation_ctx = "SQLQuery_node1795381004234")

# Script generated for node PostgreSQL
PostgreSQL_node1795381349613 = glueContext.write_dynamic_frame.from_catalog(frame=SQLQuery_node1795381004234, database="superstore_catalog", table_name="superstore_dw_staging_sales", transformation_ctx="PostgreSQL_node1795381349613")

job.commit()