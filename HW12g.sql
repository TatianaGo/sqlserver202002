--1. Загрузить данные из файла StockItems.xml в таблицу Warehouse.StockItems.
--Существующие записи в таблице обновить, отсутствующие добавить сопоставлять записи по полю StockItemName).
--Файл StockItems.xml в личном кабинете.
DECLARE @x XML
DECLARE @docHandle int
SET @x = ( 
 SELECT * FROM OPENROWSET
  (BULK 'G:\temp11\StockItems-188-f89807.xml',
   SINGLE_BLOB)
   as d)

EXEC sp_xml_preparedocument @docHandle OUTPUT, @x

MERGE Warehouse.StockItems as Target
USING  
(SELECT
StockItemName as StockItemName
,SupplierID as SupplierID
,UnitPackageID as UnitPackageID
,OuterPackageID as OuterPackageID
,QuantityPerOuter as QuantityPerOuter
,TypicalWeightPerUnit as TypicalWeightPerUnit
,LeadTimeDays as LeadTimeDays
,IsChillerStock as IsChillerStock
,TaxRate as TaxRate
,UnitPrice as UnitPrice
FROM OPENXML(@docHandle, N'/StockItems/Item', 3)
WITH ( 
	[StockItemName] nvarchar(200) '@Name',
	[SupplierID] int 'SupplierID',
	[UnitPackageID] int 'Package/UnitPackageID',
	[OuterPackageID] int 'Package/OuterPackageID',
	[QuantityPerOuter] int 'Package/QuantityPerOuter',
	[TypicalWeightPerUnit] decimal(18,3) 'Package/TypicalWeightPerUnit',
	[LeadTimeDays] int 'LeadTimeDays',
	[IsChillerStock] bit 'IsChillerStock',
	[TaxRate] decimal(18,3)'TaxRate',
	[UnitPrice] decimal(18,3) 'UnitPrice'
	)
)  AS Source

    ON (Target.StockItemName = Source.StockItemName)
WHEN MATCHED 
    THEN UPDATE 
SET StockItemName = Source.StockItemName
,SupplierID			= Source.SupplierID 
,UnitPackageID		= Source.UnitPackageID 
,OuterPackageID		= Source.OuterPackageID 
,QuantityPerOuter	= Source.QuantityPerOuter 
,TypicalWeightPerUnit =Source.TypicalWeightPerUnit 
,LeadTimeDays		= Source.LeadTimeDays 
,IsChillerStock		= Source.IsChillerStock 
,TaxRate			= Source.TaxRate 
,UnitPrice			= Source.UnitPrice                 
WHEN NOT MATCHED 
    THEN INSERT
	( StockItemName
	,SupplierID			
	,UnitPackageID		
	,OuterPackageID		
	,QuantityPerOuter	
	,TypicalWeightPerUnit
	,LeadTimeDays		
	,IsChillerStock		
	,TaxRate			
	,UnitPrice
	,LastEditedBy)
	VALUES
	(Source.StockItemName
	,Source.SupplierID 
	,Source.UnitPackageID 
	,Source.OuterPackageID 
	,Source.QuantityPerOuter 
	,Source.TypicalWeightPerUnit 
	,Source.LeadTimeDays 
	,Source.IsChillerStock 
	,Source.TaxRate 
	,Source.UnitPrice
	,1)                
OUTPUT deleted.*, $action, inserted.*;

EXEC sp_xml_removedocument @docHandle
go

--2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
CREATE TABLE ##StockItemsXMLOut  
	(StockItemsXMLOut xml) --NVARCHAR(MAX))
INSERT INTO ##StockItemsXMLOut
	(StockItemsXMLOut)

SELECT(SELECT  
	StockItemName AS [@Name]
	,SupplierID			
	,UnitPackageID	AS [Package/UnitPackageID]	
	,OuterPackageID	AS [Package/OuterPackageID]			
	,QuantityPerOuter	AS [Package/QuantityPerOuter]		
	,TypicalWeightPerUnit	AS [Package/TypicalWeightPerUnit]	
	,LeadTimeDays		
	,IsChillerStock		
	,TaxRate			
	,UnitPrice

FROM Warehouse.StockItems
FOR XML PATH('Item'), ROOT('StockItems'))

