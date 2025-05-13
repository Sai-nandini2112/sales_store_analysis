create table sales_store (
    transaction_id Varchar(15),
    customer_id varchar(15),
    customer_name varchar(30),
    customer_age int,
    gender varchar(15),
    product_id varchar(15),
    product_name varchar(15),
    product_category varchar(15),
    quantiy int,
    prce float,
    payment_mode varchar(15),
    purchaase_date date,
    time_of_purpose time,
    status varchar(15)

);

select * from sales_store 

SET DATEFORMAT dmy

BULK INSERT sales_store
FROM '/var/opt/mssql/sales.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2
);

--creating copy file
select * from sales_store

select * into sales from sales_store

select * from sales_store
select * from sales

--Data cleaning

--step - 1:- To check for duplicate

select transaction_id,count(transaction_id)
from sales 
group by transaction_id
having count(transaction_id)>1

TXN240646
TXN342128
TXN626832
TXN745076
TXN832908
TXN855235
TXN981773

--using window function

with CTE as (
select *,
    ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY transaction_id) AS ROW_NUM
from sales
)
--delete from CTE
--where ROW_NUM=2
select * from CTE
Where transaction_id in ('TXN240646' ,'TXN342128' ,'TXN626832', 'TXN745076', 'TXN832908', 'TXN855235', 'TXN981773')

--step - 2: Correction of headers
SELECT * FROM sales

EXEC sp_rename'sales.quantiy','quantity','COLUMN'

EXEC sp_rename 'sales.prce','price','COLUMN'

-- Step-3 :- To check datatype

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME= 'sales'

--Step-4: To check null values

--to check null count

DECLARE @SQL NVARCHAR(MAX) = '';

