-- Sales by Category
CREATE OR REPLACE VIEW v_sales_by_category AS
SELECT 
    c.CategoryName,
    SUM(f.FinalPrice) as TotalSales,
    SUM(f.Quantity) as TotalQuantity
FROM fact_orderdetails f
JOIN dim_categories c ON f.CategoryID = c.dim_categoryID
GROUP BY c.CategoryName;

-- Sales Trends Over Time
CREATE OR REPLACE VIEW v_sales_trends AS
SELECT 
    d.year,
    d.month,
    d.monthAsString,
    SUM(f.FinalPrice) as MonthlySales,
    COUNT(DISTINCT f.CustomerID) as UniqueCustomers
FROM fact_orderdetails f
JOIN dim_date d ON f.DateID = d.dim_dateID
GROUP BY d.year, d.month, d.monthAsString
ORDER BY d.year, d.month;

-- Top Performing Products
CREATE OR REPLACE VIEW v_top_products AS
SELECT 
    p.ProductName,
    SUM(f.FinalPrice) as TotalRevenue,
    SUM(f.Quantity) as TotalQuantity,
    COUNT(DISTINCT f.CustomerID) as UniqueCustomers
FROM fact_orderdetails f
JOIN dim_products p ON f.ProductID = p.dim_productID
GROUP BY p.ProductName;

-- Customer Analysis
CREATE OR REPLACE VIEW v_customer_metrics AS
SELECT 
    c.Country,
    c.City,
    COUNT(DISTINCT f.CustomerID) as CustomerCount,
    SUM(f.FinalPrice) as TotalRevenue
FROM fact_orderdetails f
JOIN dim_customers c ON f.CustomerID = c.dim_customerID
GROUP BY c.Country, c.City;