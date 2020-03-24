--1. Довставлять в базу 5 записей используя insert в таблицу Customers или Suppliers

INSERT INTO [Purchasing].[Suppliers] 
	(SupplierName                
	,SupplierCategoryID           
	,PrimaryContactPersonID       
	,AlternateContactPersonID     
	,DeliveryMethodID             
	,DeliveryCityID               
	,PostalCityID                 
	,SupplierReference            
	,BankAccountName              
	,BankAccountBranch            
	,BankAccountCode              
	,BankAccountNumber            
	,BankInternationalCode        
	,PaymentDays                  
	,InternalComments             
	,PhoneNumber                  
	,FaxNumber                    
	,WebsiteURL                   
	,DeliveryAddressLine1         
	,DeliveryAddressLine2         
	,DeliveryPostalCode           
	,DeliveryLocation             
	,PostalAddressLine1           
	,PostalAddressLine2           
	,PostalPostalCode 
	,LastEditedBy
	)

SELECT top 5
	SupplierName + '___NEW'                
	,SupplierCategoryID           
	,PrimaryContactPersonID       
	,AlternateContactPersonID     
	,DeliveryMethodID             
	,DeliveryCityID               
	,PostalCityID                 
	,SupplierReference            
	,BankAccountName              
	,BankAccountBranch            
	,BankAccountCode              
	,BankAccountNumber            
	,BankInternationalCode        
	,PaymentDays                  
	,InternalComments             
	,PhoneNumber                  
	,FaxNumber                    
	,WebsiteURL                   
	,DeliveryAddressLine1         
	,DeliveryAddressLine2         
	,DeliveryPostalCode           
	,DeliveryLocation             
	,PostalAddressLine1           
	,PostalAddressLine2           
	,PostalPostalCode
	,LastEditedBy
FROM [Purchasing].[Suppliers]
--2. удалите 1 запись из Customers, которая была вами добавлена
DELETE 
FROM [Purchasing].[Suppliers]
WHERE SupplierID = (
				SELECT top 1
				SupplierID
				FROM [Purchasing].[Suppliers]
				WHERE SupplierName like '%___NEW')


--3. изменить одну запись, из добавленных через UPDATE
UPDATE f
SET SupplierName = SupplierName + '___NEW2'
FROM [Purchasing].[Suppliers] f
WHERE SupplierID = (
				SELECT top 1
				SupplierID
				FROM [Purchasing].[Suppliers]
				WHERE SupplierName like '%___NEW')

--4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть

-- SELECT  top 1
--	SupplierID
--	,SupplierName    as   SupplierName          
--	,SupplierCategoryID           
--	,PrimaryContactPersonID       
--	,AlternateContactPersonID     
--	,DeliveryMethodID             
--	,DeliveryCityID               
--	,PostalCityID                 
--	,SupplierReference            
--	,BankAccountName              
--	,BankAccountBranch            
--	,BankAccountCode              
--	,BankAccountNumber            
--	,BankInternationalCode        
--	,PaymentDays                  
--	,InternalComments             
--	,PhoneNumber                  
--	,FaxNumber                    
--	,WebsiteURL                   
--	,DeliveryAddressLine1         
--	,DeliveryAddressLine2         
--	,DeliveryPostalCode           
--	,DeliveryLocation             
--	,PostalAddressLine1           
--	,PostalAddressLine2           
--	,PostalPostalCode
--	,LastEditedBy
--INTO TestMerge
--FROM [Purchasing].[Suppliers]
--UPDATE  TestMerge
--SET SupplierName = SupplierName + '_M'
--WHERE SupplierID = (SELECT TOP 1 SupplierID FROM TestMerge)


--INSERT INTO TestMerge
-- SELECT  top 1
--	12336
--	,SupplierName + SupplierName + '_M'         
--	,SupplierCategoryID           
--	,PrimaryContactPersonID       
--	,AlternateContactPersonID     
--	,DeliveryMethodID             
--	,DeliveryCityID               
--	,PostalCityID                 
--	,SupplierReference            
--	,BankAccountName              
--	,BankAccountBranch            
--	,BankAccountCode              
--	,BankAccountNumber            
--	,BankInternationalCode        
--	,PaymentDays                  
--	,InternalComments             
--	,PhoneNumber                  
--	,FaxNumber                    
--	,WebsiteURL                   
--	,DeliveryAddressLine1         
--	,DeliveryAddressLine2         
--	,DeliveryPostalCode           
--	,DeliveryLocation             
--	,PostalAddressLine1           
--	,PostalAddressLine2           
--	,PostalPostalCode
--	,LastEditedBy

--FROM [Purchasing].[Suppliers]

--SELECT * FROM TestMerge



MERGE  [Purchasing].[Suppliers]  AS Target
USING TestMerge AS Source
    ON (Target.SupplierID = Source.SupplierID)
WHEN MATCHED 
    THEN UPDATE 
        SET SupplierName = Source.SupplierName
WHEN NOT MATCHED 
    THEN INSERT 
	(SupplierID
	,SupplierName        
	,SupplierCategoryID           
	,PrimaryContactPersonID       
	,AlternateContactPersonID     
	,DeliveryMethodID             
	,DeliveryCityID               
	,PostalCityID                 
	,SupplierReference            
	,BankAccountName              
	,BankAccountBranch            
	,BankAccountCode              
	,BankAccountNumber            
	,BankInternationalCode        
	,PaymentDays                  
	,InternalComments             
	,PhoneNumber                  
	,FaxNumber                    
	,WebsiteURL                   
	,DeliveryAddressLine1         
	,DeliveryAddressLine2         
	,DeliveryPostalCode           
	,DeliveryLocation             
	,PostalAddressLine1           
	,PostalAddressLine2           
	,PostalPostalCode
	,LastEditedBy)
        VALUES (
	 source.SupplierID
	,source.SupplierName        
	,source.SupplierCategoryID           
	,source.PrimaryContactPersonID       
	,source.AlternateContactPersonID     
	,source.DeliveryMethodID             
	,source.DeliveryCityID               
	,source.PostalCityID                 
	,source.SupplierReference            
	,source.BankAccountName              
	,source.BankAccountBranch            
	,source.BankAccountCode              
	,source.BankAccountNumber            
	,source.BankInternationalCode        
	,source.PaymentDays                  
	,source.InternalComments             
	,source.PhoneNumber                  
	,source.FaxNumber                    
	,source.WebsiteURL                   
	,source.DeliveryAddressLine1         
	,source.DeliveryAddressLine2         
	,source.DeliveryPostalCode           
	,source.DeliveryLocation             
	,source.PostalAddressLine1           
	,source.PostalAddressLine2           
	,source.PostalPostalCode
	,source.LastEditedBy
	)
OUTPUT deleted.*, $action, inserted.*;
--5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert 

exec master..xp_cmdshell 'bcp "WideWorldImporters.Sales.InvoiceLines" out "G:\temp11\InvoiceLines01.txt" -T -w -t"@eu&$1&" -S DESKTOP-O6B5NP0\SQL2017'


BULK INSERT [WideWorldImporters].[Sales].[InvoiceLines_TestBulk]
				   FROM 'G:\temp11\InvoiceLines01.txt'
				   WITH 
					 (
						BATCHSIZE = 100000, 
						DATAFILETYPE = 'widechar',
						FIELDTERMINATOR = '@eu&$1&',
						ROWTERMINATOR ='\n',
						KEEPNULLS,
						TABLOCK        
					  );