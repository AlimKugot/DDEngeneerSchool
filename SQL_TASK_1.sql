USE AdventureWorks2017
GO

/*
������ 2
������� ����� ����� ������ � ��������� �� ����� � �������, �� ��� ����� ������ ��������
*/
SELECT 
	SUM(ssoh.TotalDue) as sold_totaldue
	,YEAR(ssoh.OrderDate) as sold_year
	,MONTH(ssoh.OrderDate) as sold_month
FROM 
	Sales.SalesOrderHeader AS ssoh
GROUP BY 
	YEAR(ssoh.OrderDate)
	,MONTH(ssoh.OrderDate)
ORDER BY 
	sold_year DESC
	,sold_month DESC;

/*
������ 3
������� 10 ����� ������������ ������� ��� ���������� ��������
�������: ����� | ���������
��������� ������������ ��� ���������� ����������� � ������
� ������ �� ������ ���� ��������
*/
SELECT TOP(10)  
	pa.City
	,COUNT(ssoh.CustomerID) AS [priority]
FROM 
	Sales.SalesOrderHeader AS ssoh
INNER JOIN 
	Person.Address AS pa 
	ON pa.AddressID = ssoh.BillToAddressID
WHERE
	pa.City NOT IN (
		SELECT City
		FROM Person.Address AS ad
		INNER JOIN 
			Person.BusinessEntityAddress AS pbea
			ON ad.AddressID = pbea.AddressID 
		INNER JOIN
			Sales.Store AS ss
			ON ss.BusinessEntityID = pbea.BusinessEntityID 
	) 
GROUP BY pa.City
ORDER BY 
	[priority] DESC
	,pa.City;

/*
������ 4
������� �����������, �������� ������ 15 ������ ������ � ���� �� �������� �� ��� ����� ������ ��������.
�������: ������� ���������� | ��� ���������� | �������� �������� | ���������� ��������� ����������� (�� ��� �����) 
����������� �� ���������� ��������� ����������� �� ��������, ����� �� ������� ����� ���������� �� �����������
*/
SELECT 
	person.LastName
	,person.FirstName
	,product.Name AS product_name
	,SUM(ssod.OrderQty) AS total_bought
FROM Sales.Customer AS sc
INNER JOIN 
	Sales.SalesOrderHeader AS ssoh
	ON sc.CustomerID = ssoh.CustomerID
INNER JOIN 
	Person.Person AS person
	ON sc.PersonID = person.BusinessEntityID
INNER JOIN
	Sales.SalesOrderDetail AS ssod
	ON ssod.SalesOrderID = ssoh.SalesOrderID
INNER JOIN
	Production.Product AS product
	ON product.ProductID = ssod.ProductID
GROUP BY 
	LastName, FirstName, product.Name 
HAVING 
	SUM(ssod.OrderQty) > 15
ORDER BY 
	total_bought DESC
	,LastName
	,FirstName;

/*
������ 5
������� ���������� ������� ������ ������� �������
�������: ���� ������ | ������� ���������� | ��� ���������� | ���������� ������
����������� �� ���� ������ �� ����� � ������
� ������ ����������� ������ ����� ���������� ��� �������� ������ ���������� � ��������� �������:
<��� ������> ����������: <���������� � ������> ��.
<��� ������> ����������: <���������� � ������> ��.
<��� ������> ����������: <���������� � ������> ��.
...
*/
SELECT 
	ssoh.OrderDate
	,person.LastName
	,person.FirstName
	,STRING_AGG(CONVERT(NVARCHAR(max), CONCAT(product.Name, N' ����������: ', ssod.OrderQty, N' ��.')), CHAR(13)) AS product_count
FROM Sales.Customer AS sc
INNER JOIN 
	Sales.SalesOrderHeader AS ssoh
	ON sc.CustomerID = ssoh.CustomerID
INNER JOIN 
	Person.Person AS person
	ON sc.PersonID = person.BusinessEntityID
INNER JOIN
	Sales.SalesOrderDetail AS ssod
	ON ssod.SalesOrderID = ssoh.SalesOrderID
INNER JOIN
	Production.Product AS product
	ON product.ProductID = ssod.ProductID
