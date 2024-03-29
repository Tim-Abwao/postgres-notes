# Basics

[SQL][sql] (Structured Query Language) is a domain-specific language used to manage / process data  stored in relational database management systems ([RDBMS][rdbms]) e.g *MySQL*, *PostgreSQL*, *SQLite*. A *relation* is a **table**.

[sql]: https://en.wikipedia.org/wiki/SQL
[rdbms]: https://en.wikipedia.org/wiki/Relational_database_management_system

A table is a named collection of **row**s. Several tables can be grouped in a **database**. A collection of databases managed by a single server instance is called a **database cluster**.

Each row has the same set of named **column**s.  The order of rows within a table is not guaranteed, but you can sort values for display.

Each column has a *specific data type*, and a *fixed order* in each row.

Spaces, tabs and newlines can be used freely in SQL commands.

`--` introduces single-line comments.

## 1. Creating a table

Use a `CREATE TABLE` statement with column names and their data types:

```console
$ psql mydb
psql (15.3)
Type "help" for help.
mydb=> 
```

```psql
mydb=> CREATE TABLE products (
mydb(>   name             varchar(50),
mydb(>   items_in_stock   int,
mydb(>   price            numeric(7, 2)
mydb(> );
CREATE TABLE
```

## 2. Populating a table

Use an `INSERT` command:

```psql
mydb=> INSERT INTO products (name, items_in_stock, price) VALUES ('Apples', 100, 25);
INSERT 0 1
```

You can list columns in any order, with their respective values:

```psql
mydb=> INSERT INTO products (price, name, items_in_stock) VALUES (10, 'Bananas', 32);
INSERT 0 1
```

You can insert values without specifying columns (not recommended):

```psql
mydb=> INSERT INTO products VALUES ('Cherries', 74, 2.5);
INSERT 0 1
```

You can also use the `COPY` command to load large amounts of data from *flat-text files* (e.g. txt, csv) into a table.

````{tip}
The *psql* `\copy` command is more user-friendly when fetching/storing data in a file *accessible to the psql client*:

{.no-copybutton}

```psql
\copy table_name FROM '/path/to/data.csv'
```

````

## 3. Querying a table

Use a `SELECT` statement:

```psql
mydb=> SELECT * FROM products;
   name   | items_in_stock | price 
----------+----------------+-------
 Apples   |            100 | 25.00
 Bananas  |             32 | 10.00
 Cherries |             74 |  2.50
(3 rows)
```

`*` is shorthand for "all columns". You can specify columns (recommended):

```psql
mydb=> SELECT name, price FROM products;
   name   | price 
----------+-------
 Apples   | 25.00
 Bananas  | 10.00
 Cherries |  2.50
(3 rows)
```

You can include *expressions*:

```psql
mydb=> SELECT name, items_in_stock * price AS inventory_value FROM products;
   name   | inventory_value 
----------+-----------------
 Apples   |         2500.00
 Bananas  |          320.00
 Cherries |          185.00
(3 rows)
```

You can use a `WHERE` clause to filter results:

```psql
mydb=> SELECT * FROM products WHERE items_in_stock < 50;
  name   | items_in_stock | price 
---------+----------------+-------
 Bananas |             32 | 10.00
(1 row)
```

You can use an `ORDER BY` clause to sort results:

```psql
mydb=> SELECT * FROM products ORDER BY price;
   name   | items_in_stock | price 
----------+----------------+-------
 Cherries |             74 |  2.50
 Bananas  |             32 | 10.00
 Apples   |            100 | 25.00
```

## 4. Joining tables

A *join query* accesses multiple tables (or multiple instances of the same table) at once:

We'll need another table to experiment with joins:

```psql
mydb=> CREATE TABLE suppliers (
mydb(>   name                 varchar(70),
mydb(>   product_name         varchar(50),
mydb(>   unit_price           numeric(7, 2),
mydb(>   last_delivery_date   date
mydb(> );
CREATE TABLE
mydb=> INSERT INTO suppliers VALUES
mydb->   ('ACME Fruits Ltd', 'Bananas', 8.5, '2023-07-23'),
mydb->   ('Green Thumb Corp.', 'Spinach', 5.95, '2023-07-24'),
mydb->   ('Jolly Grocers', 'Apples', 23.80, '2023-07-24');
INSERT 0 3
```

