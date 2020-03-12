
--1
SELECT DISTINCT
wsi.StockItemName
FROM Warehouse.StockItems wsi
WHERE wsi.StockItemName like '%urgent%' OR
wsi.StockItemName like 'Animal%'

--2
SELECT
s.SupplierID,
s.SupplierName
FROM Purchasing.Suppliers s
LEFT JOIN Purchasing.PurchaseOrders p ON s.SupplierID = p.SupplierID
WHERE p.SupplierID IS NULL

--3
SELECT
o.OrderID
,o.OrderDate
,DATEPART(MONTH,o.OrderDate) as OrderMonth
,DATEPART (QUARTER,o.OrderDate) as OrderQuarter
,CASE WHEN DATEPART (MONTH,o.OrderDate) in(1,2,3,4) 
			THEN 1
	  WHEN DATEPART (MONTH,o.OrderDate) in(5,6,7,8)
			THEN 2
	  ELSE 3 END as OrderTret
,ol.PickingCompletedWhen
FROM Sales.Orders o 
LEFT JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
WHERE 
ol.UnitPrice > 1000 OR ol.Quantity > 20
ORDER BY OrderQuarter, OrderTret, o.OrderDate 
OFFSET 1000 ROWS FETCH FIRST 100 ROWS ONLY;

--4
SELECT
dm.DeliveryMethodName
,po.ExpectedDeliveryDate
,s.SupplierName
,p.FullName as ContactPerson
FROM Purchasing.PurchaseOrders po
LEFT JOIN Application.DeliveryMethods dm on dm.DeliveryMethodID = po.DeliveryMethodID
LEFT JOIN Purchasing.Suppliers s on s.SupplierID = po.SupplierID
LEFT JOIN Application.People p on p.PersonID = po.ContactPersonID
WHERE
po.OrderDate >= '2014-01-01' AND po.OrderDate < '2015-01-01'and
(dm.DeliveryMethodName ='Road Freight' or dm.DeliveryMethodName = 'Post')

--5
SELECT TOP 10 
c.CustomerName
,p.FullName as SalespersonPerson
,o.OrderDate
FROM Sales.Orders o
LEFT JOIN Sales.Customers c on c.CustomerID = o.CustomerID
LEFT JOIN Application.People p on p.PersonID = o.SalespersonPersonID
ORDER BY o.OrderDate desc

--6
SELECT DISTINCT
o.CustomerID
,c.CustomerName
,c.PhoneNumber
FROM Sales.Orders o 
LEFT JOIN Sales.Customers c ON c.CustomerID = o.CustomerID
LEFT JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
LEFT JOIN Warehouse.StockItems si ON si.StockItemID = ol.StockItemID
WHERE 
si.StockItemName = 'Chocolate frogs 250g'
ORDER BY o.CustomerID
