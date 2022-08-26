# Running

```bash
php generate_data.php > data.sql
docker-compose up -d
```

# Demonstrating

Use two shells in demo:

```bash
docker-compose exec demo bash
docker-compose exec demo bash
```

The file containing the date should be located at `/sgx/demo/users.ibd`. Same goes for `/vanilla/demo/users.ibd`.

We now import our data and shutdown the server to flush the data from the InnoDB binlog to the storage file:

```bash
mariadb --host sgx     --password=enclaive < data.sql
mariadb --host vanilla --password=enclaive < data.sql
```

And simply do a `grep`:

```bash
grep -Ri testUsername /vanilla/ /sgx/
```

followed by printing the data:

```bash
xxd -c 32 /sgx/demo/users.ibd     | grep -i testUsername
xxd -c 32 /vanilla/demo/users.ibd | grep -i testUsername
```

We could also use `strings` on that file:

```bash
strings /sgx/demo/users.ibd
strings /vanilla/demo/users.ibd
```
