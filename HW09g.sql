--1. Требуется написать запрос, который в результате своего выполнения формирует таблицу следующего вида:
--Название клиента
--МесяцГод Количество покупок

--Клиентов взять с ID 2-6, это все подразделение Tailspin Toys
--имя клиента нужно поменять так чтобы осталось только уточнение
--например исходное Tailspin Toys (Gasport, NY) - вы выводите в имени только Gasport,NY
--дата должна иметь формат dd.mm.yyyy например 25.12.2019

--Например, как должны выглядеть результаты:
--InvoiceMonth Peeples Valley, AZ Medicine Lodge, KS Gasport, NY Sylvanite, MT Jessie, ND
--01.01.2013 3 1 4 2 2
--01.02.2013 7 3 4 2 1
SELECT 
	OrderDateFORMAT
	,[Gasport, NY]
	,[Jessie, ND]
	,[Medicine Lodge, KS]
	,[Peeples Valley, AZ]
	,[Sylvanite, MT]
FROM 
		(SELECT 
		OrderId
		,FORMAT( o.OrderDate, '01.MM.yyyy') as OrderDateFORMAT
		--,o.OrderDate
		,SUBSTRING(CustomerName,CHARINDEX('(', CustomerName) +1, CHARINDEX(')', CustomerName) - (CHARINDEX('(', CustomerName) +1)) as CName
		FROM   Sales.Orders o
		--JOIN Sales.OrderLines ol ON o.OrderId = ol.OrderId
		JOIN Sales.Customers c ON c.CustomerID = o.CustomerID
		WHERE o.CustomerID IN (2,3,4,5,6)) as Tab
PIVOT (COUNT(OrderId) 
FOR CName  IN ([Gasport, NY]
				,[Jessie, ND]
				,[Medicine Lodge, KS]
				,[Peeples Valley, AZ]
				,[Sylvanite, MT]))
		as PVT
--ORDER BY OrderDate

--2. Для всех клиентов с именем, в котором есть Tailspin Toys
--вывести все адреса, которые есть в таблице, в одной колонке

--Пример результатов
--CustomerName AddressLine
--Tailspin Toys (Head Office) Shop 38
--Tailspin Toys (Head Office) 1877 Mittal Road
--Tailspin Toys (Head Office) PO Box 8975
--Tailspin Toys (Head Office) Ribeiroville
;WITH CTE as (
	SELECT
		c.CustomerID
		,c.CustomerName
		,c.PostalAddressLine1
		,c.PostalAddressLine2
		,c.DeliveryAddressLine1
		,c.DeliveryAddressLine2
	FROM Sales.Customers c
	WHERE CustomerName LIKE 'Tailspin Toys%')
SELECT * FROM CTE
UNPIVOT(AddressLine FOR AddressLineType IN ([PostalAddressLine1]
											,[PostalAddressLine2]
											,[DeliveryAddressLine1]
											,[DeliveryAddressLine2])) as upvt


--3. В таблице стран есть поля с кодом страны цифровым и буквенным
--сделайте выборку ИД страны, название, код - чтобы в поле был либо цифровой либо буквенный код
--Пример выдачи

--CountryId CountryName Code
--1 Afghanistan AFG
--1 Afghanistan 4
--3 Albania ALB
--3 Albania 8

with CTE as (
Select c.CountryID								as 'CountryID'
      ,c.CountryName							as 'CountryName'
	  ,Convert(varchar(3), c.IsoAlpha3Code)		as 'IsoAlpha3Code'
	  ,Convert(varchar(3), c.IsoNumericCode)	as 'IsoNumericCode'
  from Application.Countries c
)
Select * from CTE
Unpivot(Code for CodeType in ([IsoAlpha3Code],[IsoNumericCode])) as unpvt;


--4. Перепишите ДЗ из оконных функций через CROSS APPLY
--Выберите по каждому клиенту 2 самых дорогих товара, которые он покупал
--В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки

SELECT
	Tab.CustomerID
	,c.CustomerName
	,Tab.StockItemID
	,Tab.UnitPrice
	,Tab.OrderDate
FROM Sales.Customers c
	CROSS APPLY (SELECT TOP 2 WITH TIES
		o.CustomerID
		,ol.StockItemID
		,ol.UnitPrice
		,MAX(o.OrderDate) as OrderDate
	FROM Sales.Orders o
	INNER JOIN Sales.OrderLines ol ON ol.OrderID = o.OrderID
	WHERE o.CustomerID = c.CustomerID
	GROUP BY 
		o.CustomerID
		,ol.StockItemID
		,ol.UnitPrice
	ORDER BY o.CustomerID, ol.UnitPrice DESC) as Tab
ORDER BY c.CustomerName
 