```psql
mydb=> SELECT * FROM suppliers;
       name        | product_name | unit_price | last_delivery_date 
-------------------+--------------+------------+--------------------
 ACME Fruits Ltd   | Bananas      |       8.50 | 2023-07-23
 Green Thumb Corp. | Spinach      |       5.95 | 2023-07-24
 Jolly Grocers     | Apples       |      23.80 | 2023-07-24
(3 rows)
```

It is good practice to *qualify* column names (e.g table.colname) and use *aliases* to avoid issues with duplicate column names:

```psql
mydb=> SELECT * FROM products JOIN suppliers ON name = product_name; -- this will fail
ERROR:  column reference "name" is ambiguous
LINE 1: SELECT * FROM products JOIN suppliers ON name = product_name...
```

```psql
mydb=> SELECT * FROM products p JOIN suppliers s ON p.name = s.product_name;  -- 2 "name" columns
  name   | items_in_stock | price |      name       | product_name | unit_price | last_delivery_date 
---------+----------------+-------+-----------------+--------------+------------+--------------------
 Apples  |            100 | 25.00 | Jolly Grocers   | Apples       |      23.80 | 2023-07-24
 Bananas |             32 | 10.00 | ACME Fruits Ltd | Bananas      |       8.50 | 2023-07-23
(2 rows)
```

```psql
mydb=> SELECT s.name AS supplier_name, p.name AS product_name, p.price,
mydb->        s.unit_price AS purchase_price, p.items_in_stock, s.last_delivery_date
mydb->   FROM products p JOIN suppliers s ON p.name = s.product_name;
  supplier_name  | product_name | price | purchase_price | items_in_stock | last_delivery_date 
-----------------+--------------+-------+----------------+----------------+--------------------
 Jolly Grocers   | Apples       | 25.00 |          23.80 |            100 | 2023-07-24
 ACME Fruits Ltd | Bananas      | 10.00 |           8.50 |             32 | 2023-07-23
(2 rows)
```

The default is an *inner join*, which returns only rows that match the join condition. To include all possible results from both tables, we can use a *full outer join*:

```psql
mydb=> SELECT s.name AS supplier_name, p.name AS product_name, p.price,
mydb->        s.unit_price AS purchase_price, p.items_in_stock, s.last_delivery_date
mydb->   FROM products p FULL OUTER JOIN suppliers s ON p.name = s.product_name
mydb->   ORDER BY supplier_name;
   supplier_name   | product_name | price | purchase_price | items_in_stock | last_delivery_date 
-------------------+--------------+-------+----------------+----------------+--------------------
 ACME Fruits Ltd   | Bananas      | 10.00 |           8.50 |             32 | 2023-07-23
 Green Thumb Corp. |              |       |           5.95 |                | 2023-07-24
 Jolly Grocers     | Apples       | 25.00 |          23.80 |            100 | 2023-07-24
                   | Cherries     |  2.50 |                |             74 | 
(4 rows)
```

More on joins later.

## 5. Aggregate functions

Aggregate functions compute a *single result from multiple input rows* e.g. `count`, `sum`, `avg`, `max` and `min`.

```psql
mydb=> SELECT sum(price * items_in_stock) FROM products AS total_inventory_value; 
   sum   
---------
 3005.00
(1 row)
```

```psql
mydb=> SELECT min(price), max(price), avg(price) FROM products;
 min  |  max  |         avg         
------+-------+---------------------
 2.50 | 25.00 | 12.5000000000000000
(1 row)
```

To include aggregate functions in `WHERE` clauses, you can use a *subquery*. `WHERE` clauses determine which rows to include, and so are processed before aggregate functions.

