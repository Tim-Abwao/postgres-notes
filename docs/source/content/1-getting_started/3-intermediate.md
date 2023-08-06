# Intermediate

First, let's refresh the sample data:

```console
$ dropdb mydb  # start afresh
$ createdb mydb
$ psql mydb 
psql (15.3)
Type "help" for help.

mydb=> 
```

```psql
mydb=> \i sample_tables.sql 
BEGIN
CREATE TABLE
INSERT 0 10
CREATE TABLE
INSERT 0 8
CREATE TABLE
INSERT 0 15
COMMIT
```

## 1. Views

Creating a view over a query *gives it a name* that you can refer to like an ordinary table:

```psql
mydb=> CREATE VIEW price_info AS
mydb->   SELECT pu.supplier_name, pu.product_name, pr.price AS selling_price,
mydb->          pu.unit_price AS purchase_price, (pr.price - pu.unit_price) AS profit_per_unit
mydb->     FROM purchases pu JOIN products pr ON pu.product_name = pr.name
mydb->     ORDER BY profit_per_unit DESC;
CREATE VIEW
mydb=> SELECT * FROM price_info LIMIT 5;
        supplier_name        | product_name | selling_price | purchase_price | profit_per_unit 
-----------------------------+--------------+---------------+----------------+-----------------
 Zing Gardens                | Watermelons  |         42.00 |          39.95 |            2.05
 City Merchants              | Bananas      |         10.00 |           8.00 |            2.00
 Green Thumb Corp.           | Spinach      |          7.50 |           5.95 |            1.55
 ACME Fruits Ltd             | Bananas      |         10.00 |           8.50 |            1.50
 Village Growers Association | Mangoes      |         30.00 |          28.50 |            1.50
(5 rows)
```

Using views is considered *good SQL database design*. You can use views almost anywhere a table can be used. You can build views upon other views.

## 2. Foreign keys

Foreign keys maintain *referential integrity*, ensuring that you can't insert values in one table that do not have a matching reference in another.

```psql
mydb=> INSERT INTO purchases VALUES('Planet Farms', 'Coconuts', 10, 15.00, '2023-07-29');
ERROR:  insert or update on table "purchases" violates foreign key constraint "purchases_product_name_fkey"
DETAIL:  Key (product_name)=(Coconuts) is not present in table "products".
```

More on *foreign keys* and other *constraints* later.

## 3. Transactions

Transactions *bundle multiple steps into a single, all-or-nothing operation*.

A transactional database guarantees that all the updates made by a transaction are *logged in permanent storage* (i.e. on disk) before the transaction is reported complete.

Transactions are *atomic*: from the point of view of other transactions, they either happen completely or not at all. Intermediate states between the steps in a transaction are invisible to other concurrent transactions.

{.no-copybutton}

```psql
mydb=> BEGIN; -- record a purchase and update inventory
BEGIN
mydb=*> INSERT INTO purchases (supplier_name, product_name, units, unit_price, last_delivery_date)
mydb-*>   VALUES ('Zing Gardens', 'Pineapples', 30, 33.75, '2023-07-30');
INSERT 0 1
mydb=*> UPDATE products SET items_in_stock = items_in_stock + 30
mydb-*>   WHERE name = 'Pineapples';
UPDATE 1
mydb=*> COMMIT;
COMMIT
```

You can use the `ROLLBACK` command to cancel an ongoing transaction:

{.no-copybutton emphasize-lines=5}

```psql
mydb=> BEGIN;
BEGIN
mydb=*> INSERT INTO products (name, items_in_stock, price) VALUES ('Pumpkins', 10, 12.00);
INSERT 0 1
mydb=*> ROLLBACK;
ROLLBACK
mydb=> SELECT * FROM products WHERE name = 'Pumpkins';  -- insert was undone by rollback
 name | items_in_stock | price 
------+----------------+-------
(0 rows)
```

You can use the `SAVEPOINT` command to define *savepoints*. You can then use `ROLLBACK TO` to roll back to your savepoints as many times as you'll need to. No need to start all over.

{.no-copybutton emphasize-lines=11}

```psql
mydb=> BEGIN;
BEGIN
mydb=*> INSERT INTO products (name, items_in_stock, price) VALUES ('Pumpkins', 10, 12.00);
INSERT 0 1
mydb=*> SELECT * FROM products WHERE name = 'Pumpkins';
   name   | items_in_stock | price 
----------+----------------+-------
 Pumpkins |             10 | 12.00
(1 row)

mydb=*> SAVEPOINT added_pumpkins;
SAVEPOINT
mydb=*> UPDATE products SET price = 10 WHERE name = 'Pumpkins';
UPDATE 1
mydb=*> SELECT * FROM products WHERE name = 'Pumpkins';
   name   | items_in_stock | price 
----------+----------------+-------
 Pumpkins |             10 | 10.00
(1 row)

mydb=*> ROLLBACK TO added_pumpkins;
ROLLBACK
mydb=*> SELECT * FROM products WHERE name = 'Pumpkins';
   name   | items_in_stock | price 
----------+----------------+-------
 Pumpkins |             10 | 12.00
(1 row)
mydb=*> COMMIT;
COMMIT
```

