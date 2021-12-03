# Introduction

PostgreSQL is a *relational database management system* - it manages data stored in relations/**tables**.

Each table is a named collection of **rows**. SQL does not guarantee the order of rows within a table, though you can sort values for display.

Each row has the same set of named **columns**, each of a *specific data type*. Columns have a *fixed order* in each row.

Several tables can be grouped in a **database**.

A collection of databases managed by a single  *PostgreSQL* server instance is called a **database cluster**.

## 1. Creating a table

```sql
CREATE TABLE weather (
    city            varchar(80),
    temp_lo         int,           -- low temperature
    temp_hi         int,           -- high temperature
    prcp            real,          -- precipitation
    date            date
);
```

```sql
CREATE TABLE cities (
    name            varchar(80),
    location        point
);
```

Spaces, tabs and newlines can be used freely in SQL commands.

`--` introduces single-line comments.

`varchar(80)` data type stores arbitrary strings up to 80 character long.

`int` data type stores integers.

`real` data type stores single precision floating-point numbers.

`date` data type stores dates.

`point` is a Postgres-specific data type.

More SQL standard data types, PostgeSQL-specific data types and user-defined data types will be discussed in future.
<!-- TODO: Add link to data types -->

## 2. Populating a table with rows

If you remember the order of the columns, you can add arranged values without specifying the columns:

```sql
INSERT INTO weather VALUES ('Nairobi', 13, 21, 0.1, '2021-05-26');
```

Alternatively, you can list any of the columns in any order, then supply their respective values *(recommended)*:

```sql
INSERT INTO weather (city, temp_lo, temp_hi, prcp, date)
    VALUES ('Mombasa', 23, 28, 0.0, '2021-05-26');
```

You can also use the `COPY` command to load large amounts of data from *flat-text files* into a table.

Contents of a sample file named `cities.txt`:

```txt
Nairobi (-1.28333, 36.81667)
Mombasa (-4.05466, 39.66359)
```

```sql
COPY cities FROM '/path/to/cities.txt'
```

> **NOTE:** This requires you to be a `superuser`, or have one of the roles `pg_read_server_files` / `pg_execute_server_program`, since it allows reading any file or running a program that the server has privileges to access.
>
> The psql `\copy` command is more user-friendly. It invokes `COPY FROM STDIN` or `COPY TO STDOUT`, and then fetches/stores the data in a file *accessible to the psql client*.

```sql
\copy cities FROM '/path/to/cities.txt'
```

## 3. Querying a table

```sql
mydb=> SELECT * FROM weather;
  city   | temp_lo | temp_hi | prcp |    date    
---------+---------+---------+------+------------
 Nairobi |      13 |      21 |  0.1 | 2021-05-26
 Mombasa |      23 |      28 |    0 | 2021-05-26
(2 rows)
```

`*` is shorthand for "all columns". You can specify columns *(recommended)*:

```sql
mydb=> SELECT date, city, prcp FROM weather;
    date    |  city   | prcp 
------------+---------+------
 2021-05-26 | Nairobi |  0.1
 2021-05-26 | Mombasa |    0
(2 rows)
```

You can use expressions:

```sql
mydb=> SELECT date, city, (temp_hi+temp_lo)/2 as avg_temp FROM weather;
    date    |  city   | avg_temp 
------------+---------+----------
 2021-05-26 | Nairobi |       17
 2021-05-26 | Mombasa |       25
(2 rows)

mydb=> SELECT * FROM weather ORDER BY city;
  city   | temp_lo | temp_hi | prcp |    date    
---------+---------+---------+------+------------
 Mombasa |      23 |      28 |    0 | 2021-05-26
 Nairobi |      13 |      21 |  0.1 | 2021-05-26
(2 rows)

mydb=> SELECT DISTINCT city FROM weather;
  city   
---------
 Mombasa
 Nairobi
(2 rows)
```

## 4. Joining tables

A *join query* accesses multiple rows of the same or different tables at once:

```sql
mydb=> SELECT city, temp_lo, temp_hi, prcp, date, location
mydb->   FROM weather, cities
mydb->   WHERE city = name;
  city   | temp_lo | temp_hi | prcp |    date    |      location       
---------+---------+---------+------+------------+---------------------
 Nairobi |      13 |      21 |  0.1 | 2021-05-26 | (-1.28333,36.81667)
 Mombasa |      23 |      28 |    0 | 2021-05-26 | (-4.05466,39.66359)
(2 rows)
```

You can also use *qualified column names* (recommended) and *aliases*:

```sql
mydb=> SELECT w.city, w.temp_lo, w.temp_hi, w.prcp, w.date, c.location
mydb->   FROM weather w, cities c
mydb->   WHERE c.name = w.city;
  city   | temp_lo | temp_hi | prcp |    date    |      location       
---------+---------+---------+------+------------+---------------------
 Nairobi |      13 |      21 |  0.1 | 2021-05-26 | (-1.28333,36.81667)
 Mombasa |      23 |      28 |    0 | 2021-05-26 | (-4.05466,39.66359)
(2 rows)
```

More on joins later.
<!-- TODO: Add link to join types -->

## 5. Aggregate functions

Aggregate function compute a *single result from multiple input rows*. Examples include `count`, `sum`, `avg`, `max` and `min`.

```sql
mydb=> INSERT INTO weather (city, temp_lo, temp_hi, prcp, date) VALUES
  ('Mombasa', 24, 27, 0.05, '2021-05-27'),
  ('Nairobi', 11, 21, 0.2, '2021-05-27');
INSERT 0 2

mydb=> SELECT * FROM weather;
  city   | temp_lo | temp_hi | prcp |    date    
---------+---------+---------+------+------------
 Nairobi |      13 |      21 |  0.1 | 2021-05-26
 Mombasa |      23 |      28 |    0 | 2021-05-26
 Mombasa |      24 |      27 | 0.05 | 2021-05-27
 Nairobi |      11 |      21 |  0.2 | 2021-05-27
(4 rows)

mydb=> SELECT min(temp_lo), max(temp_hi) FROM weather;
 min | max 
-----+-----
  11 |  28
(1 row)
```

> **NOTE:** To include aggregate functions in `WHERE` clauses, you'll need to use a *subquery*. `WHERE` clauses determine which rows to include, and so are processed before aggregate functions.

```sql
mydb=> SELECT city
mydb->   FROM weather
mydb->   WHERE temp_hi = (SELECT max(temp_hi) FROM weather);
  city   
---------
 Mombasa
```

Aggregate functions are very useful in `GROUP BY` clauses:

```sql
mydb=> SELECT city, min(temp_lo)
mydb->   FROM weather
mydb->   GROUP BY city;
  city   | min 
---------+-----
 Mombasa |  23
 Nairobi |  11
(2 rows)
```

You can filter grouped rows using `HAVING`.

```sql
mydb=> SELECT city, min(temp_lo)
mydb->   FROM weather
mydb->   GROUP BY city
mydb->   HAVING min(temp_lo) > 15;
  city   | min 
---------+-----
 Mombasa |  23
(1 row)
```

> **NOTE:** The fundamental difference between `WHERE` and `HAVING` is that `WHERE` selects *input rows before grouping & aggregation*, whereas `HAVING` selects *group rows after groups and aggregates are computed*.

## 6. Updates

You can update existing rows using the `UPDATE` command:

```sql
mydb=> UPDATE weather
mydb->   SET temp_lo = temp_lo + 2, temp_hi = temp_hi + 3
mydb->   WHERE city = 'Mombasa';
UPDATE 2

mydb=> SELECT * FROM weather;
  city   | temp_lo | temp_hi | prcp |    date    
---------+---------+---------+------+------------
 Nairobi |      13 |      21 |  0.1 | 2021-05-26
 Nairobi |      11 |      21 |  0.2 | 2021-05-27
 Mombasa |      25 |      31 |    0 | 2021-05-26
 Mombasa |      26 |      30 | 0.05 | 2021-05-27
(4 rows)
```

## 7. Deletions

You can remove rows using the `DELETE` command:

```sql
mydb=> DELETE FROM weather WHERE temp_hi > 30;
DELETE 1

mydb=> SELECT * FROM weather;
  city   | temp_lo | temp_hi | prcp |    date    
---------+---------+---------+------+------------
 Nairobi |      13 |      21 |  0.1 | 2021-05-26
 Nairobi |      11 |      21 |  0.2 | 2021-05-27
 Mombasa |      26 |      30 | 0.05 | 2021-05-27
(3 rows)
```

> **WARNING:** Using `DELETE FROM tablename;` without a *qualification* will remove all rows. Exercise caution.
