--Группировки и агрегатные функции
--1. Посчитать среднюю цену товара, общую сумму продажи по месяцам
SELECT
FORMAT(i.InvoiceDate,'yyyyMM') as MonthInvoiceDate
,AVG(il.UnitPrice) as AVGUnitPrice
,SUM(il.UnitPrice * il.Quantity) as Amount

FROM Sales.Invoices i
INNER JOIN Sales.InvoiceLines il on i.InvoiceID = il.InvoiceID
GROUP BY 
FORMAT(i.InvoiceDate,'yyyyMM')


--2. Отобразить все месяцы, где общая сумма продаж превысила 10 000
SELECT
FORMAT(i.InvoiceDate,'yyyyMM') as MonthInvoiceDate
,AVG(il.UnitPrice) as AVGUnitPrice
,SUM(il.UnitPrice * il.Quantity) as Amount

FROM Sales.Invoices i
INNER JOIN Sales.InvoiceLines il on i.InvoiceID = il.InvoiceID
GROUP BY 
FORMAT(i.InvoiceDate,'yyyyMM')
HAVING SUM(il.UnitPrice * il.Quantity) > 10000

--3. Вывести сумму продаж, дату первой продажи и количество проданного по месяцам, 
--по товарам, продажи которых менее 50 ед в месяц.
--Группировка должна быть по году и месяцу.
SELECT
si.StockItemName
,FORMAT(i.InvoiceDate,'yyyyMM') as MonthInvoiceDate
,SUM(il.UnitPrice * il.Quantity) as Amount
,MIN(i.InvoiceDate) as MINInvoiceDate
,SUM(il.Quantity) as Quantity
,AVG(il.UnitPrice) as AVGUnitPrice

FROM Sales.Invoices i
INNER JOIN Sales.InvoiceLines il on i.InvoiceID = il.InvoiceID
INNER JOIN Warehouse.StockItems si on si.StockItemID =  il.StockItemID
GROUP BY si.StockItemName,
FORMAT(i.InvoiceDate,'yyyyMM')
HAVING SUM(il.Quantity) < 50

--4. Написать рекурсивный CTE sql запрос и заполнить им временную таблицу и табличную переменную

;WITH  MyEmpl as
(
SELECT 
EmployeeID
,CONVERT(varchar(255), FirstName + ' ' + LastName) as Name
,Title 
,1 EmployeeLevel
FROM MyEmployees 
WHERE ManagerID IS NULL

UNION ALL 
SELECT 
e.EmployeeID

,CONVERT(varchar(255), REPLICATE ('|    ' , EmployeeLevel) + e.FirstName + ' ' + e.LastName) as Name
                                        
,e.Title 
,c.EmployeeLevel +1
FROM MyEmpl c
JOIN MyEmployees e ON e.ManagerID = c.EmployeeID
)
select * from MyEmpl




