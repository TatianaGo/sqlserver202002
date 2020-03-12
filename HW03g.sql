--1 Выберите сотрудников, которые являются продажниками, и еще не сделали ни одной продажи.
SELECT
*
FROM Application.People p
WHERE p.IsSalesperson = 1
AND NOT EXISTS (SELECT * FROM Sales.Orders s WHERE s.SalespersonPersonID = p.PersonID )

--2. Выберите товары с минимальной ценой (подзапросом), 2 варианта подзапроса. 
SELECT
s.StockItemName
FROM Warehouse.StockItems s
WHERE s.UnitPrice <= (SELECT MIN(UnitPrice) FROM Warehouse.StockItems )

SELECT
s.StockItemName
FROM Warehouse.StockItems s
WHERE s.UnitPrice <= ALL (SELECT UnitPrice FROM Warehouse.StockItems )

--3. Выберите информацию по клиентам, которые перевели компании 5 максимальных платежей из [Sales].[CustomerTransactions] 
--   представьте 3 способа (в том числе с CTE)
SELECT
sc.CustomerName
,tab1.TransactionAmount
,tab1.TransactionDate
FROM Sales.Customers sc
JOIN (
SELECT TOP 5 WITH TIES
	s.TransactionAmount
	,s.CustomerID
	,s.TransactionDate
	FROM Sales.CustomerTransactions s
	ORDER BY s.TransactionAmount DESC
) as tab1 ON tab1.CustomerID = sc.CustomerID

;WITH cteTopTr as
(
SELECT TOP 5 WITH TIES
	s.TransactionAmount
	,s.CustomerID
	,s.TransactionDate
	FROM Sales.CustomerTransactions s
	ORDER BY s.TransactionAmount DESC
)
SELECT 
c.CustomerName
,cte.TransactionAmount
,cte.TransactionDate
FROM cteTopTr cte
JOIN Sales.Customers c ON  cte.CustomerID = c.CustomerID;

SELECT 
(SELECT
c.CustomerName
FROM Sales.Customers c WHERE c.CustomerID = s.CustomerID) as CustomerName
,s.TransactionAmount
,s.TransactionDate
FROM Sales.CustomerTransactions s
WHERE s.TransactionAmount IN  
	(SELECT TOP 5 WITH TIES
	s.TransactionAmount
	FROM Sales.CustomerTransactions s
	ORDER BY s.TransactionAmount DESC)

--4. Выберите города (ид и название), в которые были доставлены товары, 
--   входящие в тройку самых дорогих товаров, а также Имя сотрудника, который осуществлял упаковку заказов

;WITH
cteTopExpStockItems AS
(
SELECT TOP 3 WITH TIES
UnitPrice
,StockItemID
FROM Warehouse.StockItems s
ORDER BY UnitPrice DESC
),
cteOL AS
(
SELECT DISTINCT
OrderID
FROM  Sales.OrderLines
WHERE StockItemID IN (SELECT StockItemID FROM cteTopExpStockItems)
)
SELECT 
c.DeliveryCityID
,ac.CityName
,ap.FullName
,o.PickedByPersonID
FROM Sales.Orders o
JOIN Sales.Customers c ON c.CustomerID = o.CustomerID
LEFT JOIN Application.People ap ON ap.PersonID = o.PickedByPersonID
LEFT JOIN Application.Cities ac ON ac.CityID = c.DeliveryCityID
WHERE o.OrderID IN (SELECT OrderID FROM cteOL)

--5. Объясните, что делает и оптимизируйте запрос:
--Отгружено товара, для платежей на сумму > 27000
--тк связь на один заказ много платежей, могут возникать ошибки
SELECT
Invoices.InvoiceID,
Invoices.InvoiceDate,
(SELECT People.FullName
FROM Application.People
WHERE People.PersonID = Invoices.SalespersonPersonID
) AS SalesPersonName,

SalesTotals.TotalSumm AS TotalSummByInvoice,

(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
FROM Sales.OrderLines
WHERE OrderLines.OrderId = (SELECT Orders.OrderId
FROM Sales.Orders
WHERE Orders.PickingCompletedWhen IS NOT NULL
AND Orders.OrderId = Invoices.OrderId)
) AS TotalSummForPickedItems

FROM Sales.Invoices
JOIN
(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
FROM Sales.InvoiceLines
GROUP BY InvoiceId
HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
ON Invoices.InvoiceID = SalesTotals.InvoiceID

ORDER BY TotalSumm DESC
go
----------
;WITH cteIL AS --платежи > 27000
	(
	SELECT 
	i.OrderID,
	SUM(il.Quantity*il.UnitPrice) AS TotalSumm
	FROM Sales.Invoices i 
	JOIN Sales.InvoiceLines il on il.InvoiceID = i.InvoiceID

	GROUP BY 
	i.OrderID
	HAVING SUM(Quantity*UnitPrice) > 27000
	),

cteOgr as --Отгружено на сумму 
	(
	SELECT 
	o.OrderId
	,SUM(ol.PickedQuantity * ol.UnitPrice) as TotalSummForPickedItems
	FROM Sales.Orders o
	LEFT JOIN Sales.OrderLines ol ON o.OrderId = ol.OrderId
	WHERE o.PickingCompletedWhen IS NOT NULL
	AND o.OrderId IN (SELECT OrderID FROM cteIL)
	GROUP BY  o.OrderID
	)
SELECT
ii.InvoiceId, 
p.FullName,
i.OrderID,
i.TotalSumm,
o.TotalSummForPickedItems

FROM cteIL i
JOIN cteOgr o ON o.OrderId = i.OrderId
JOIN Sales.Invoices ii ON o.OrderId = ii.OrderId  --тут ошибка, если на один заказ будет несколько платежей
LEFT JOIN Application.People p on p.PersonID = ii.SalespersonPersonID
ORDER BY TotalSumm DESC

--Опциональная часть: 
 --cteDeletedDF Выбираются активные файлы на удаление 
 --cteDeletedDFMatchedRules на одну строку накидываются все строки из #companyCustomRules, в EXISTS выбираются соответствующие правилам 
 









