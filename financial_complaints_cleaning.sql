"You can view the full ETL and Data Cleaning script here"
  

  LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\consumer_complaints' 
INTO TABLE consumer_complaints 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;


create table dim_issues (
issue_id int auto_increment primary key,
issue varchar (250),
sub_issue varchar (250) 
);

INSERT INTO dim_issues (issue, sub_issue)
SELECT DISTINCT
    TRIM(LOWER(COALESCE(nullif(issue, ''),'unknown'))) as issue,
    TRIM(LOWER(COALESCE(nullif(sub_issue, ''),'unknown'))) as sub_issue
FROM consumer_complaints c;

create table dim_products (
product_id int auto_increment primary key,
product varchar (250) not null,
sub_product varchar (250) not null 	
);
INSERT INTO dim_products (product, sub_product)
SELECT DISTINCT
    TRIM(LOWER(COALESCE(NULLIF(c.product, ''),'unknown'))) as product,
    TRIM(LOWER(COALESCE(nullif(c.sub_product, ''), 'missing'))) as sub_product
FROM consumer_complaints c;

CREATE TABLE dim_companies (
    company_id INT AUTO_INCREMENT PRIMARY KEY,
    company VARCHAR(200),
    company_public_response VARCHAR(300),
    company_response_to_consumer VARCHAR(300)
);

INSERT INTO dim_companies (company, company_public_response, company_response_to_consumer)
SELECT DISTINCT
    TRIM(LOWER(COALESCE(c.company,'missing'))) AS company,
    TRIM(LOWER(COALESCE(c.company_public_response,'missing'))) AS company_public_response,
    TRIM(LOWER(COALESCE(c.company_response_to_consumer,'missing'))) AS company_response_to_consumer
FROM consumer_complaints c;

CREATE TABLE dim_locations (
    location_id INT AUTO_INCREMENT PRIMARY KEY,
    state CHAR(2),
    zipcode VARCHAR(150)
);

insert into dim_locations (state, zipcode)
select distinct
case when state is null or trim(state) = '' then '??'
else state end,
case when zipcode is null or upper(trim(zipcode)) = '' then 'missing'
else zipcode end
from consumer_complaints;

create table dim_submitted (
submitted_id int auto_increment primary key,
submitted_via varchar (100)
);
insert into dim_submitted (submitted_via)
select distinct
submitted_via 
from consumer_complaints 
where submitted_via is not null and trim(submitted_via) <> '' ;

create table dim_consumer_behavior (
consumer_behavior_id int auto_increment primary key,
timely_response varchar(50),
consumer_disputed varchar (50)
);

insert into dim_consumer_behavior (timely_response, consumer_disputed)
select distinct
timely_response,
consumer_disputed
 from consumer_complaints;
 
 CREATE TABLE dim_date (
    date_id DATE PRIMARY KEY,
    year INT,
    month INT,
    month_name VARCHAR(20),
    day INT,
    day_of_week INT,
    day_name VARCHAR(20),
    quarter INT
);
INSERT INTO dim_date (date_id, year, month, month_name, day, day_of_week, day_name, quarter)
SELECT DISTINCT
    str_to_date(d, '%m/%d/%Y') as d,
    YEAR(str_to_date(d,'%m/%d/%Y')),
    MONTH(str_to_date(d, '%m/%d/%Y')),
    MONTHNAME(str_to_date(d, '%m/%d/%Y')),
    DAY(str_to_date(d, '%m/%d/%Y')),
    DAYOFWEEK(str_to_date(d, '%m/%d/%Y')),
    DAYNAME(str_to_date(d, '%m/%d/%Y')),
    QUARTER(str_to_date(d, '%m/%d/%Y'))
FROM (
    SELECT date_received AS d FROM consumer_complaints
    UNION
    SELECT date_sent_to_company FROM consumer_complaints
) dates;
 


CREATE TABLE fact_complaints (
    complaint_id INT PRIMARY KEY,
    date_received_id date,
    date_sent_to_company_id date,
    product_id INT,
    issue_id INT,
    company_id INT,
    location_id INT,
    submitted_id INT,
    consumer_behavior_id INT,
    tags VARCHAR(100), 
    consumer_consent_provided VARCHAR(100),
    consumer_complaint_narrative TEXT 
);

INSERT INTO fact_complaints
SELECT 
    c.complaint_id,
    dr.date_id AS date_received_id,
    ds.date_id AS date_sent_to_company_id,
    p.product_id,
    i.issue_id,
    comp.company_id,
    l.location_id,
    s.submitted_id,
    cb.consumer_behavior_id,
    coalesce(NULLIF(TRIM(c.tags), ''), 'missing') as tags,
    coalesce(NULLIF(TRIM(c.consumer_consent_provided), ''), 'missing') as consumer_consent_provided,
    coalesce(c.consumer_complaint_narrative, 'missing') as consumer_complaint_narrative
FROM consumer_complaints c
LEFT JOIN dim_products p ON 
    trim(lower(c.product)) = p.product AND 
    trim(lower(coalesce(c.sub_product, 'missing'))) = p.sub_product
LEFT JOIN dim_issues i
ON TRIM(LOWER(COALESCE(c.issue,'unknown'))) = i.issue
AND TRIM(LOWER(COALESCE(NULLIF(c.sub_issue,''),'unknown'))) = i.sub_issue
LEFT JOIN dim_companies comp ON 
    c.company = comp.company AND 
    COALESCE(c.company_public_response, 'missing') = comp.company_public_response AND
    COALESCE(c.company_response_to_consumer, 'missing') = comp.company_response_to_consumer
LEFT JOIN dim_locations l ON 
    COALESCE(c.state, '??') = l.state AND 
    COALESCE(c.zipcode, 'missing') = l.zipcode
LEFT JOIN dim_submitted s ON 
    c.submitted_via = s.submitted_via
LEFT JOIN dim_consumer_behavior cb ON 
    c.timely_response = cb.timely_response AND 
    c.consumer_disputed = cb.consumer_disputed
LEFT JOIN dim_date dr 
    ON STR_TO_DATE(c.date_received, '%m/%d/%Y') = dr.date_id 
LEFT JOIN dim_date ds 
    ON STR_TO_DATE(c.date_sent_to_company, '%m/%d/%Y') = ds.date_id;




