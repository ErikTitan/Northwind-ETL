--Graf 1:
SELECT 
    SUM(FinalPrice) AS TotalRevenue
FROM fact_orderdetails;

--Graf 2:
SELECT 
    COUNT(DISTINCT OrderID) AS TotalOrders
FROM fact_orderdetails;

--Graf 3:
SELECT 
    COUNT(DISTINCT CustomerID) AS UniqueCustomers
FROM fact_orderdetails;

--Graf 4:
SELECT CategoryName, TotalSales 
FROM v_sales_by_category 
ORDER BY TotalSales DESC;

--Graf 5:
SELECT ProductName, TotalRevenue, TotalQuantity
FROM v_top_products
ORDER BY TotalRevenue DESC
LIMIT 5;

--Graf 6:
SELECT 
    Country,
    SUM(TotalRevenue) as CountryRevenue
FROM v_customer_metrics
GROUP BY Country
ORDER BY CountryRevenue DESC;

--Graf 7:
SELECT 
    DATE_FROM_PARTS(year, month, 1) AS YearMonth,
    SUM(UniqueCustomers) AS UniqueCustomers
FROM v_sales_trends
GROUP BY year, month
ORDER BY YearMonth;

--Graf 8:
SELECT 
    DATE_FROM_PARTS(year, month, 1) AS YearMonth,
    SUM(MonthlySales) AS MonthlySales
FROM v_sales_trends
GROUP BY year, month
ORDER BY YearMonth;