exec xp_cmdshell 'bcp "select StockItemsXMLOut FROM ##StockItemsXMLOut" queryout "G:\temp11\StockItemsx.xml" -S DESKTOP-O6B5NP0\SQL2017 -T -c'
 
DROP TABLE ##StockItemsXMLOut

--3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
--Написать SELECT для вывода:
--- StockItemID
--- StockItemName
--- CountryOfManufacture (из CustomFields)
--- FirstTag (из поля CustomFields, первое значение из массива Tags)
SELECT
	 StockItemID
	,CustomFields
	,StockItemName
	,JSON_VALUE(CustomFields, '$.CountryOfManufacture')
	,JSON_VALUE(CustomFields,'$.Tags[0]')
FROM
	Warehouse.StockItems

--4. Найти в StockItems строки, где есть тэг "Vintage".
--Вывести:
--- StockItemID
--- StockItemName
--- (опционально) все теги (из CustomFields) через запятую в одном поле

--Тэги искать в поле CustomFields, а не в Tags.
--Запрос написать через функции работы с JSON.
--Для поиска использовать равенство, использовать LIKE запрещено.

--Должно быть в таком виде:
--... where ... = 'Vintage'

SELECT
	 StockItemID
	,CustomFields
	,StockItemName
	,Tag
	,TagsText
FROM
	Warehouse.StockItems
OUTER APPLY (
		SELECT value as Tag
		FROM OPENJSON (CustomFields, '$.Tags')
			) as t

OUTER APPLY (
		SELECT 
		STRING_AGG(value, ', ') as TagsText
		FROM OPENJSON (CustomFields, '$.Tags')
			) as t2
WHERE Tag = 'Vintage'

--5. Пишем динамический PIVOT.
--По заданию из занятия “Операторы CROSS APPLY, PIVOT, CUBE”.
--Требуется написать запрос, который в результате своего выполнения формирует таблицу следующего вида:
--Название клиента
--МесяцГод Количество покупок

--Нужно написать запрос, который будет генерировать результаты для всех клиентов.
--Имя клиента указывать полностью из CustomerName.
--Дата должна иметь формат dd.mm.yyyy например 25.12.2019 

DECLARE @columns NVARCHAR(max)
DECLARE @query NVARCHAR(4000)
--SELECT @columns =
--	STRING_AGG('[' +CustomerName + ']', ', ') 
--	FROM 
--	(SELECT top 100
--	CustomerName
--	FROM
--	Sales.Orders o
--	JOIN Sales.Customers c ON c.CustomerID = o.CustomerID
--	GROUP BY CustomerName
--	) tab

SELECT @columns =
(select ', '+  '[' + CustomerName + ']' 
	FROM 
		(SELECT 
			CustomerName
		FROM
			Sales.Orders o
			JOIN Sales.Customers c ON c.CustomerID = o.CustomerID
			WHERE o.CustomerID IN (2,3,4,5,6) --Для всех не получается похоже там ограничение по размеру(в PIVOT и STRING_AGG)
		GROUP BY CustomerName) as CustomerNames for xml path(''))

SELECT @columns	= STUFF(@columns, 1,1,'')	
--SELECT @columns
SET @query =
'SELECT
*
FROM 
		(SELECT 
			OrderId
			,CustomerName
			,FORMAT( o.OrderDate, ''01.MM.yyyy'') as OrderDateFORMAT
		FROM   Sales.Orders o
			JOIN Sales.Customers c ON c.CustomerID = o.CustomerID
		WHERE o.CustomerID IN (2,3,4,5,6)) as Tab
PIVOT (
	COUNT(OrderId) 
	FOR CustomerName  IN  (' + @columns + ')
	   )as PVT'
EXECUTE SP_EXECUTESQL @query

