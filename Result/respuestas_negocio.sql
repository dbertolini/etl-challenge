/*
	Author: Diego Bertolini
	Date: 15/04/2020 
*/

/* 1. Cantidad de usuarios donde su apellido comience con la letra ‘M’. */

-- Es un simple script el cual cuenta con un select y el filtro correspondiente
-- para obtener todos los Surname que comiencen con la letra 'M', para 
-- finalmente contabilizarlos.

SELECT COUNT(*) AS Quatity
FROM Customer
WHERE Surname LIKE 'M%';

/* 2. Listado de los usuarios que cumplan años en el día de la fecha (hoy). */

-- Es un select el cual filtra mes y día dentro de la tabla Customer, segun 
-- la fecha actual.

SELECT *
FROM Customer
WHERE DAY(Birthdate) = DAY(GETDATE())
	AND MONTH(Birthdate) = MONTH(GETDATE());

/* 3. Por día se necesita, cantidad de ventas realizadas, cantidad de productos vendidos
y monto total transaccionado para el mes de Enero del 2020. */

-- Se genera un select con las funciones de agregación correspondientes a lo requerido
-- por el enunciado, y sus relaciones entre las tablas Order e Item, con sus filtros y
-- agrupadores. Cabe destacar que los dias visualizados en el listado dependerán
-- de su existencia en los registros, es decir que si algun día del calendario
-- no tienen ningún registro de ventas en la tabla 'Order', el mismo no se visualizará.

SELECT [Order].Due, COUNT(*) AS SalesQuantity, 
	SUM([Order].Quantity) AS ItemsQuantity, 
	SUM(Item.Amount * [Order].Quantity) AS Amount
FROM [Order]
	INNER JOIN Item ON [Order].ItemId = Item.Id
WHERE MONTH([Order].Due) = 1
	AND YEAR([Order].Due) = 2020
GROUP BY [Order].Due;

/* 4. Por cada mes del 2019, se solicita el top 5 de usuarios que más vendieron ($) en la
categoría Celulares. Se requiere el mes y año de análisis, nombre y apellido del
vendedor, la cantidad vendida y el monto total transaccionado. */

-- El query select principal que se ejecuta, obtiene todos los usuarios que vendieron segun
-- estan relacionados con la tabla de Order, el cual tiene un ordenamiento y lo mas importante
-- un campo 'rownumber' el cual es un contador que se va a utilizar posteriormente para
-- la selección solamente de las 5 primeras personas.
-- El filtro de la categoría fue expresado con un simple Id de la misma. Esto esta sujero
-- a verdaderamente como requiera hacerlo, es decir, si es por uno o varios Ids que contengan
-- el string 'Celulares', en ese caso tambien se puede realizar el filtro.

WITH result AS
(
SELECT MONTH([Order].Due) AS [Month], 
	YEAR([Order].Due) AS [Year], 
	Customer.Name, 
	Customer.Surname,
	SUM([Order].Quantity) AS ItemsQuantity,
	SUM(Item.Amount * [Order].Quantity) AS Amount,
	ROW_NUMBER() OVER (PARTITION BY 
			YEAR([Order].Due), 
			MONTH([Order].Due) 
			ORDER BY 
			YEAR([Order].Due),	
			MONTH([Order].Due), 
			SUM(Item.Amount * [Order].Quantity) DESC) AS rownumber
FROM [Order]
	INNER JOIN Customer ON [Order].BuyerCustomerId = Customer.Id
	INNER JOIN Item ON [Order].ItemId = Item.Id
WHERE YEAR([Order].Due) = 2019
	AND CategoryId = 3
GROUP BY MONTH([Order].Due), 
	YEAR([Order].Due),
	Customer.Name, 
	Customer.Surname
	)
SELECT [Month],
	[Year], 
	Name, 
	Surname,
	ItemsQuantity,
	Amount
FROM result
WHERE rownumber <= 5;

/* 5. Se solicita poblar una tabla con el precio y estado de los Items a fin del día (se
puede resolver a través de StoredProcedure).
a. Vale resaltar que en la tabla Item, vamos a tener únicamente el último estado
informado por la PK definida.
b. Esta información nos va a permitir realizar análisis para entender el
comportamiento de los diferentes Items (por ejemplo evolución de Precios,
cantidad de Items activos). */

-- Se crea el siguiente Stored Procedure con el script de inserción hacia la tabla
-- creada con anterioridad llamada 'ItemHistory':

CREATE PROCEDURE PopulateItemHistory
AS
BEGIN
	SET NOCOUNT ON;

	INSERT INTO ItemHistory (ItemId,
	  Due,
      Amount,
      [State],
      ExpiryDate,
      ProductName,
      CategoryId)
    SELECT Id AS ItemId,
	  GETDATE() AS Due,
      Amount,
      [State],
      ExpiryDate,
      ProductName,
      CategoryId
	FROM Item;

END
GO

-- Execution: se puede crear un Job que llame al Stored Procedure anteriormente creado, 
-- que se ejecute al final del dia. Para la ejecucion manual:
EXEC PopulateItemHistory;

/* 6. Desde IT nos comentan que la tabla de Categorías tiene un issue ya que cuando
generan modificaciones de una categoría se genera un nuevo registro con la misma
PK en vez de actualizar el ya existente. Teniendo en cuenta que tenemos una
columna de Fecha de LastUpdated, se solicita crear una nueva tabla y poblar la
misma sin ningún tipo de duplicados garantizando la calidad y consistencia de los
datos. */

-- Cree una tabla 'CategoryDuplicates' que simula tener duplicados con la misma PK segun 
-- menciona el enunciado sin modificar la estructura general para el resto del examen 
-- con el cual fue confeccionado. La tabla donde se insertan los datos es 'CategoryNew'.
-- Esta ultima, fue previamente generada, pero tranquilamente se puede colocar un script
-- para su generación.

INSERT INTO CategoryNew (Id,
	Name,
	CategoryId,
	LastUpdated)
SELECT CategoryDuplicates.Id,
	CategoryDuplicates.Name,
    CategoryDuplicates.CategoryId,
    CategoryDuplicates.LastUpdated
FROM CategoryDuplicates
INNER JOIN (SELECT Id,
		Max(LastUpdated) AS MaxLastUpdate
	FROM CategoryDuplicates
	GROUP BY Id) AS CategoryMaxLastUpdate
ON CategoryDuplicates.Id = CategoryMaxLastUpdate.Id 
	AND CategoryDuplicates.LastUpdated = CategoryMaxLastUpdate.MaxLastUpdate

