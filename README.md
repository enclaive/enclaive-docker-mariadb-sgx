# MariaDB-SGX Demonstration

The goal is to show the mariadb-sgx database remains encrypted while in use (recall, encryption at rest decrypts the data collection in memory to perform the database operation). To this end, `insert.sql` creates a `username:password` table. The rationality is that the data is encrypted at any moment in time, while vanilla mariadb reveals the data. Note, there is no need for data-in-rest encryption and the burden of key updates/management. Encryption is handled on the fly by 

## Prerequisites

Install PHP (version 8.0+)
```
sudo add-apt-repository ppa:ondrej/php
suod apt update
sudo apt install php8.1 php8.1-mbstring
```
and generate SQL queries `insert.sql` to insert `user:pass` into a demo database
```bash
php generate_data.php > insert.sql
```

## Building and Running
```bash
docker compose up -d    # builds demo, mariadb and mariadb-sgx container
```
## Stopping and Restarting
In which case prune the volume
```
docker compose down
docker container prune -f && docker volume prune -f
```
## Setup

Use two shells in demo:

```bash
docker exec -it demo bash     # shell 1
docker exec -it demo bash     # shell 2
```

## Import and flush (mariadb)

Insert data and shutdown the server to flush the data from the InnoDB binlog to the storage file

```bash
# shell 1
mariadb --host mariadb --password=enclaive < insert.sql
```
and print the flushed file content

```bash
# shell 2
xxd -c 32 /sgx/demo/users.ibd | grep -i testUsername
```

## Import and flush (mariadb-sgx)

Insert data and shutdown the server to flush the data from the InnoDB binlog to the storage file

```bash
# shell 1
mariadb --host mariadb-sgx --password=enclaive < insert.sql
```
and print the flushed file content

```bash
# shell 2
xxd -c 32 /sgx/demo/users.ibd | grep -i testUsername
```

## Remarks

We could use `strings` on the output

```bash
strings /sgx/demo/users.ibd
strings /vanilla/demo/users.ibd
```

Alternatively compare a `grep'

```bash
grep -Ri testUsername /vanilla/ /sgx/
```