WHERE ssoh.OrderDate IN (
	SELECT MIN(sohIN.OrderDate) 
	FROM Sales.SalesOrderHeader as sohIN
	JOIN Person.Person AS ppIN
	ON sohIN.SalesPersonID = ppIN.BusinessEntityID 
	GROUP BY ppIN.LastName, ppIN.FirstName
)
GROUP BY 
	OrderDate, LastName, FirstName
ORDER BY 
	OrderDate desc;

-- test case to check sql-select5
SELECT 
	ssoh.OrderDate AS order_date
	,person.LastName
	,person.FirstName
	,product.Name
	,ssod.OrderQty
FROM Sales.Customer AS sc
INNER JOIN 
	Sales.SalesOrderHeader AS ssoh
	ON sc.CustomerID = ssoh.CustomerID
INNER JOIN 
	Person.Person AS person
	ON sc.PersonID = person.BusinessEntityID
	AND person.LastName = 'Leonetti'
INNER JOIN
	Sales.SalesOrderDetail AS ssod
	ON ssod.SalesOrderID = ssoh.SalesOrderID
INNER JOIN
	Production.Product AS product
	ON product.ProductID = ssod.ProductID
ORDER BY 
	order_date;

/*
������ 6
������� ���������� �����������, ���������������� ������������ ������� ������ � ������ �������� � ��������
�������: ��� ������������ | ���� ������ ������������ �� ������| ���� �������� ������������ |
	| ��� ���������� | ���� ������ ���������� �� ������| ���� �������� ����������
���� ��� ������� � ������� '������� �.�.'
����������� �� ������ � �������� �� ��������� ���� � �����������
������ ������ ������ �������� ����������� �� ������� ������������, ����� �� ������� ����������
*/
SELECT 
	CONCAT(pp1.LastName, ' ', LEFT(pp1.FirstName, 1), '.', ISNULL(LEFT(pp1.MiddleName, 1) + '.', '')) AS boss_name
	,empl1.HireDate AS boss_hiredate
	,empl1.BirthDate AS boss_birthday
	,CONCAT(pp2.LastName, ' ', LEFT(pp2.FirstName, 1), '.', ISNULL(LEFT(pp2.MiddleName, 1) + '.', '')) AS employee_name
	,empl2.HireDate AS employee_hiredate
	,empl2.BirthDate AS employee_birthday
FROM HumanResources.Employee AS empl1
INNER JOIN 
	HumanResources.Employee AS empl2
	-- GetAncestor(1) ����������� �������� �� ���� ������� ���� � ������ OrganizationNode
	ON empl1.OrganizationNode.GetAncestor(1)  = empl2.OrganizationNode 
	AND empl1.BirthDate > empl2.BirthDate
	AND empl1.HireDate > empl2.HireDate
INNER JOIN Person.Person AS pp1 ON empl1.BusinessEntityID = pp1.BusinessEntityID
INNER JOIN Person.Person AS pp2 ON empl2.BusinessEntityID = pp2.BusinessEntityID
ORDER BY 
	empl1.OrganizationLevel, pp1.LastName, pp2.LastName;

/*
������ 7
�������� �������� ���������, � ����� ����������� � �������������� ������� ������ 
������� ��������� - ��� ����, � � �� 
�������� �������� - ���������� ��������� ������� 
�������������� ����� �������� ������ ���� �������� ������-�����������, ���������� � �������� ��������� ���
*/
DROP PROCEDURE IF EXISTS HumanResources.UnmarriedMen;
GO

CREATE PROCEDURE HumanResources.UnmarriedMen (
	@from AS date
	,@to AS date
	,@out AS int OUTPUT
)
AS 
BEGIN
	SELECT @out = COUNT(*)
	FROM HumanResources.Employee AS empl
	INNER JOIN
		Person.Person AS pp
		ON pp.BusinessEntityID = empl.BusinessEntityID
	WHERE 
		empl.HireDate BETWEEN @from AND @to
		AND
		empl.Gender = 'M'
		AND
		empl.MaritalStatus <> 'M'
END
GO


DECLARE @from date = '01/01/2010'
DECLARE	@to date = '01/01/2014'
DECLARE	@out int

EXEC HumanResources.UnmarriedMen @from, @to, @out OUTPUT;
PRINT @out
GO