# Getting Started

*PostgreSQL* uses a **client** / **server** model, with each session consisting of:

1. A server process/program called `postgres`, which:
   - manages the database files
   - accepts connections from client applications
   - performs database actions on behalf of clients.

   The server process *starts a fork for each new client connection*. It can handle multiple concurrent client connections.

2. A client (frontend) application, which could be:
   - a text-oriented tool
   - a graphical application (gui)
   - a web server that accesses the database to display web pages
   - a specialized database maintenance tool.

The client and the server *can be on different hosts*, communicating via a TCP/IP network connection. Just ensure that files you intend to use are accessible at both ends.

## The Command Line Interface

### 1. Creating a database

```bash
createdb mydb
```

If you don't provide a database name, the current username will be used.

### 2. Deleting a database

```bash
dropdb mydb
```

This permanently removes all files related to the database - it can't be undone. The database name must always be specified.

### 3. Accessing a database

You can access databases using:

- the *PostgreSQL* interactive terminal program, `psql`
- an existing graphical frontend tool e.g. `pgAdmin`
- a custom application, using one of the several available language bindings.

We'll focus on *psql*.

```bash
$ psql mydb
psql (14.1)
Type "help" for help.

mydb=>
```

You can now enter SQL queries and `psql` internal commands.

```psql
mydb=> SELECT version();
                                                 version                                                  
----------------------------------------------------------------------------------------------------------
 PostgreSQL 14.1 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 11.2.1 20210728 (Red Hat 11.2.1-1), 64-bit
(1 row)

mydb=> SELECT current_date;
 current_date 
--------------
 2021-12-03
(1 row)

mydb=> SELECT 1 + 2;
 ?column? 
----------
        3

mydb=> \?
```
