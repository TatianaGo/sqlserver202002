--1) Написать функцию возвращающую Клиента с наибольшей суммой покупки.
--USE [WideWorldImporters]
--GO


--SET ANSI_NULLS ON
--GO

--SET QUOTED_IDENTIFIER ON
--GO


--CREATE FUNCTION [dbo].[fGetCustomerMaxPurchase] ()
--RETURNS int
--WITH EXECUTE AS CALLER
--AS

--BEGIN
--DECLARE @CustomerID int
--SELECT @CustomerID = CustomerID
--FROM
--	(SELECT TOP 1
--	i.InvoiceID
--	,i.CustomerID
--	,SUM(il.UnitPrice * il.Quantity) as PurchaseAmount
--FROM Sales.Invoices i
--INNER JOIN Sales.InvoiceLines il ON il.InvoiceID = i.InvoiceID
--GROUP BY i.CustomerID,i.InvoiceID
--ORDER BY PurchaseAmount desc) as tab

--     RETURN @CustomerID
--END
--GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

alter FUNCTION fSelectCastomerMaxPurchase 
(	

)
RETURNS TABLE 
AS
RETURN 
(
WITH tab (InvoiceID,CustomerID,PurchaseAmount) as 
(SELECT 
	i.InvoiceID
	,i.CustomerID
	,sum(il.UnitPrice * il.Quantity) as PurchaseAmount
FROM Sales.Invoices i
INNER JOIN Sales.InvoiceLines il ON il.InvoiceID = i.InvoiceID
GROUP BY i.CustomerID,i.InvoiceID)
SELECT
	tab.CustomerID
	,c.CustomerName
FROM tab
INNER JOIN Sales.Customers c on c.CustomerID = tab.CustomerID
where PurchaseAmount = 
	(SELECT 
	max(PurchaseAmount)
	FROM tab)
)
GO

select * from fSelectCastomerMaxPurchase()


--2) Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.
--Использовать таблицы :
--Sales.Customers
--Sales.Invoices
--Sales.InvoiceLines


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[pCustomerPurchase] 
	@inCustomerID int = null
AS
BEGIN
	SET NOCOUNT ON;
	SELECT 
        c.CustomerName
		,SUM(il.UnitPrice * il.Quantity) as PurchaseAmount
	FROM Sales.Invoices i
	INNER JOIN Sales.InvoiceLines il ON il.InvoiceID = i.InvoiceID
	INNER JOIN Sales.Customers c ON c.CustomerID = i.CustomerID
	WHERE (i.CustomerID = @inCustomerID or @inCustomerID IS NULL)
	GROUP BY
		 i.CustomerID
		,c.CustomerName
END

----


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[pCustomerPurchaseO] 
	@inCustomerID int = NULL
	,@outPurchaseAmount float OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @PurchaseAmount123 float

	SELECT @PurchaseAmount123 = 
		SUM(il.UnitPrice * il.Quantity) 
	FROM Sales.Invoices i
	INNER JOIN Sales.InvoiceLines il ON il.InvoiceID = i.InvoiceID
	WHERE CustomerID = @inCustomerID

	SET @outPurchaseAmount = @PurchaseAmount123 
SELECT @PurchaseAmount123;
END

--3) Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER  FUNCTION fTestTable 
(
	@inCustomerID int = null
)
RETURNS 
@Table_Var TABLE 
(
	CustomerID INT
	,CustomerName NVARCHAR (200)
	,PurchaseAmount FLOAT
)
AS
BEGIN
INSERT INTO @Table_Var
(	CustomerID 
	,CustomerName 
	,PurchaseAmount 
)
	SELECT 
		 i.CustomerID
		,c.CustomerName
		,SUM(il.UnitPrice * il.Quantity) as PurchaseAmount
	FROM Sales.Invoices i
	INNER JOIN Sales.InvoiceLines il ON il.InvoiceID = i.InvoiceID
	INNER JOIN Sales.Customers c ON c.CustomerID = i.CustomerID
	WHERE (i.CustomerID = @inCustomerID or @inCustomerID IS NULL)
	GROUP BY
		 i.CustomerID
		,c.CustomerName
	
	RETURN 
END
GO
set statistics time on;
SELECT * FROM  fTestTable (null)
 --SQL Server Execution Times:
 --     CPU time = 47 ms,  elapsed time = 94 ms.
------

EXEC [dbo].[pCustomerPurchase] 
	@inCustomerID  = null --WITH RECOMPILE; 
GO

--SQL Server parse and compile time: 
--   CPU time = 15 ms, elapsed time = 15 ms.

-- SQL Server Execution Times:
--   CPU time = 0 ms,  elapsed time = 0 ms.

-- SQL Server Execution Times:
--   CPU time = 31 ms,  elapsed time = 109 ms.

-- SQL Server Execution Times:
--   CPU time = 47 ms,  elapsed time = 125 ms.

--4) Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла.
SELECT
*
FROM Sales.Customers c
INNER JOIN dbo.fTestTable (null) f  ON  f.CustomerID = c.CustomerID