SELECT @SQL = STRING_AGG(
 'SELECT ''' + COLUMN_NAME + ''' AS ColumnName, 
 COUNT(*) AS NullCount
 FROM ' + QUOTENAME(TABLE_SCHEMA) + '.sales
 WHERE' + QUOTENAME( COLUMN_NAME) + ' IS NULL' ,
 ' UNION ALL '
)
WITHIN GROUP (ORDER BY COLUMN_NAME)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'sales';


-- Execute the dynamic SQL
EXEC sp_executesql @SQL;


--treating null values

select * from sales
where  transaction_id is null
or 
customer_id is null
OR
customer_name is NULL
OR
customer_age is NULL
or 
gender is NULL
or 
product_id is NULL
or 
product_name IS NULL
or 
product_category is null 
OR
quantity IS NULL 
OR
price is null 
or 
payment_mode is NULL
OR
purchaase_date is NULL
or 
time_of_purpose is null
OR
status is null


--deleting outlier
delete from sales 
where transaction_id is null

--treating null values

select * from sales
where Customer_name='Ehsaan Ram'

update sales
set customer_id='CUST9494'
where transaction_id='TXN977900'

select * from sales
where Customer_name='Damini Raju'

update sales
set customer_id='CUST1401'
where transaction_id='TXN985663'

select * from sales
where customer_id='CUST1003'

update sales
set customer_name='Mahika Saini', customer_age='35', gender='Male'
where transaction_id='TXN432798'

--step-5: dat cleaning

--cleaning gender column

select distinct gender 
from sales

update sales
set gender='F'
WHERE gender ='Female'

update sales
set gender='M'
WHERE gender ='Male'


select * from sales

--cleaning Payment_mode column

select distinct payment_mode
from sales

update sales
set payment_mode='Credit Card'
WHERE payment_mode ='CC'


---Data Analysis--
--1.What are the top 5 most selling products by quantity?

select product_name,status
from sales
where status='delivered'

--cleaning status using chatgpt
SELECT DISTINCT 
  status AS original_status,
  TRIM(REPLACE(REPLACE(status, CHAR(13), ''), CHAR(10), '')) AS cleaned_status
FROM sales;

UPDATE sales
SET status = TRIM(REPLACE(REPLACE(status, CHAR(13), ''), CHAR(10), ''));

SELECT DISTINCT status FROM sales;

UPDATE sales
SET status = LTRIM(RTRIM(REPLACE(REPLACE(status, CHAR(13), ''), CHAR(10), '')));

--1.What are the top 5 most selling products by quantity?
select top 5 product_name,sum(quantity) as total_sold
from sales
where status='delivered'
group by product_name
order by total_sold desc 

--Business Problem: We don't know which products are most in demand.

--Business Impact: Helps prioritize stock and boost sales through targeted promotions. 

--2.Which products are mostly cancelled?
select top 5  product_name,Count(*) As total_canceled
from sales 
where status = 'cancelled'
Group by product_name
order by total_canceled desc

--Business problem: Frequent cancellation affect revenue and customer trust
--Business Impact: Identify poor performing products to improve quality or remove from catalogue

--3.what time of the day has the highest number of purchases?
select * from sales
select 
   Case 
       when DATEPART(hour,time_of_purpose) Between 0 and 5 then 'Night'
       when DATEPART(hour,time_of_purpose) Between 6 and 11 then 'Morning'
       when DATEPART(hour,time_of_purpose) Between 12 and 17 then 'Afternoon'
       when DATEPART(hour,time_of_purpose) Between 18 and 23 then 'Evening'
    end as time_of_day,
    count(*) AS total_orders
From sales
Group BY
    case
        when DATEPART(hour,time_of_purpose) Between 0 and 5 then 'Night'
       when DATEPART(hour,time_of_purpose) Between 6 and 11 then 'Morning'
       when DATEPART(hour,time_of_purpose) Between 12 and 17 then 'Afternoon'
       when DATEPART(hour,time_of_purpose) Between 18 and 23 then 'Evening'
    end 

order by total_orders desc

--Business Problem: Find Peak sales times
--Business Impact: Optimize staffing,promotions, and server loads


--4.who are the top 5 highest spending customers?
select * from sales


SELECT TOP 5 
    customer_name,   
    CAST(SUM(price * quantity) AS MONEY) AS total_spend
FROM sales
GROUP BY customer_name
ORDER BY total_spend DESC;

--Business Problem: Identify VIP customers
--Business Impact: Personalized offers,loyalty rewards, and retention

 

--5.Which product categories generate the highest revenue?
select * from sales


select product_category ,
    cast(Sum(price * quantity) As Money )as Revenue
from sales
group by product_category
order by Revenue Desc

--Business Problem: Identify top-performing product categories
--Business Impact: Refine product strategy,supply chain,and promotions.
--allowing the business to invest more in high-margin or high-demand categories


--6.what is the return/cancellation rate per product category?
select * from sales
SELECT product_category,
    COUNT(CASE WHEN status IN ('returned') THEN 1 END) * 100.0 / COUNT(*)  AS cancel_rate
FROM sales
GROUP BY product_category
ORDER BY cancel_rate DESC;

SELECT product_category,
    COUNT(CASE WHEN status IN ('returned') THEN 1 END) * 100.0 / COUNT(*) AS return_rate
FROM sales
GROUP BY product_category
ORDER BY return_rate DESC;

--Business Problem: MOnitor dissatisfaction trends per category
--Business Impact: Reduce returns, improve product descriptions/expectations.
--Helps identify and fix product or logistics issues.


--7.What is most preferred payment mode?
select * from sales

select payment_mode,count(*) As total_count
from sales
group by payment_mode
order by total_count  DESC 

--business problem: Know which payment options customers prefered
--business impact: Streamline payment processing,prioritize popular modes.

--8.how does age group afect purchasing behaviour?
select * from sales
select 
    CASE 
        when customer_age Between 18 and 25 then '18-25'
        when customer_age Between 26 and 35 then '26-35'
        when customer_age Between 36 and 50 then '36-50'
        else '51+'
    End as customer_age,
   sum(price*quantity) As total_purchase
from sales
Group by case 
         when customer_age Between 18 and 25 then '18-25'
        when customer_age Between 26 and 35 then '26-35'
        when customer_age Between 36 and 50 then '36-50'
        else '51+'
    End
order by total_purchase DESC

--Business problem: Understand Customer demographics
--Business Impact:Targeted marketing and product recommendations by age group

--9.whats monthly sales trend?

select * from sales

--Method 1
SELECT 
    year(purchaase_date) as years,
    month(purchaase_date) as months,
    sum(price*quantity) As total_sales,
    sum(quantity) as total_quantity
FROM sales 
group by year(purchaase_date),Month(purchaase_date)
Order by months

--Business problem: sales fluctuations go unnoticed
--business Impact: plan inventory and marketing according to seasonal trends



--10.Are Certain gender buying more specific product categories?

select * from sales

select gender,product_category,count(product_category) as total_purchase
from  sales
group by gender,product_category
order by gender 

--method 2
select * 
FROM (
    select gender,product_category
    from sales
    ) as source_table
PIVOT (
    count(gender)
    for gender in ([M],[F])    
    ) as pivot_table
order by product_category 

--Business Problem: Gender-based product preferences
--business Impact: Personalized ads, gender-focused campaigns