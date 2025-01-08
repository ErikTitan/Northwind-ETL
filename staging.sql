CREATE DATABASE CAT_Northwind;

CREATE SCHEMA CAT_Northwind.staging;

USE SCHEMA CAT_Northwind.staging;

CREATE TABLE Categories_staging
(      
    CategoryID INTEGER PRIMARY KEY,
    CategoryName VARCHAR(25),
    Description VARCHAR(255)
);

CREATE TABLE Customers_staging
(      
    CustomerID INTEGER PRIMARY KEY,
    CustomerName VARCHAR(50),
    ContactName VARCHAR(50),
    Address VARCHAR(50),
    City VARCHAR(20),
    PostalCode VARCHAR(10),
    Country VARCHAR(15)
);

CREATE TABLE Employees_staging
(
    EmployeeID INTEGER PRIMARY KEY,
    LastName VARCHAR(15),
    FirstName VARCHAR(15),
    BirthDate DATETIME,
    Photo VARCHAR(25),
    Notes VARCHAR(1024)
);

CREATE TABLE Shippers_staging(
    ShipperID INTEGER PRIMARY KEY,
    ShipperName VARCHAR(25),
    Phone VARCHAR(15)
);

CREATE TABLE Suppliers_staging(
    SupplierID INTEGER PRIMARY KEY,
    SupplierName VARCHAR(50),
    ContactName VARCHAR(50),
    Address VARCHAR(50),
    City VARCHAR(20),
    PostalCode VARCHAR(10),
    Country VARCHAR(15),
    Phone VARCHAR(15)
);

CREATE TABLE Products_staging(
    ProductID INTEGER PRIMARY KEY,
    ProductName VARCHAR(50),
    SupplierID INTEGER,
    CategoryID INTEGER,
    Unit VARCHAR(25),
    Price NUMERIC,
	FOREIGN KEY (CategoryID) REFERENCES Categories_staging (CategoryID),
	FOREIGN KEY (SupplierID) REFERENCES Suppliers_staging (SupplierID)
);

CREATE TABLE Orders_staging(
    OrderID INTEGER PRIMARY KEY,
    CustomerID INTEGER,
    EmployeeID INTEGER,
    OrderDate DATETIME,
    ShipperID INTEGER,
    FOREIGN KEY (EmployeeID) REFERENCES Employees_staging (EmployeeID),
    FOREIGN KEY (CustomerID) REFERENCES Customers_staging (CustomerID),
    FOREIGN KEY (ShipperID) REFERENCES Shippers_staging (ShipperID)
);

CREATE TABLE OrderDetails_staging(
    OrderDetailID INTEGER PRIMARY KEY,
    OrderID INTEGER,
    ProductID INTEGER,
    Quantity INTEGER,
	FOREIGN KEY (OrderID) REFERENCES Orders_staging (OrderID),
	FOREIGN KEY (ProductID) REFERENCES Products_staging (ProductID)
);

CREATE OR REPLACE STAGE CAT_stage;

COPY INTO suppliers_staging
FROM @CAT_stage/northwind_table_suppliers.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO shippers_staging
FROM @CAT_stage/northwind_table_shippers.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO products_staging
FROM @CAT_stage/northwind_table_products.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO orders_staging
FROM @CAT_stage/northwind_table_orders.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO orderdetails_staging
FROM @CAT_stage/northwind_table_orderdetails.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO employees_staging
FROM @CAT_stage/northwind_table_employees.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO customers_staging
FROM @CAT_stage/northwind_table_customers.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO categories_staging
FROM @CAT_stage/northwind_table_categories.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);