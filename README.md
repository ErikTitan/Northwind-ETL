# **ETL proces Northwind databázy**

Tento repozitár obsahuje implementáciu ETL procesu v Snowflake pre analýzu dát z **Northwind** databázy. Projekt sa zameriava na analýzu predajov, produktov a zákazníkov pomocou viacdimenzionálneho dátového modelu, ktorý umožňuje komplexnú analýzu obchodných metrík.

---
## **1. Úvod a popis zdrojových dát**
Cieľom semestrálneho projektu je analyzovať obchodné dáta týkajúce sa predajov, produktov, zákazníkov a dodávateľov. Táto analýza umožňuje identifikovať predajné trendy, výkonnosť produktov a správanie zákazníkov.

Zdrojové dáta pochádzajú z Northwind databázy, ktorá obsahuje osem hlavných tabuliek:
- `Categories` - kategórie produktov
- `Customers` - informácie o zákazníkoch
- `Employees` - údaje o zamestnancoch
- `OrderDetails` - detaily objednávok
- `Orders` - objednávky
- `Products` - produkty
- `Shippers` - prepravcovia
- `Suppliers` - dodávatelia

Účelom ETL procesu je transformovať tieto transakčné dáta do formátu vhodného pre Business Intelligence analýzu.

---
### **1.1 Dátová architektúra**

### **ERD diagram**
Surové dáta sú usporiadané v relačnom modeli, ktorý je znázornený na **entitno-relačnom diagrame (ERD)**:

<p align="center">
  <img src="https://github.com/ErikTitan/Northwind-ETL/blob/master/erd_schema.png" alt="ERD Schema">
  <br>
  <em>Obrázok 1 Entitno-relačná schéma Northwind databázy</em>
</p>

---
## **2 Dimenzionálny model**

Pre efektívnu analýzu dát bol navrhnutý **hviezdicový model (star schema)**, kde centrálnym bodom je faktová tabuľka **`fact_orderdetails`**, ktorá je prepojená s nasledujúcimi dimenziami:

- **`dim_shippers`**: Obsahuje informácie o prepravcoch
- **`dim_customers`**: Údaje o zákazníkoch vrátane kontaktných informácií a lokality
- **`dim_employees`**: Informácie o zamestnancoch
- **`dim_categories`**: Kategórie produktov a ich popisy
- **`dim_suppliers`**: Údaje o dodávateľoch
- **`dim_products`**: Informácie o produktoch vrátane cien
- **`dim_date`**: Časová dimenzia obsahujúca hierarchické členenie dátumov
- **`dim_time`**: Časová dimenzia pre analýzu na úrovni hodín

Faktová tabuľka `fact_orderdetails` obsahuje kľúčové metriky ako:
- Finálna cena (FinalPrice)
- Množstvo (Quantity)
- Prepojenia na všetky relevantné dimenzie

<p align="center">
  <img src="https://github.com/ErikTitan/Northwind-ETL/blob/master/star_schema.png" alt="Star Schema">
  <br>
  <em>Obrázok 2: Hviezdicová schéma Northwind dátového skladu</em>
</p>

---
## **3. ETL proces v Snowflake**
ETL proces pozostáva z troch hlavných fáz: `extrahovanie` (Extract), `transformácia` (Transform) a `načítanie` (Load). Proces je implementovaný v Snowflake s využitím staging vrstvy a následnou transformáciou do dimenzionálneho modelu.


### **3.1 Extract (Extrahovanie dát)**
V prvej fáze sú dáta nahrané do Snowflake pomocou interného stage priestoru `CAT_stage`. Vytvorenie stage priestoru je realizované príkazom:

#### Príklad kódu:
```sql
CREATE OR REPLACE STAGE CAT_stage;
```
Následne sú dáta importované do staging tabuliek pomocou príkazu COPY INTO. Príklad importu dát pre tabuľku categories:

```sql
COPY INTO categories_staging
FROM @CAT_stage/northwind_table_categories.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);
```

---
### **3.2 Transform (Transformácia dát)**

Transformačná fáza zahŕňa vytvorenie dimenzionálneho modelu v schéme CAT_Northwind.DWH. Kľúčové transformácie zahŕňajú:

- Vytvorenie časových dimenzií (dim_date a dim_time) s odvodeními atribútmi
- Mapovanie staging tabuliek na dimenzionálne tabuľky
- Výpočet metrík vo faktovej tabuľke (napr. FinalPrice)

### Dimenzie a ich SCD typy:

#### 1. dim_shippers (SCD Typ 1)
Dimenzia prepravcov - aktualizuje sa pri zmene údajov prepravcu
```sql
CREATE TABLE dim_shippers (
  dim_shipperID INTEGER PRIMARY KEY,
  ShipperName VARCHAR(25),
  Phone VARCHAR(15)
);
```
#### 2. dim_customers (SCD Typ 2)
Dimenzia zákazníkov - sleduje historické zmeny v údajoch zákazníkov
```sql
CREATE TABLE dim_customers (
  dim_customerID INTEGER PRIMARY KEY,
  CustomerName VARCHAR(50),
  ContactName VARCHAR(50),
  Address VARCHAR(50),
  City VARCHAR(20),
  PostalCode VARCHAR(10),
  Country VARCHAR(15)
);
```
#### 3. dim_employees (SCD Typ 1)
Dimenzia zamestnancov - udržiava aktuálne informácie o zamestnancoch
```sql
CREATE TABLE dim_employees (
  dim_employeeID INTEGER PRIMARY KEY,
  LastName VARCHAR(15),
  FirstName VARCHAR(15),
  BirthDate DATETIME
);
```
#### 4. dim_categories (SCD Typ 1)
Dimenzia kategórií - obsahuje aktuálne kategórie produktov
```sql
CREATE TABLE dim_categories (
  dim_categoryID INTEGER PRIMARY KEY,
  CategoryName VARCHAR(25),
  Description VARCHAR(255)
);
```
#### 5. dim_suppliers (SCD Typ 2)
Dimenzia dodávateľov - sleduje zmeny v údajoch dodávateľov v čase
```sql
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
```
#### 6. dim_products (SCD Typ 2)
Dimenzia produktov - zachováva históriu zmien v cenách a detailoch produktov
```sql
CREATE TABLE dim_products (
  dim_productID INTEGER PRIMARY KEY,
  ProductName VARCHAR(50),
  Unit VARCHAR(25),
  Price DECIMAL(10,2)
);
```
#### 7. dim_date (SCD Typ 0)
Časová dimenzia pre dátum - nemenné časové údaje
```sql
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
```
#### 8. dim_time (SCD Typ 0)
Časová dimenzia pre hodiny - nemenné časové údaje
```sql
CREATE TABLE dim_time (
  dim_timeID INTEGER PRIMARY KEY,
  timestamp TIME,
  hour INTEGER,
  ampm VARCHAR(2)
);
```

Následne naplníme dimenzie údajmi zo staging tabuliek. Príklad pre dimenziu dim_date:

```sql
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
```

Faktová tabuľka `fact_orderdetails` je centrálna faktová tabuľka, ktorá obsahuje transakčné dáta s vypočítanou metrikou FinalPrice a prepojeniami na všetky dimenzie. Táto štruktúra umožňuje analýzu predajov z rôznych pohľadov:

```sql
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
```
Tento návrh umožňuje efektívne analyzovať:

- Predaje podľa časových období
- Výkonnosť produktov a kategórií
- Aktivitu zákazníkov
- Efektivitu zamestnancov

---
### **3.3 Load (Načítanie dát)**

V tejto fáze sa dáta zo staging oblasti načítavajú do dimenzionálnych tabuliek:

```sql
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
```

Po úspešnej transformácii dát do dimenzionálneho modelu je možné odstrániť staging tabuľky pre optimalizáciu využitia úložiska. Odstránenie staging tabuliek sa vykoná nasledovnými príkazmi:

```sql
DROP TABLE IF EXISTS Categories_staging;
DROP TABLE IF EXISTS Customers_staging;
DROP TABLE IF EXISTS Employees_staging;
DROP TABLE IF EXISTS OrderDetails_staging;
DROP TABLE IF EXISTS Orders_staging;
DROP TABLE IF EXISTS Products_staging;
DROP TABLE IF EXISTS Shippers_staging;
DROP TABLE IF EXISTS Suppliers_staging;
```

