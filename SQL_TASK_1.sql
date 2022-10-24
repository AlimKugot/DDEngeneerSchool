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

*/