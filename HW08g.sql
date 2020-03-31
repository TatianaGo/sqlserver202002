--1. Напишите запрос с временной таблицей и перепишите его с табличной переменной. Сравните планы.
--В качестве запроса с временной таблицей и табличной переменной можно взять свой запрос или следующий запрос:
--Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года (в рамках одного месяца он будет одинаковый, 
--нарастать будет в течение времени выборки)
--Выведите id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом
--Пример
--Дата продажи Нарастающий итог по месяцу
--2015-01-29 4801725.31
--2015-01-30 4801725.31
--2015-01-31 4801725.31
--2015-02-01 9626342.98
--2015-02-02 9626342.98
--2015-02-03 9626342.98
--Продажи можно взять из таблицы Invoices.
--Нарастающий итог должен быть без оконной функции.

--2. Если вы брали предложенный выше запрос, то сделайте расчет суммы нарастающим итогом с помощью оконной функции.
--Сравните 2 варианта запроса - через windows function и без них. Написать какой быстрее выполняется, сравнить по set statistics time on;


DECLARE @Inv as TABLE
	(
	InvoiceDate date
	,AmountMonth decimal(18,2)
	)
INSERT INTO @Inv
	(InvoiceDate 
	,AmountMonth
	)
SELECT
	EOMONTH(i.InvoiceDate)
	,SUM(il.UnitPrice * il.Quantity)
FROM Sales.Invoices i
INNER JOIN Sales.InvoiceLines il ON il.InvoiceID = i.InvoiceID
WHERE i.InvoiceDate >='2015-01-01'
GROUP BY EOMONTH(i.InvoiceDate)

DECLARE @InvT as TABLE
	(
	InvoiceDate date
	,AmountMonth decimal(18,2)
	,AmountN decimal(18,2)
	,YMDate varchar (50)
	)
INSERT INTO @InvT
	(InvoiceDate 
	,AmountMonth
	,AmountN
	,YMDate
	)

SELECT 
	InvoiceDate 
	,AmountMonth
	,(SELECT SUM(AmountMonth) FROM @Inv WHERE InvoiceDate <= i.InvoiceDate ) 
	,FORMAT(InvoiceDate,'yyyyMM') as YMDate
FROM @Inv i

--Выведите id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом
SELECT
	i.InvoiceID
	,c.CustomerName
	,i.InvoiceDate
	,il.UnitPrice * il.Quantity as Amount
	,AmountMonth
	,AmountN
FROM Sales.Invoices i
	INNER JOIN  @InvT t ON t.YMDate =  FORMAT(i.InvoiceDate,'yyyyMM') 
	INNER JOIN Sales.Customers c on c.CustomerID = i.CustomerID
	INNER JOIN Sales.InvoiceLines il ON il.InvoiceID = i.InvoiceID 
WHERE i.InvoiceDate >='2015-01-01'
ORDER BY i.InvoiceDate


SELECT
	i.InvoiceID
	,c.CustomerName
	,i.InvoiceDate
	,il.UnitPrice * il.Quantity as Amount
	,SUM(il.UnitPrice * il.Quantity) OVER (  ORDER BY FORMAT(i.InvoiceDate,'yyyyMM')) as Amount
FROM Sales.Invoices i
	INNER JOIN Sales.Customers c on c.CustomerID = i.CustomerID
	INNER JOIN Sales.InvoiceLines il ON il.InvoiceID = i.InvoiceID 
WHERE i.InvoiceDate >='2015-01-01'
ORDER BY i.InvoiceDate

--set statistics time on;
--Первый вариант
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
SQL Server parse and compile time: 
   CPU time = 65 ms, elapsed time = 65 ms.

(17 rows affected)

(1 row affected)

 SQL Server Execution Times:
   CPU time = 78 ms,  elapsed time = 76 ms.

(17 rows affected)

(1 row affected)

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 63 ms.

(101356 rows affected)

(1 row affected)

 SQL Server Execution Times:
   CPU time = 1078 ms,  elapsed time = 2008 ms.
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.

--Второй вариант

SQL Server parse and compile time:
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
SQL Server parse and compile time: 
   CPU time = 31 ms, elapsed time = 31 ms.

(101356 rows affected)

(1 row affected)

 SQL Server Execution Times:
   CPU time = 1235 ms,  elapsed time = 2097 ms.
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
-- не знаю как тут правильно как смотреть, но цифры похожи

--2. Вывести список 2х самых популярных продуктов (по кол-ву проданных) в каждом месяце за 2016й год (по 2 самых популярных продукта в каждом месяце)