```psql
mydb=> SELECT name, price FROM products WHERE price = min(price);
ERROR:  aggregate functions are not allowed in WHERE
LINE 1: SELECT name, price FROM products WHERE price = min(price);
                                                       ^
```

```psql
mydb=> SELECT name, price FROM products WHERE price = (SELECT min(price) FROM products);
   name   | price 
----------+-------
 Cherries |  2.50
(1 row)
```

Aggregate functions are often used in `GROUP BY` clauses:

```psql
mydb=> INSERT INTO suppliers (name, product_name, unit_price, last_delivery_date) VALUES
mydb->   ('Planet Farms', 'Apples', 24.10, '2023-07-25'),
mydb->   ('City Merchants', 'Bananas', 9.00, '2023-07-25');
INSERT 0 2
mydb=> SELECT product_name, count(name) AS num_suppliers, min(unit_price) AS min_price,
mydb->        max(unit_price) AS max_price, avg(unit_price) AS avg_price
mydb->  FROM suppliers
mydb->  GROUP BY product_name;
 product_name | num_suppliers | min_price | max_price |      avg_price      
--------------+---------------+-----------+-----------+---------------------
 Apples       |             2 |     23.80 |     24.10 | 23.9500000000000000
 Bananas      |             2 |      8.50 |      9.00 |  8.7500000000000000
 Spinach      |             1 |      5.95 |      5.95 |  5.9500000000000000
(3 rows)
```

```psql
mydb=> SELECT s.product_name, avg(s.unit_price) AS avg_purchase_price, p.price AS sale_price
mydb->   FROM products p JOIN suppliers s ON p.name = s.product_name
mydb->   GROUP BY s.product_name, p.price
mydb->   ORDER BY sale_price DESC;
 product_name | avg_purchase_price  | sale_price 
--------------+---------------------+------------
 Apples       | 23.9500000000000000 |      25.00
 Bananas      |  8.7500000000000000 |      10.00
```

You can filter grouped rows with a `HAVING` clause.

```psql
mydb=> SELECT product_name, avg(unit_price) AS avg_purchase_price
mydb->   FROM suppliers
mydb->   GROUP BY product_name
mydb->   HAVING avg(unit_price) < 10;
 product_name | avg_purchase_price 
--------------+--------------------
 Bananas      | 8.7500000000000000
 Spinach      | 5.9500000000000000
(2 rows)
```

```{note}
The fundamental difference between `WHERE` and `HAVING` is that `WHERE` selects *input rows before grouping & aggregation*, whereas `HAVING` selects *group rows after groups and aggregates are computed*.

`HAVING` clauses usually contain aggregate functions, but this isn't a must. In such cases, `WHERE` clauses would be more efficient; we'd avoid doing grouping and aggregate calculations for all rows that fail the `WHERE` check.
```

## 6. Updates

You can update existing rows using the `UPDATE` command:

```psql
mydb=> UPDATE products SET price = 3 WHERE name = 'Cherries';
UPDATE 1
mydb=> SELECT * FROM products;
   name   | items_in_stock | price 
----------+----------------+-------
 Apples   |            100 | 25.00
 Bananas  |             32 | 10.00
 Cherries |             74 |  3.00
(3 rows)
```

## 7. Deletions

You can remove rows using the `DELETE` command:

```psql
mydb=> DELETE FROM products WHERE name = 'Bananas';
DELETE 1
mydb=> SELECT * FROM products;
   name   | items_in_stock | price 
----------+----------------+-------
 Apples   |            100 | 25.00
 Cherries |             74 |  3.00
(2 rows)
```

```{caution}
`DELETE FROM tablename;` will remove all rows. Be specific.
```

```{tip}
Start with a `SELECT` query to check the rows that would be selected. Then switch to a `DELETE` command.
```

You can use `DROP TABLE` to remove a table:

```psql
mydb=> DROP TABLE products;
DROP TABLE
mydb=> SELECT * FROM products;
ERROR:  relation "products" does not exist
LINE 1: SELECT * FROM products;
                      ^
```