---
## **4 Vizualizácia dát**

Dashboard kombinuje osem kľúčových vizualizácií:

1. **KPI Metriky**
   - Celkové tržby
   - Počet objednávok
   - Počet unikátnych zákazníkov

2. **Produktová analýza**
   - Predaje podľa kategórií
   - Top 5 najvýkonnejších produktov

3. **Geografická analýza**
   - Distribúcia tržieb podľa krajín

4. **Časové trendy**
   - Vývoj počtu zákazníkov
   - Mesačné tržby

<p align="center">
  <img src="https://github.com/ErikTitan/Northwind-ETL/blob/master/dashboard.png" alt="Dashboard">
  <br>
  <em>Obrázok 3 Dashboard Northwind databázy</em>
</p>

---
### **Implementované pohľady**

Pre efektívnu analýzu dát boli vytvorené pohľady (views) v samostatnom súbore views.sql, ktoré slúžia ako základ pre dashboardy a reporty. Tieto pohľady zjednodušujú prístup k často potrebným metrikám a agregáciám.

#### **1. Predaje podľa kategórií (v_sales_by_category)**
Tento pohľad agreguje predaje a množstvá podľa produktových kategórií:

```sql
CREATE OR REPLACE VIEW v_sales_by_category AS
SELECT 
    c.CategoryName,
    SUM(f.FinalPrice) as TotalSales,
    SUM(f.Quantity) as TotalQuantity
FROM fact_orderdetails f
JOIN dim_categories c ON f.CategoryID = c.dim_categoryID
GROUP BY c.CategoryName;
```

#### **2. Trendy predajov v čase (v_sales_trends)**
Analýza mesačných predajov a počtu unikátnych zákazníkov:
```sql
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
```

#### **3. Najvýkonnejšie produkty (v_top_products)**
Pohľad na celkovú výkonnosť jednotlivých produktov:

```sql
CREATE OR REPLACE VIEW v_top_products AS
SELECT 
    p.ProductName,
    SUM(f.FinalPrice) as TotalRevenue,
    SUM(f.Quantity) as TotalQuantity,
    COUNT(DISTINCT f.CustomerID) as UniqueCustomers
FROM fact_orderdetails f
JOIN dim_products p ON f.ProductID = p.dim_productID
GROUP BY p.ProductName;
```

#### **4. Analýza zákazníkov (v_customer_metrics)**
Geografická analýza zákazníkov a tržieb:

```sql
CREATE OR REPLACE VIEW v_customer_metrics AS
SELECT 
    c.Country,
    c.City,
    COUNT(DISTINCT f.CustomerID) as CustomerCount,
    SUM(f.FinalPrice) as TotalRevenue
FROM fact_orderdetails f
JOIN dim_customers c ON f.CustomerID = c.dim_customerID
GROUP BY c.Country, c.City;
```

### **Hlavné metriky dashboardu**

Dashboard začína trojicou kľúčových ukazovateľov výkonnosti (KPIs), ktoré poskytujú okamžitý prehľad o celkovej výkonnosti predaja:

#### **Graf 1: Celkové tržby**
```sql
SELECT 
    SUM(FinalPrice) AS TotalRevenue
FROM fact_orderdetails;
```
#### **Graf 2: Celkový počet objednávok**
```sql
SELECT 
    COUNT(DISTINCT OrderID) AS TotalOrders
FROM fact_orderdetails;
```
#### **Graf 3: Počet unikátnych zákazníkov**
```sql
SELECT 
    COUNT(DISTINCT CustomerID) AS UniqueCustomers
FROM fact_orderdetails;
```

Tieto metriky sú umiestnené v hornej časti dashboardu a poskytujú rýchly prehľad o celkovej obchodnej výkonnosti. Umožňujú manažmentu okamžite vidieť kľúčové čísla bez potreby hlbšej analýzy.

---
### **Analýza produktov a kategórií**

Pod hlavnými KPI metrikami sa nachádzajú dva grafy poskytujúce detailný pohľad na výkonnosť produktov:

#### **Graf 4: Predaje podľa kategórií produktov**
```sql
SELECT CategoryName, TotalSales 
FROM v_sales_by_category 
ORDER BY TotalSales DESC;
```

