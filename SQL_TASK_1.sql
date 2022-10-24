USE AdventureWorks2017
GO

/*
������ 2
������� ����� ����� ������ � ��������� �� ����� � �������, �� ��� ����� ������ ��������
*/
SELECT 
	SUM(ssoh.TotalDue) as sold_totaldue
	,YEAR(ssoh.ModifiedDate) as sold_year
	,MONTH(ssoh.ModifiedDate) as sold_month
FROM 
	Sales.SalesOrderHeader AS ssoh
GROUP BY 
	YEAR(ssoh.ModifiedDate)
	,MONTH(ssoh.ModifiedDate)
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
	MIN(ssoh.OrderDate) AS order_date
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
GROUP BY 
	LastName, FirstName
ORDER BY 
	order_date desc;

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
	CONCAT(pp1.LastName, ' ', LEFT(pp1.FirstName, 1), '.', ISNULL(LEFT(pp1.MiddleName, 1) + '.', '')) AS older_name
	,empl1.HireDate AS older_hiredate
	,empl1.BirthDate AS older_birthday
	,CONCAT(pp2.LastName, ' ', LEFT(pp2.FirstName, 1), '.', ISNULL(LEFT(pp2.MiddleName, 1) + '.', '')) AS younger_name
	,empl2.HireDate AS younger_hiredate
	,empl2.BirthDate AS younger_birthday
FROM HumanResources.Employee AS empl1
INNER JOIN 
	HumanResources.Employee AS empl2
	-- GetAncestor(1) ����������� �������� �� ���� ������� ���� � ������ OrganizationNode
	ON empl1.OrganizationNode.GetAncestor(1)  = empl2.OrganizationNode 
	AND empl1.OrganizationLevel > empl2.OrganizationLevel
	AND empl1.BirthDate > empl2.BirthDate
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
	@from AS date,
	@to AS date
)
AS 
BEGIN
	DECLARE @men_count AS INT
	SELECT @men_count=COUNT(*)
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
	RETURN @men_count
END
GO

DECLARE	@return_value INT
EXEC	@return_value = HumanResources.UnmarriedMen
        @from = '01/01/2010',
		@to = '01/01/2014'
SELECT	'Return Value' = @return_value
GO