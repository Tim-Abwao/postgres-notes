# Introduction

*PostgreSQL* uses a *client/server* model. Each session consists of:

1. A server process called `postgres`, that:
   - manages database files
   - accepts connections from client applications
   - performs database actions on behalf of clients.

   The server process can handle multiple concurrent clients by *starting a fork for each new client connection*.

2. A client (frontend) application, which could be:
   - a text-oriented tool
   - a graphical application (gui)
   - a web server that accesses the database to display web pages
   - a specialized database maintenance tool.

The client and server *can be on different hosts*, communicating via a TCP/IP network connection. Just ensure that files you intend to use are accessible at both ends.

## The Command Line Interface

### 1. Creating a database

Use the [createdb][createdb] command:

```console
$ createdb mydb
```

Database names shoud start with an alphabetic character, and must be <= 63 bytes long. If you don't provide a database name, the current username will be used.

### 2. Deleting a database

Use the [dropdb][dropdb] command:

```console
$ dropdb mydb
```

Permanently removes all files related to the database. Can't be undone. Database name must always be specified.

[createdb]: https://www.postgresql.org/docs/current/app-createdb.html
[dropdb]: https://www.postgresql.org/docs/current/app-dropdb.html

### 3. Accessing a database

You can use:

- the *PostgreSQL* interactive terminal program, `psql`

  ```console
  $ psql mydb
  psql (15.3)
  Type "help" for help.

  mydb=> 
  ```

- a graphical frontend tool e.g. [pgAdmin](https://www.pgadmin.org/)
- a custom application, using available language bindings.

We'll focus on *psql*.