Tento graf zobrazuje celkové tržby rozdelené podľa kategórií produktov. Vizualizácia pomáha identifikovať najvýkonnejšie produktové kategórie a potenciálne príležitosti pre optimalizáciu portfólia produktov.

#### **Graf 5: Top 5 najpredávanejších produktov**

```sql
SELECT ProductName, TotalRevenue, TotalQuantity
FROM v_top_products
ORDER BY TotalRevenue DESC
LIMIT 5;
```

Stĺpcový graf zobrazuje päť produktov s najvyššími tržbami. Pre každý produkt sú zobrazené celkové tržby aj predané množstvo, čo umožňuje rýchlu identifikáciu najpopulárnejších produktov v portfóliu.

---
### **Geografická analýza tržieb**

Pod analýzou produktov sa nachádza vizualizácia geografickej distribúcie tržieb.

#### **Graf 6: Tržby podľa krajín**
```sql
SELECT 
    Country,
    SUM(TotalRevenue) as CountryRevenue
FROM v_customer_metrics
GROUP BY Country
ORDER BY CountryRevenue DESC;
```
Tento graf poskytuje prehľad o výkonnosti predaja v jednotlivých krajinách. Vizualizácia umožňuje:

- Identifikovať najvýznamnejšie trhy z hľadiska tržieb
- Odhaliť potenciálne príležitosti na menej výkonných trhoch
- Podporiť rozhodovanie o geografickej expanzii alebo optimalizácii distribúcie

---
### **Časové trendy a vývoj**

Spodná časť dashboardu obsahuje dva líniové grafy zobrazujúce kľúčové trendy v čase.

#### **Graf 7: Vývoj počtu unikátnych zákazníkov**
```sql
SELECT 
    DATE_FROM_PARTS(year, month, 1) AS YearMonth,
    SUM(UniqueCustomers) AS UniqueCustomers
FROM v_sales_trends
GROUP BY year, month
ORDER BY YearMonth;
```
Tento graf sleduje mesačný vývoj počtu aktívnych zákazníkov, čo pomáha pochopiť sezónne vzory v zákazníckej aktivite a efektivitu akvizičných stratégií.

#### **Graf 8: Mesačné tržby**
```sql
SELECT 
    DATE_FROM_PARTS(year, month, 1) AS YearMonth,
    SUM(MonthlySales) AS MonthlySales
FROM v_sales_trends
GROUP BY year, month
ORDER BY YearMonth;
```
Líniový graf zobrazuje vývoj mesačných tržieb v čase. Táto vizualizácia umožňuje:

- Sledovať dlhodobé trendy v predajoch
- Identifikovať sezónne výkyvy
- Vyhodnocovať úspešnosť predajných kampaní
- Kombinácia týchto dvoch grafov poskytuje komplexný pohľad na vzťah medzi počtom zákazníkov a generovanými -tržbami v čase.

---
## **5 Záver**

Tento projekt predstavuje komplexnú implementáciu ETL procesu pre Northwind databázu v prostredí Snowflake, ktorý pozostáva z nasledujúcich kľúčových komponentov:

### **ETL Proces**
- Vytvorenie staging vrstvy pre počiatočné načítanie dát
- Transformácia do dimenzionálneho modelu typu hviezda
- Implementácia časových dimenzií pre detailnú časovú analýzu
- Vytvorenie faktovej tabuľky s prepojením na všetky dimenzie

### **Analytická vrstva**
- Implementácia analytických pohľadov (views) pre zjednodušenie prístupu k dátam
- Vytvorenie komplexného dashboardu s KPI metrikami
- Analýza predajov podľa rôznych dimenzií (čas, geografia, produkty)
- Sledovanie trendov a vývoja kľúčových metrík

### **Prínosy riešenia**
- Efektívna analýza predajných dát
- Možnosť sledovania výkonnosti produktov a kategórií
- Geografická analýza predajov
- Monitoring zákazníckej aktivity
- Podpora pre informované biznis rozhodnutia

Implementované riešenie poskytuje robustný základ pre ďalšie rozšírenia a optimalizácie podľa budúcich analytických potrieb.

---

**Autor:** Erik Sháněl
