
-- Нужно ускорить запросы ниже любыми способами
-- Можно менять текст самого запроса или добавилять новые индексы
-- Схему БД менять нельзя
-- В овете пришлите итоговый запрос и все что было создано для его ускорения

-- Задача 1
DECLARE @StartTime datetime2 = '2010-08-30 16:27';

SELECT TOP(5000) wl.SessionID, wl.ServerID, wl.UserName 
FROM Marketing.WebLog AS wl
WHERE wl.SessionStart >= @StartTime
ORDER BY wl.ServerID;
-- убрал сортировку по wl.SessionStart, тк её нет в SELECT
-- ORDER BY wl.SessionStart, wl.ServerID;
GO


-- Задача 2
CREATE NONCLUSTERED INDEX IX_StateCode ON Marketing.PostalCode(StateCode);

SELECT PostalCode, Country
FROM Marketing.PostalCode 
WHERE StateCode = 'KY'
ORDER BY PostalCode;
-- нет смысла сортировать по StateCode равной константе
-- ORDER BY StateCode, PostalCode;
GO

-- Задача 3
DROP INDEX IF EXISTS IX_Lastname ON Marketing.Prospect;
DROP INDEX IF EXISTS IX_Prospect_All ON Marketing.Prospect;

CREATE NONCLUSTERED INDEX IX_Lastname ON Marketing.Prospect(LastName);
CREATE NONCLUSTERED INDEX IX_Prospect_All ON Marketing.Prospect
(
	[LastName] ASC,
	[ProspectID] ASC
)
INCLUDE([FirstName],[MiddleName],[CellPhoneNumber],[HomePhoneNumber],[WorkPhoneNumber],[Demographics],[LatestContact],[EmailAddress]) WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]


DECLARE @Counter INT = 0;
WHILE @Counter < 150
BEGIN
  SELECT p.LastName, p.FirstName 
  FROM Marketing.Prospect AS p
  INNER JOIN Marketing.Salesperson AS sp
  ON p.LastName = sp.LastName
  -- лишнее, тк используем сравнение со значением
  -- ORDER BY p.LastName, p.FirstName;
  
  SELECT * 
  FROM Marketing.Prospect AS p
  WHERE p.LastName = 'Smith';
  SET @Counter += 1;
END;

-- Задача 4
DROP INDEX IF EXISTS IX_Product ON Marketing.Product;
DROP INDEX IF EXISTS IX_ProductModel ON Marketing.ProductModel;

CREATE NONCLUSTERED INDEX IX_Product ON Marketing.Product (SubcategoryID, ProductModelID); 
CREATE NONCLUSTERED INDEX IX_ProductModel ON Marketing.ProductModel (ProductModel) INCLUDE (ProductModelID);

SELECT
	c.CategoryName,
	sc.SubcategoryName,
	pm.ProductModel,
	COUNT(p.ProductID) AS ModelCount
FROM Marketing.ProductModel pm
	JOIN Marketing.Product p
		ON p.ProductModelID = pm.ProductModelID
	JOIN Marketing.Subcategory sc
		ON sc.SubcategoryID = p.SubcategoryID
	JOIN Marketing.Category c
		ON c.CategoryID = sc.CategoryID
GROUP BY c.CategoryName,
	sc.SubcategoryName,
	pm.ProductModel
HAVING COUNT(p.ProductID) > 1