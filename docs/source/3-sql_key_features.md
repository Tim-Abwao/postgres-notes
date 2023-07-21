# SQL Key Features

## 1. Views

Creating a view over a query *gives it a name that you can refer to* like an ordinary table:

```sql
mydb=> CREATE VIEW avg_temp AS
mydb->   SELECT city, avg((temp_hi + temp_lo) / 2)  AS avg_temp
mydb->     FROM weather
mydb->     GROUP BY city;
CREATE VIEW
mydb=> SELECT * FROM avg_temp;
  city   |      avg_temp       
---------+---------------------
 Mombasa | 25.5000000000000000
 Nairobi | 16.5000000000000000
(2 rows)
```

Making liberal use of views is a key aspect of *good SQL database design*. You can build views upon other views.

## 2. Foreign keys

Foreign keys maintain *referential integrity*, ensuring that you can't insert values in one table that do not have a matching reference in another.

```sql
CREATE TABLE cities_2 (
    city     varchar(80) primary key,
    location point
);

CREATE TABLE weather_2 (
    city      varchar(80) references cities_2(city),
    temp_lo   int,
    temp_hi   int,
    prcp      real,
    date      date
);

-- Populate the new tables
INSERT INTO cities_2 SELECT * FROM cities;
INSERT INTO weather_2 SELECT * FROM weather;
```

```sql
mydb=> INSERT INTO weather_2 (city, temp_hi, date)
mydb->   VALUES ('Kampala', 25, '2021-05-27');
ERROR:  insert or update on table "weather_2" violates foreign key constraint "weather_2_city_fkey"
DETAIL:  Key (city)=(Kampala) is not present in table "cities_2".
```

## 3. Transactions

Transactions *bundle multiple steps into a single, all-or-nothing operation*.

The steps in a transaction are invisible to other concurrent transactions, and if any one of them fails, none of them affects the database. This is referred to as **atomicity**.

A transactional database guarantees that all the updates made by a transaction are *logged in permanent storage* (i.e. on disk) before the transaction is reported complete.

```sql
BEGIN;  -- start transaction
/*
series of SQL statements (transaction block)
*/
COMMIT;  -- end transaction
```

You can use the `ROLLBACK` command in case you wish to cancel the transaction.

```sql
BEGIN;  -- start transaction
/*
series of SQL statements (transaction block)
*/
ROLLBACK;  -- cancel transaction
```

You can use the `SAVEPOINT` command to define *savepoints*. Afterwards, you can use `ROLLBACK TO` to roll back to your savepoints. This saves you the trouble of starting all over.

```sql
BEGIN;
/*
series of SQL statements
*/
SAVEPOINT my_savepoint;
/*
series of SQL statements with unintended consequences
*/
ROLLBACK TO my_savepoint;
/*
series of SQL statements yielding desired result
*/
COMMIT;
```

## 4. Window functions

A window function *performs a calculation across a set of table rows that are somehow related to the current row*.

Whereas aggregate functions group rows into single output rows, the rows in window fuctions retain their separate identities.

```sql
CREATE TABLE empsalary (
    depname     varchar(15),
    empno       int,
    salary      int
);

INSERT INTO empsalary (depname, empno, salary)
VALUES
  ('develop', 11, 5200),
  ('develop', 7, 4200),
  ('develop', 9, 4500),
  ('develop', 8, 6000),
  ('develop', 10, 5200),
  ('personnel' , 5, 3500),
  ('personnel' , 2, 3900),
  ('sales' , 3, 4800),
  ('sales' , 1, 5000),
  ('sales' , 4, 4800);
```

```sql
mydb=> SELECT depname, empno, salary,
mydb->        avg(salary) OVER (PARTITION BY depname) AS dep_avg_salary
mydb->   FROM empsalary;
  depname  | empno | salary |    dep_avg_salary     
-----------+-------+--------+-----------------------
 develop   |    11 |   5200 | 5020.0000000000000000
 develop   |     7 |   4200 | 5020.0000000000000000
 develop   |     9 |   4500 | 5020.0000000000000000
 develop   |     8 |   6000 | 5020.0000000000000000
 develop   |    10 |   5200 | 5020.0000000000000000
 personnel |     5 |   3500 | 3700.0000000000000000
 personnel |     2 |   3900 | 3700.0000000000000000
 sales     |     3 |   4800 | 4866.6666666666666667
 sales     |     1 |   5000 | 4866.6666666666666667
 sales     |     4 |   4800 | 4866.6666666666666667

```

A window function call always contains an `OVER` clause directly following the window function's name and argument(s). The `OVER` clause determines exactly how the rows of the query are *split up for processing by the window function*.

The `OVER` clause in the example above causes the `avg` aggregate function to be treated as a window function, computing the average accross rows that have the same *depname*.

