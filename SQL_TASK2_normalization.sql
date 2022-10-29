USE Demo
GO

DROP TABLE IF EXISTS Orders;
DROP TABLE IF EXISTS ProductPrice;
DROP TABLE IF EXISTS Product;
DROP TABLE IF EXISTS Currency;
DROP TABLE IF EXISTS Customer;

CREATE TABLE Customer(
	Fullname nvarchar(255) PRIMARY KEY
	,Sex char(1) NOT NULL
	,CONSTRAINT [Check_Sex] CHECK (Sex IN ('М','Ж'))
);

CREATE TABLE Currency (
	CurrencyCode nvarchar(3) PRIMARY KEY
	,CurrencyDetailName nvarchar(50) NULL 
);

CREATE TABLE Product(
	ProductName nvarchar(255) PRIMARY KEY
);

-- возможно, один и тот же продукт имеет разные цены
-- например: 
-- рыба 1кг = 500 руб
-- рыба 100 кг = 500*95 руб
-- рыба 1 тонна = 500*900 руб 
-- (вспомнил пример со скидкой на фирму bmw в презентации)
CREATE TABLE ProductPrice(
	ProductPriceID int IDENTITY(1,1) PRIMARY KEY
	,ProductName nvarchar(255)
	,Unit nvarchar(15) NOT NULL
	,UnitPrice money NOT NULL
	,CurrencyCode nvarchar(3) NOT NULL DEFAULT 'РУБ'
	,PricedDate date NOT NULL DEFAULT GETDATE()
	,CONSTRAINT FK_PRODUCT_NAME
		FOREIGN KEY (ProductName)
		REFERENCES Product(ProductName)
		ON UPDATE CASCADE 
	,CONSTRAINT FK_Currency_ID
		FOREIGN KEY (CurrencyCode)
		REFERENCES Currency(CurrencyCode)
);

CREATE TABLE Orders(
	OrderID int IDENTITY(1,1) PRIMARY KEY
	-- Адрес можно было бы отнести к таблице Customer, если б он был фиксированным.
	-- Однако, один и тот же человек может заказывать в одном городе в разные места
	--
	-- Например: Петр заказал парусину к Порту, еду к Невскому проспекту и заказнные книги предпочёл забрать в "Подписных изданиях"
	-- Нам важно, что это именно Петр заказал, а адрес относится к заказу 
	,DeliveryAddress nvarchar(255) NOT NULL
	,DeliveryDate date NOT NULL
	,Qty int NOT NULL
	,CustomerFullname nvarchar(255) NOT NULL
	,ProductPriceID int NOT NULL
	,OrderedDate date NOT NULL DEFAULT GETDATE()
	,CONSTRAINT FK_Customer_Fullname
		FOREIGN KEY (CustomerFullname)
		REFERENCES Customer(FullName)
		ON UPDATE CASCADE
	,CONSTRAINT FK_Product_PRICE_NAME
		FOREIGN KEY (ProductPriceID)
		REFERENCES ProductPrice(ProductPriceID)
		ON UPDATE CASCADE
);


INSERT INTO Customer(Fullname, Sex) VALUES ('Петр Романов', 'М');
INSERT INTO Customer(Fullname, Sex) VALUES ('Софи́я Авгу́ста Фредери́ка А́нгальт-Це́рбстская', 'Ж');
INSERT INTO Customer(Fullname, Sex) VALUES ('Александр Рюрикович', 'М');

INSERT INTO Currency(CurrencyCode, CurrencyDetailName) VALUES ('РУБ', 'Российский рубль');

INSERT INTO Product(ProductName) VALUES('Рама оконная');
INSERT INTO Product(ProductName) VALUES('Платье бальное');
INSERT INTO Product(ProductName) VALUES('Грудки куриные');
INSERT INTO Product(ProductName) VALUES('Cалат');
INSERT INTO Product(ProductName) VALUES('Топор');
INSERT INTO Product(ProductName) VALUES('Пила');
INSERT INTO Product(ProductName) VALUES('Доски');
INSERT INTO Product(ProductName) VALUES('Брус');
INSERT INTO Product(ProductName) VALUES('Парусина');

INSERT INTO ProductPrice(ProductName, UnitPrice, Unit) VALUES ('Рама оконная', 3875, 'шт');
INSERT INTO ProductPrice(ProductName, UnitPrice, Unit) VALUES ('Платье бальное', 15000, 'шт'); 
INSERT INTO ProductPrice(ProductName, UnitPrice, Unit) VALUES ('Грудки куриные', 180, 'кг');
INSERT INTO ProductPrice(ProductName, UnitPrice, Unit) VALUES ('Cалат', 52, 'шт');
INSERT INTO ProductPrice(ProductName, UnitPrice, Unit) VALUES ('Топор', 500, 'шт');
INSERT INTO ProductPrice(ProductName, UnitPrice, Unit) VALUES ('Пила', 450, 'шт');
INSERT INTO ProductPrice(ProductName, UnitPrice, Unit) VALUES ('Доски', 4890, 'м3');
INSERT INTO ProductPrice(ProductName, UnitPrice, Unit) VALUES ('Брус', 9390, 'м3');
INSERT INTO ProductPrice(ProductName, UnitPrice, Unit) VALUES ('Парусина', 182, 'м.п.');
INSERT INTO ProductPrice(ProductName, UnitPrice, Unit) VALUES ('Брус', 9390, 'м3');


Set DateFormat MDY 

INSERT INTO 
	Orders(DeliveryAddress, DeliveryDate, Qty, CustomerFullname, ProductPriceID)
VALUES
	('СПб, Сенатская площадь д.1', '1703-05-27', 1, 'Петр Романов', 5)
	,('СПб, Сенатская площадь д.1', '1704-05-11', 1, 'Петр Романов', 6)
	,('СПб, Сенатская площадь д.1', '1704-05-11', 200, 'Петр Романов', 7)
	,('СПб, Сенатская площадь д.1', '1704-05-11', 20, 'Петр Романов', 8) 
	,('СПб, Сенатская площадь д.1', '1704-05-11', 100, 'Петр Романов', 9)

	,('СПб, площадь Островского д.1', '1762-06-28', 999, 'Софи́я Авгу́ста Фредери́ка А́нгальт-Це́рбстская', 2)

	,('СПб, пл. Александра Невского д.1', '1242-04-05', 5, 'Александр Рюрикович', 3) 
	,('СПб, пл. Александра Невского д.1', '1242-04-05', 5, 'Александр Рюрикович', 4)
;


SELECT c.Fullname
	, c.Sex
	, o.DeliveryDate
	, o.DeliveryAddress
	, pp.ProductName
	, o.Qty
	, pp.Unit
	, pp.UnitPrice
	, pp.CurrencyCode
	, (pp.UnitPrice * o.Qty) AS total_price
FROM Orders AS o
INNER JOIN 
	ProductPrice AS pp
	ON pp.ProductPriceID = o.ProductPriceID
INNER JOIN
	Customer AS c
	ON c.Fullname = o.CustomerFullname;