## 4. Window functions

A window function *performs a calculation across a set of table rows that are somehow related to the current row*.

Whereas aggregate functions group rows into single output rows, the rows in window fuctions retain their separate identities.

A window function call always contains an `OVER` clause, which determines how the rows of the query are *split up for processing by the window function*.

A `PARTITION BY` clause within `OVER` divides the rows into groups.

To compare the prices of products from different suppliers against the average:

```psql
mydb=> SELECT product_name, supplier_name, unit_price,
mydb->        avg(unit_price) OVER (PARTITION BY product_name) AS avg_price
mydb->   FROM purchases
mydb->   ORDER BY avg_price DESC, unit_price DESC;
 product_name |        supplier_name        | unit_price |      avg_price      
--------------+-----------------------------+------------+---------------------
 Watermelons  | Zing Gardens                |      39.95 | 39.9500000000000000
 Pineapples   | Zing Gardens                |      33.75 | 33.7500000000000000
 Pineapples   | Zing Gardens                |      33.75 | 33.7500000000000000
 Mangoes      | Tropical Paradise Ltd       |      29.05 | 28.7750000000000000
 Mangoes      | Village Growers Association |      28.50 | 28.7750000000000000
 Apples       | Planet Farms                |      24.10 | 23.8000000000000000
 Apples       | Jolly Grocers               |      23.80 | 23.8000000000000000
 Apples       | Village Growers Association |      23.50 | 23.8000000000000000
 Bananas      | City Merchants              |       9.00 |  8.5000000000000000
 Bananas      | ACME Fruits Ltd             |       8.50 |  8.5000000000000000
 Bananas      | City Merchants              |       8.00 |  8.5000000000000000
 Spinach      | Green Thumb Corp.           |       5.95 |  5.9500000000000000
 Kiwis        | Tropical Paradise Ltd       |       4.00 |  4.0000000000000000
 Tomatoes     | Village Growers Association |       3.80 |  3.8000000000000000
 Lemons       | Tropical Paradise Ltd       |       3.25 |  3.2500000000000000
 Cherries     | Jolly Grocers               |       2.15 |  2.1500000000000000
(16 rows)
```

You can control the order in which rows are processed by window functions using `ORDER BY` within `OVER`.

```psql
mydb=> SELECT product_name, supplier_name, unit_price,
mydb->        rank() OVER (PARTITION BY product_name ORDER BY unit_price DESC)
mydb->   FROM purchases;
 product_name |        supplier_name        | unit_price | rank 
--------------+-----------------------------+------------+------
 Apples       | Planet Farms                |      24.10 |    1
 Apples       | Jolly Grocers               |      23.80 |    2
 Apples       | Village Growers Association |      23.50 |    3
 Bananas      | City Merchants              |       9.00 |    1
 Bananas      | ACME Fruits Ltd             |       8.50 |    2
 Bananas      | City Merchants              |       8.00 |    3
 Cherries     | Jolly Grocers               |       2.15 |    1
 Kiwis        | Tropical Paradise Ltd       |       4.00 |    1
 Lemons       | Tropical Paradise Ltd       |       3.25 |    1
 Mangoes      | Tropical Paradise Ltd       |      29.05 |    1
 Mangoes      | Village Growers Association |      28.50 |    2
 Pineapples   | Zing Gardens                |      33.75 |    1
 Pineapples   | Zing Gardens                |      33.75 |    1
 Spinach      | Green Thumb Corp.           |       5.95 |    1
 Tomatoes     | Village Growers Association |       3.80 |    1
 Watermelons  | Zing Gardens                |      39.95 |    1
(16 rows)

```

For each row, there's a set of rows within its partition called its *window frame*. By default, including `ORDER BY` limits the frame to "from start to current row (plus any rows equal to current row)":

```psql
mydb=> SELECT unit_price, sum(unit_price) OVER (ORDER BY unit_price) FROM purchases;
 unit_price |  sum   
------------+--------
       2.15 |   2.15
       3.25 |   5.40
       3.80 |   9.20
       4.00 |  13.20
       5.95 |  19.15
       8.00 |  27.15
       8.50 |  35.65
       9.00 |  44.65
      23.50 |  68.15
      23.80 |  91.95
      24.10 | 116.05
      28.50 | 144.55
      29.05 | 173.60
      33.75 | 241.10
      33.75 | 241.10
      39.95 | 281.05
(16 rows)
```

When `PARTITION BY` and `ORDER BY` are omitted, the default frame consists of all the rows in one partition:

