/****************************************************************************************
*****************************************************************************************
			
		***		Treinamento: SQL23 - SQL Server 2012: Mastering the Database Engine		***

	Autor: Luciano Caixeta Moreira
	E-mail: luciano.moreira@srnimbus.com.br
	Blog: http://luticm.blogspot.com
	Twitter: @luticm
	
	Título: Modulo 07 Demo 05 - Novo Cardinality Estimator
	Descrição: 
		
	* Copyright (C) 2013 Sr. Nimbus Prestação de Serviços em Tecnologia LTDA 
	* http://www.srnimbus.com.br

*****************************************************************************************	
****************************************************************************************/

USE AdventureWorks2012
GO

/*
	Agradecimento a Kendra Little que escreveu o post com o conteúdo dessa demonstração
	http://www.brentozar.com/archive/2014/04/sql-2014-cardinality-estimator-eats-bad-tsql-breakfast/
*/

-- Garante uso do novo cardinality estimator
ALTER DATABASE AdventureWorks2012 SET COMPATIBILITY_LEVEL=120;
GO

CHECKPOINT
DBCC FREEPROCCACHE
DBCC DROPCLEANBUFFERS

SET STATISTICS TIME ON	
SET STATISTICS IO ON		

-- Plano antigo, trace flag 9481
-- Mostar plano de execução e STATISTICS
SELECT e.[BusinessEntityID],
       p.[Title],
       p.[FirstName],
       p.[MiddleName],
       p.[LastName],
       p.[Suffix],
       e.[JobTitle],
       pp.[PhoneNumber],
       pnt.[Name] AS [PhoneNumberType],
       ea.[EmailAddress],
       p.[EmailPromotion],
       a.[AddressLine1],
       a.[AddressLine2],
       a.[City],
       sp.[Name] AS [StateProvinceName],
       a.[PostalCode],
       cr.[Name] AS [CountryRegionName],
       p.[AdditionalContactInfo]
FROM   [HumanResources].[Employee] AS e
       INNER JOIN [Person].[Person] AS p
       ON RTRIM(LTRIM(p.[BusinessEntityID])) = RTRIM(LTRIM(e.[BusinessEntityID]))
       INNER JOIN [Person].[BusinessEntityAddress] AS bea
       ON RTRIM(LTRIM(bea.[BusinessEntityID])) = RTRIM(LTRIM(e.[BusinessEntityID]))
       INNER JOIN [Person].[Address] AS a
       ON RTRIM(LTRIM(a.[AddressID])) = RTRIM(LTRIM(bea.[AddressID]))
       INNER JOIN [Person].[StateProvince] AS sp
       ON RTRIM(LTRIM(sp.[StateProvinceID])) = RTRIM(LTRIM(a.[StateProvinceID]))
       INNER JOIN [Person].[CountryRegion] AS cr
       ON RTRIM(LTRIM(cr.[CountryRegionCode])) = RTRIM(LTRIM(sp.[CountryRegionCode]))
       LEFT OUTER JOIN [Person].[PersonPhone] AS pp
       ON RTRIM(LTRIM(pp.BusinessEntityID)) = RTRIM(LTRIM(p.[BusinessEntityID]))
       LEFT OUTER JOIN [Person].[PhoneNumberType] AS pnt
       ON RTRIM(LTRIM(pp.[PhoneNumberTypeID])) = RTRIM(LTRIM(pnt.[PhoneNumberTypeID]))
       LEFT OUTER JOIN [Person].[EmailAddress] AS ea
       ON RTRIM(LTRIM(p.[BusinessEntityID])) = RTRIM(LTRIM(ea.[BusinessEntityID]))
OPTION(QUERYTRACEON 9481) 

/*
	Memory grant?
	Número de registros estimado?
	Custo?
	Estatísticas de IO?
*/


-- Agora com o novo CE...
CHECKPOINT
DBCC FREEPROCCACHE
DBCC DROPCLEANBUFFERS

SELECT e.[BusinessEntityID],
       p.[Title],
       p.[FirstName],
       p.[MiddleName],
       p.[LastName],
       p.[Suffix],
       e.[JobTitle],
       pp.[PhoneNumber],
       pnt.[Name] AS [PhoneNumberType],
       ea.[EmailAddress],
       p.[EmailPromotion],
       a.[AddressLine1],
       a.[AddressLine2],
       a.[City],
       sp.[Name] AS [StateProvinceName],
       a.[PostalCode],
       cr.[Name] AS [CountryRegionName],
       p.[AdditionalContactInfo]
FROM   [HumanResources].[Employee] AS e
       INNER JOIN [Person].[Person] AS p
       ON RTRIM(LTRIM(p.[BusinessEntityID])) = RTRIM(LTRIM(e.[BusinessEntityID]))
       INNER JOIN [Person].[BusinessEntityAddress] AS bea
       ON RTRIM(LTRIM(bea.[BusinessEntityID])) = RTRIM(LTRIM(e.[BusinessEntityID]))
       INNER JOIN [Person].[Address] AS a
       ON RTRIM(LTRIM(a.[AddressID])) = RTRIM(LTRIM(bea.[AddressID]))
       INNER JOIN [Person].[StateProvince] AS sp
       ON RTRIM(LTRIM(sp.[StateProvinceID])) = RTRIM(LTRIM(a.[StateProvinceID]))
       INNER JOIN [Person].[CountryRegion] AS cr
       ON RTRIM(LTRIM(cr.[CountryRegionCode])) = RTRIM(LTRIM(sp.[CountryRegionCode]))
       LEFT OUTER JOIN [Person].[PersonPhone] AS pp
       ON RTRIM(LTRIM(pp.BusinessEntityID)) = RTRIM(LTRIM(p.[BusinessEntityID]))
       LEFT OUTER JOIN [Person].[PhoneNumberType] AS pnt
       ON RTRIM(LTRIM(pp.[PhoneNumberTypeID])) = RTRIM(LTRIM(pnt.[PhoneNumberTypeID]))
       LEFT OUTER JOIN [Person].[EmailAddress] AS ea
       ON RTRIM(LTRIM(p.[BusinessEntityID])) = RTRIM(LTRIM(ea.[BusinessEntityID]));
GO