;WITH  Tab AS
	(SELECT
		FORMAT(i.InvoiceDate,'yyyyMM') as mm
		,StockItemID
		,SUM(Quantity) as Quantity
	FROM Sales.Invoices i
	INNER JOIN Sales.InvoiceLines il ON il.InvoiceID = i.InvoiceID 
	WHERE i.InvoiceDate >='2016-01-01' AND i.InvoiceDate <'2017-01-01'
	GROUP BY 
		FORMAT(i.InvoiceDate,'yyyyMM')
		,StockItemID) , 
Tab2 AS(SELECT
			mm
			,StockItemID
			,Quantity
			,RANK() OVER (PARTITION BY mm ORDER BY Quantity DESC) AS RankNum
		FROM Tab
) 
SELECT
	mm
	,t.StockItemID
	,si.StockItemName
	,Quantity
FROM Tab2 t
INNER JOIN Warehouse.StockItems si ON si.StockItemID = t.StockItemID
WHERE RankNum <3
ORDER BY mm,Quantity, StockItemID

--3. Функции одним запросом
--Посчитайте по таблице товаров, в вывод также должен попасть ид товара, название, брэнд и цена
--пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
--посчитайте общее количество товаров и выведете полем в этом же запросе
--посчитайте общее количество товаров в зависимости от первой буквы названия товара
--отобразите следующий id товара исходя из того, что порядок отображения товаров по имени
--предыдущий ид товара с тем же порядком отображения (по имени)
--названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
--сформируйте 30 групп товаров по полю вес товара на 1 шт
--Для этой задачи НЕ нужно писать аналог без аналитических функций
;WITH Tab as
	(SELECT
		StockItemID
		,StockItemName
		,Brand
		,UnitPrice
		,TypicalWeightPerUnit
		,SUBSTRING ( StockItemName ,PATINDEX('%[A-Z]%',StockItemName) , 1 ) as Letter
	FROM Warehouse.StockItems
	)
SELECT
	StockItemID
	,StockItemName
	,Brand
	,UnitPrice
	,ROW_NUMBER() OVER (PARTITION BY Letter  ORDER BY  Letter)
	,COUNT(*) OVER()
	,COUNT(*) OVER(PARTITION BY Letter )
	,LEAD(StockItemID) OVER(ORDER BY StockItemName)
	,LAG(StockItemID) OVER(ORDER BY StockItemName)
	,LAG (StockItemName ,2  ,'No items')  OVER(ORDER BY StockItemName)--названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
	,NTILE(30) OVER ( ORDER BY TypicalWeightPerUnit)
FROM Tab

--4. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал
--В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки
;WITH Tab as
	(SELECT
		ROW_NUMBER() OVER (PARTITION BY SalespersonPersonID ORDER BY  OrderDate DESC) as Num
		,OrderID
		,SalespersonPersonID
		,CustomerID
		,OrderDate
	FROM Sales.Orders o) 

SELECT 
	t.SalespersonPersonID
	,p.FullName
	,t.CustomerID
	,c.CustomerName
	,t.OrderDate
	,(SELECT SUM(UnitPrice * Quantity) FROM Sales.OrderLines WHERE OrderID = t.OrderID) as Amount
FROM Application.People p
LEFT JOIN Tab t ON t.SalespersonPersonID  = p.PersonID AND Num = 1
LEFT JOIN Sales.Customers c on c.CustomerID = t.CustomerID
WHERE p.IsSalesperson = 1

--5. Выберите по каждому клиенту 2 самых дорогих товара, которые он покупал
--В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки

;WITH Tab as(
		SELECT
		o.OrderID
		,o.OrderDate
		,o.CustomerID
		,StockItemID
		,UnitPrice
		,DENSE_RANK() OVER (PARTITION BY CustomerID ORDER BY UnitPrice DESC) as Drank
	FROM Sales.Orders o
	INNER JOIN Sales.OrderLines ol ON ol.OrderID = o.OrderID
	) 
SELECT 
	t.CustomerID
	,c.CustomerName
	,t.StockItemID
	,t.UnitPrice
	,MAX(OrderDate) as OrderDate

FROM Tab t
INNER JOIN Sales.Customers c on c.CustomerID = t.CustomerID
WHERE Drank < 3
GROUP BY
	t.CustomerID
	,c.CustomerName
	,t.StockItemID
	,t.UnitPrice
ORDER BY c.CustomerName