```psql
mydb=> SELECT unit_price, sum(unit_price) OVER () FROM purchases;
 unit_price |  sum   
------------+--------
       8.50 | 281.05
       5.95 | 281.05
      23.80 | 281.05
      24.10 | 281.05
       9.00 | 281.05
      39.95 | 281.05
      28.50 | 281.05
       3.25 | 281.05
       4.00 | 281.05
       2.15 | 281.05
      33.75 | 281.05
       8.00 | 281.05
      29.05 | 281.05
       3.80 | 281.05
      23.50 | 281.05
      33.75 | 281.05
(16 rows)
```

```{note}
Window functions are *only permitted in the `SELECT` list and the `ORDER BY` clause* of the query. They are forbidden elsewhere, such as in `GROUP BY`, `HAVING` and `WHERE`; since they logically execute after the processing of these clauses.

Additionally, window functions execute after non-window aggregate functions. This means it is valid to include an aggregate function call in the arguments of a window function, but not vice versa.
```

A query can have multiple window functions. If the same windowing behaviour is required, you can avoid duplication using a `WINDOW` clause that is then referenced in `OVER`:

```psql
mydb=> SELECT product_name, unit_price, avg(unit_price) OVER w, stddev(unit_price) OVER w
mydb->   FROM purchases 
mydb->   WINDOW w AS (PARTITION BY product_name);
 product_name | unit_price |         avg         |         stddev         
--------------+------------+---------------------+------------------------
 Apples       |      24.10 | 23.8000000000000000 | 0.30000000000000000000
 Apples       |      23.50 | 23.8000000000000000 | 0.30000000000000000000
 Apples       |      23.80 | 23.8000000000000000 | 0.30000000000000000000
 Bananas      |       8.50 |  8.5000000000000000 | 0.50000000000000000000
 Bananas      |       9.00 |  8.5000000000000000 | 0.50000000000000000000
 Bananas      |       8.00 |  8.5000000000000000 | 0.50000000000000000000
 Cherries     |       2.15 |  2.1500000000000000 |                       
 Kiwis        |       4.00 |  4.0000000000000000 |                       
 Lemons       |       3.25 |  3.2500000000000000 |                       
 Mangoes      |      28.50 | 28.7750000000000000 | 0.38890872965260113842
 Mangoes      |      29.05 | 28.7750000000000000 | 0.38890872965260113842
 Pineapples   |      33.75 | 33.7500000000000000 |                      0
 Pineapples   |      33.75 | 33.7500000000000000 |                      0
 Spinach      |       5.95 |  5.9500000000000000 |                       
 Tomatoes     |       3.80 |  3.8000000000000000 |                       
 Watermelons  |      39.95 | 39.9500000000000000 |                       
(16 rows)
```

## 5. Inheritance

Inheritance allows a table to derive columns from zero or more parent tables.

```psql
mydb=> CREATE TABLE exotic_fruits (
mydb(>   relative_size  varchar(12),
mydb(>   shelf_life     interval
mydb(> ) INHERITS (products);
CREATE TABLE                                                      
mydb=> INSERT INTO exotic_fruits (name, items_in_stock, price, relative_size, shelf_life)
mydb->   VALUES ('Pomegranates', 25, 32.00, 'small', '2 weeks');
INSERT 0 1
mydb=> SELECT * FROM exotic_fruits;
     name     | items_in_stock | price | relative_size | shelf_life 
--------------+----------------+-------+---------------+------------
 Pomegranates |             25 | 32.00 | small         | 14 days
(1 row)
```

A row of *exotic_fruits* inherits all columns (name, items_in_stock and price) from its parent, *products*.

By default, the data from a child table is included in scans of its parents (e.g Pomegranates from *exotic_fruits* automatically appears in scans of *products*):

```psql
mydb=> SELECT * FROM products;
     name     | items_in_stock | price 
--------------+----------------+-------
 Apples       |            100 | 25.00
 Bananas      |             32 | 10.00
 Cherries     |             74 |  3.00
 Kiwis        |             54 |  5.00
 Lemons       |             49 |  4.00
 Mangoes      |             38 | 30.00
 Pineapples   |             26 | 35.00
 Spinach      |             19 |  7.50
 Tomatoes     |             43 |  4.50
 Watermelons  |             22 | 42.00
 Pumpkins     |             10 | 12.00
 Pomegranates |             25 | 32.00
(12 rows)
```

`ONLY` can be used to indicate that a query should be run over only the specified table, and not tables below it in the inheritance hierarchy:

```psql
mydb=> SELECT * FROM ONLY products;
    name     | items_in_stock | price 
-------------+----------------+-------
 Apples      |            100 | 25.00
 Bananas     |             32 | 10.00
 Cherries    |             74 |  3.00
 Kiwis       |             54 |  5.00
 Lemons      |             49 |  4.00
 Mangoes     |             38 | 30.00
 Pineapples  |             26 | 35.00
 Spinach     |             19 |  7.50
 Tomatoes    |             43 |  4.50
 Watermelons |             22 | 42.00
 Pumpkins    |             10 | 12.00
(11 rows)
```

More on inheritance later.
