USE AdventureWorks2017
GO

/*
Задача 2
Вывести общую сумму продаж с разбивкой по годам и месяцам, за все время работы компании
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
Задача 3
Выбрать 10 самых приоритетных городов для следующего магазина
Столбцы: Город | Приоритет
Приоритет определяется как количество покупателей в городе
В городе не должно быть магазина
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
Задача 4
Выбрать покупателей, купивших больше 15 единиц одного и того же продукта за все время работы компании.
Столбцы: Фамилия покупателя | Имя покупателя | Название продукта | Количество купленных экземпляров (за все время) 
Упорядочить по количеству купленных экземпляров по убыванию, затем по полному имени покупателя по возрастанию
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
Задача 5
Вывести содержимое первого заказа каждого клиента
Столбцы: Дата заказа | Фамилия покупателя | Имя покупателя | Содержимое заказа
Упорядочить по дате заказа от новых к старым
В ячейку содержимого заказа нужно объединить все элементы заказа покупателя в следующем формате:
<Имя товара> Количество: <количество в заказе> шт.
<Имя товара> Количество: <количество в заказе> шт.
<Имя товара> Количество: <количество в заказе> шт.
...
*/
SELECT 
	MIN(ssoh.OrderDate) AS order_date
	,person.LastName
	,person.FirstName
	,STRING_AGG(CONVERT(NVARCHAR(max), CONCAT(product.Name, N' Количество: ', ssod.OrderQty, N' шт.')), CHAR(13)) AS product_count
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
Задача 6
Вывести содержимое сотрудников, непосредственный руководитель которых младше и меньше работает в компании
Столбцы: Имя руководителя | Дата приема руководителя на работу| Дата рождения руководителя |
	| Имя сотрудника | Дата приема сотрудника на работу| Дата рождения сотрудника
Поле имя выводит в формате 'Фамилия И.О.'
Упорядочить по уровню в иерархии от директора вниз к сотрудникам
Внутри одного уровня иерархии упорядочить по фамилии руководителя, затем по фамилии сотрудника
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
	-- GetAncestor(1) вытаскивает потомков на один уровень ниже в дереве OrganizationNode
	ON empl1.OrganizationNode.GetAncestor(1)  = empl2.OrganizationNode 
	AND empl1.OrganizationLevel > empl2.OrganizationLevel
	AND empl1.BirthDate > empl2.BirthDate
INNER JOIN Person.Person AS pp1 ON empl1.BusinessEntityID = pp1.BusinessEntityID
INNER JOIN Person.Person AS pp2 ON empl2.BusinessEntityID = pp2.BusinessEntityID
ORDER BY 
	empl1.OrganizationLevel, pp1.LastName, pp2.LastName;

/*
Задача 7
Написать хранимую процедуру, с тремя параметрами и результирующим набором данных 
входные параметры - две даты, с и по 
выходной параметр - количество найденных записей 
Результирующий набор содержит записи всех холостых мужчин-сотрудников, родившихся в диапазон указанных дат
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