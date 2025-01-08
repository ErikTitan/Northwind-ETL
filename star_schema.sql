CREATE SCHEMA CAT_Northwind.DWH;
USE SCHEMA CAT_Northwind.DWH;

CREATE TABLE dim_shippers (
  dim_shipperID INTEGER PRIMARY KEY,
  ShipperName VARCHAR(25),
  Phone VARCHAR(15)
);

CREATE TABLE dim_customers (
  dim_customerID INTEGER PRIMARY KEY,
  CustomerName VARCHAR(50),
  ContactName VARCHAR(50),
  Address VARCHAR(50),
  City VARCHAR(20),
  PostalCode VARCHAR(10),
  Country VARCHAR(15)
);

CREATE TABLE dim_employees (
  dim_employeeID INTEGER PRIMARY KEY,
  LastName VARCHAR(15),
  FirstName VARCHAR(15),
  BirthDate DATETIME
);

CREATE TABLE dim_categories (
  dim_categoryID INTEGER PRIMARY KEY,
  CategoryName VARCHAR(25),
  Description VARCHAR(255)
);

CREATE TABLE dim_suppliers (
  dim_supplierID INTEGER PRIMARY KEY,
  SupplierName VARCHAR(50),
  ContactName VARCHAR(50),
  Address VARCHAR(50),
  City VARCHAR(20),
  PostalCode VARCHAR(10),
  Country VARCHAR(15),
  Phone VARCHAR(15)
);

CREATE TABLE dim_products (
  dim_productID INTEGER PRIMARY KEY,
  ProductName VARCHAR(50),
  Unit VARCHAR(25),
  Price DECIMAL(10,2)
);

CREATE TABLE dim_date (
  dim_dateID INTEGER PRIMARY KEY,
  timestamp DATE,
  day INTEGER,
  dayOfWeek INTEGER,
  dayOfWeekAsString VARCHAR(45),
  month INTEGER,
  monthAsString VARCHAR(45),
  year INTEGER,
  week INTEGER,
  quarter INTEGER
);

CREATE TABLE dim_time (
  dim_timeID INTEGER PRIMARY KEY,
  timestamp TIME,
  hour INTEGER,
  ampm VARCHAR(2)
);

CREATE TABLE fact_orderdetails (
  fact_orderdetailID INTEGER PRIMARY KEY,
  FinalPrice DECIMAL(10,2),
  Quantity INTEGER,
  OrderDate DATETIME,
  OrderID INTEGER,
  ShipperID INTEGER,
  CustomerID INTEGER,
  EmployeeID INTEGER,
  CategoryID INTEGER,
  SupplierID INTEGER,
  ProductID INTEGER,
  DateID INTEGER,
  TimeID INTEGER,
  FOREIGN KEY (ShipperID) REFERENCES dim_shippers (dim_shipperID),
  FOREIGN KEY (CustomerID) REFERENCES dim_customers (dim_customerID),
  FOREIGN KEY (EmployeeID) REFERENCES dim_employees (dim_employeeID),
  FOREIGN KEY (CategoryID) REFERENCES dim_categories (dim_categoryID),
  FOREIGN KEY (SupplierID) REFERENCES dim_suppliers (dim_supplierID),
  FOREIGN KEY (ProductID) REFERENCES dim_products (dim_productID),
  FOREIGN KEY (DateID) REFERENCES dim_date (dim_dateID),
  FOREIGN KEY (TimeID) REFERENCES dim_time (dim_timeID)
);

-- ETL Proces
INSERT INTO dim_shippers 
SELECT * FROM CAT_Northwind.staging.Shippers_staging;

INSERT INTO dim_customers 
SELECT * FROM CAT_Northwind.staging.Customers_staging;

INSERT INTO dim_employees 
SELECT EmployeeID, LastName, FirstName, BirthDate 
FROM CAT_Northwind.staging.Employees_staging;

INSERT INTO dim_categories 
SELECT * FROM CAT_Northwind.staging.Categories_staging;

INSERT INTO dim_suppliers 
SELECT * FROM CAT_Northwind.staging.Suppliers_staging;

INSERT INTO dim_products 
SELECT ProductID, ProductName, Unit, Price 
FROM CAT_Northwind.staging.Products_staging;

INSERT INTO dim_date 
SELECT 
    ROW_NUMBER() OVER (ORDER BY OrderDate) as dim_dateID,
    DATE(OrderDate) as timestamp,
    DAYOFMONTH(OrderDate) as day,
    DAYOFWEEK(OrderDate) as dayOfWeek,
    DAYNAME(OrderDate) as dayOfWeekAsString,
    MONTH(OrderDate) as month,
    MONTHNAME(OrderDate) as monthAsString,
    YEAR(OrderDate) as year,
    WEEKOFYEAR(OrderDate) as week,
    QUARTER(OrderDate) as quarter
FROM (SELECT DISTINCT OrderDate FROM CAT_Northwind.staging.Orders_staging) as distinct_dates;

INSERT INTO dim_time 
SELECT 
    ROW_NUMBER() OVER (ORDER BY time_part) as dim_timeID,
    time_part as timestamp,
    HOUR(time_part) as hour,
    CASE WHEN HOUR(time_part) < 12 THEN 'AM' ELSE 'PM' END as ampm
FROM (
    SELECT DISTINCT TIME(OrderDate) as time_part 
    FROM CAT_Northwind.staging.Orders_staging
) as distinct_times;

INSERT INTO fact_orderdetails
SELECT 
    od.OrderDetailID,
    od.Quantity * p.Price as FinalPrice,
    od.Quantity,
    o.OrderDate,
    o.OrderID,
    o.ShipperID,
    o.CustomerID,
    o.EmployeeID,
    p.CategoryID,
    p.SupplierID,
    od.ProductID,
    d.dim_dateID,
    t.dim_timeID
FROM CAT_Northwind.staging.OrderDetails_staging od
JOIN CAT_Northwind.staging.Orders_staging o ON od.OrderID = o.OrderID
JOIN CAT_Northwind.staging.Products_staging p ON od.ProductID = p.ProductID
JOIN dim_date d ON DATE(o.OrderDate) = d.timestamp
JOIN dim_time t ON TIME(o.OrderDate) = t.timestamp;