The `PARTITION BY` clause within `OVER` divides the rows into groups.

You can control the order in which rows are processed by window functions using `ORDER BY` within `OVER`:

```sql
mydb=> SELECT depname, empno, salary,
mydb->        rank() OVER (PARTITION BY depname ORDER BY salary DESC)
mydb->   FROM empsalary;
  depname  | empno | salary | rank 
-----------+-------+--------+------
 develop   |     8 |   6000 |    1
 develop   |    10 |   5200 |    2
 develop   |    11 |   5200 |    2
 develop   |     9 |   4500 |    4
 develop   |     7 |   4200 |    5
 personnel |     2 |   3900 |    1
 personnel |     5 |   3500 |    2
 sales     |     1 |   5000 |    1
 sales     |     3 |   4800 |    2
 sales     |     4 |   4800 |    2
(10 rows)
```

For each row, there's a set of rows within its partition called its *window frame*.

When `PARTITION BY` and particularly `ORDER BY` are omitted, the default frame consists of all rows in the one partition:

```sql
mydb=> SELECT salary, sum(salary) OVER () FROM empsalary;
 salary |  sum  
--------+-------
   5200 | 47100
   4200 | 47100
   4500 | 47100
   6000 | 47100
   5200 | 47100
   3500 | 47100
   3900 | 47100
   4800 | 47100
   5000 | 47100
   4800 | 47100
(10 rows)
```

By default, if `ORDER BY` is supplied, then the frame consists of all rows *from the start* of the partition up through the current row, *plus any following rows* that are *equal to the current row* according to the ORDER BY clause.

In the example below, the sum is taken from the first (lowest) salary up through the current one, including any duplicates of the current one:

```sql
mydb=> SELECT salary, sum(salary) OVER (ORDER BY salary) FROM empsalary;
 salary |  sum  
--------+-------
   3500 |  3500
   3900 |  7400
   4200 | 11600
   4500 | 16100
   4800 | 25700
   4800 | 25700
   5000 | 30700
   5200 | 41100
   5200 | 41100
   6000 | 47100
(10 rows)
```

> **NOTE:** Window functions are *permitted only in the SELECT list and the ORDER BY clause* of the query. They are forbidden elsewhere, such as in GROUP BY, HAVING and WHERE clauses. This is because they logically execute after the processing of those clauses.
>
> Furthermore, window functions execute after non-window aggregate functions. This means it is valid to include an aggregate function call in the arguments of a window function, but not vice versa.

You can use a *sub-select* to filter or group rows after window calculations:

```sql
mydb=> SELECT depname, empno, salary
mydb->   FROM (
mydb->     SELECT depname, empno, salary,
mydb->            rank() OVER (PARTITION BY depname ORDER BY salary DESC, empno) AS pos
mydb->       FROM empsalary
mydb->   ) AS sub_select
mydb->   WHERE pos < 3;
  depname  | empno | salary 
-----------+-------+--------
 develop   |     8 |   6000
 develop   |    10 |   5200
 personnel |     2 |   3900
 personnel |     5 |   3500
 sales     |     1 |   5000
 sales     |     3 |   4800
(6 rows)
```

Shows rows from the inner query having rank less than 3 (the top 2).

When a query involves *multiple window functions*, each windowing behavior can be named in a `WINDOW` clause and then referenced in `OVER`:

```sql
mydb=> SELECT sum(salary) OVER w, avg(salary) OVER w
mydb->   FROM empsalary
mydb->   WINDOW w AS (PARTITION BY depname ORDER BY salary DESC);
  sum  |          avg          
-------+-----------------------
  6000 | 6000.0000000000000000
 16400 | 5466.6666666666666667
 16400 | 5466.6666666666666667
 20900 | 5225.0000000000000000
 25100 | 5020.0000000000000000
  3900 | 3900.0000000000000000
  7400 | 3700.0000000000000000
  5000 | 5000.0000000000000000
 14600 | 4866.6666666666666667
 14600 | 4866.6666666666666667
(10 rows)
```

## 5. Inheritance

Inheritance allows a table to derive columns from zero or more parent tables.

Schema modifications to the parent(s) normally propagate to children as well, and by default the data of the child table is included in scans of the parent(s).

```sql
CREATE TABLE cities (
    name       text,
    population real,
    elevation  int
);

CREATE TABLE capitals (
    state      char(2) UNIQUE NOT NULL
    ) INHERITS (cities);
```

A row of *capitals inherits* all columns (name, population, and elevation) from its parent, *cities*.

```sql
mydb=> SELECT * FROM capitals;
 name | population | elevation | state 
------+------------+-----------+-------
(0 rows)
```

`ONLY` can be used to indicate that a query should be run over only the specified table, and not tables below it in the inheritance hierarchy. e.g. `SELECT name, elevation FROM ONLY cities;`

More on inheritance later.