SELECT
*
FROM Sales.Customers c
CROSS APPLY (SELECT PurchaseAmount FROM dbo.fTestTable(c.CustomerID) )f 

--Во всех процедурах, в описании укажите для преподавателям
--5) какой уровень изоляции нужен и почему.
-- если нет проблем, то оставить режим по умолчанию READ COMMITTED
-- если точность данных не нужна, и много вставок/изменениий то READ UNCOMMITTED
-- если банковские проводки или что-то важное  REPEATABLE READ/SERIALIZABLE
--Опционально
--6) Переписываем одну и ту же процедуру kitchen sink с множеством входных параметров по поиску в заказах на 
--динамический SQL.
CREATE OR ALTER PROCEDURE dbo.CustomerSearch_KitchenSinkOtus
  @CustomerID            int            = NULL,
  @CustomerName          nvarchar(100)  = NULL,
  @BillToCustomerID      int            = NULL,
  @CustomerCategoryID    int            = NULL,
  @BuyingGroupID         int            = NULL,
  @MinAccountOpenedDate  date           = NULL,
  @MaxAccountOpenedDate  date           = NULL,
  @DeliveryCityID        int            = NULL,
  @IsOnCreditHold        bit            = NULL,
  @OrdersCount			 INT			= NULL, 
  @PersonID				 INT			= NULL, 
  @DeliveryStateProvince INT			= NULL,
  @PrimaryContactPersonIDIsEmployee BIT = NULL

AS
BEGIN
  SET NOCOUNT ON;
   DECLARE @sql nvarchar(max),
		  @params nvarchar(max);


  SET @params = N'
  @CustomerID            int            ,
  @CustomerName          nvarchar(100)  ,
  @BillToCustomerID      int            ,
  @CustomerCategoryID    int            ,
  @BuyingGroupID         int            ,
  @MinAccountOpenedDate  date           ,
  @MaxAccountOpenedDate  date           ,
  @DeliveryCityID        int            ,
  @IsOnCreditHold        bit            ,
  @OrdersCount			 INT			, 
  @PersonID				 INT			, 
  @DeliveryStateProvince INT			,
  @PrimaryContactPersonIDIsEmployee BIT'; 

  SET @sql =  'SELECT CustomerID, CustomerName, IsOnCreditHold
    FROM Sales.Customers AS Client
		JOIN Application.People AS Person ON 
			Person.PersonID = Client.PrimaryContactPersonID
		JOIN Application.Cities AS City ON
			City.CityID = Client.DeliveryCityID
	WHERE 1=1';


  IF @CustomerID IS NOT NULL
	SET @sql = @sql + ' AND CustomerID = @CustomerID'

  IF   @CustomerName IS NOT NULL 
  	SET @sql = @sql + ' AND CustomerName = @CustomerName'

  IF   @BillToCustomerID IS NOT NULL 
  	SET @sql = @sql + ' AND BillToCustomerID = @BillToCustomerID' 

  IF   @CustomerCategoryID IS NOT NULL
  	SET @sql = @sql + ' AND CustomerCategoryID = @CustomerCategoryID' 

  IF   @BuyingGroupID IS NOT NULL
  	SET @sql = @sql + ' AND BuyingGroupID = @BuyingGroupID'
  IF   @MinAccountOpenedDate IS NOT NULL 
  	SET @sql = @sql + ' AND MinAccountOpenedDate = @MinAccountOpenedDate'

  IF   @MaxAccountOpenedDate IS NOT NULL
  	SET @sql = @sql + ' AND @MaxAccountOpenedDate = @MaxAccountOpenedDate'

  IF   @DeliveryCityID IS NOT NULL 
  	SET @sql = @sql + ' AND DeliveryCityID = @DeliveryCityID'

   IF  @IsOnCreditHold IS NOT NULL
  	SET @sql = @sql + ' AND IsOnCreditHold = @IsOnCreditHold'

   IF  @OrdersCount IS NOT NULL	
  	SET @sql = @sql + ' AND @OrdersCount = @OrdersCount'

  IF   @PersonID IS NOT NULL	
  	SET @sql = @sql + ' AND PersonID = @PersonID'

  IF   @DeliveryStateProvince IS NOT NULL
  	SET @sql = @sql + ' AND DeliveryStateProvince = @DeliveryStateProvince'

  IF   @PrimaryContactPersonIDIsEmployee IS NOT NULL	
  	SET @sql = @sql + ' AND PrimaryContactPersonIDIsEmployee = @PrimaryContactPersonIDIsEmployee'

 PRINT @sql;
 
    EXEC sys.sp_executesql @sql, @params, 
  @CustomerID           
  ,@CustomerName         
  ,@BillToCustomerID     
  ,@CustomerCategoryID   
  ,@BuyingGroupID        
  ,@MinAccountOpenedDate 
  ,@MaxAccountOpenedDate 
  ,@DeliveryCityID       
  ,@IsOnCreditHold       
  ,@OrdersCount			
  ,@PersonID				
  ,@DeliveryStateProvince
  ,@PrimaryContactPersonIDIsEmployee
  
  END

  go
  exec CustomerSearch_KitchenSinkOtus 