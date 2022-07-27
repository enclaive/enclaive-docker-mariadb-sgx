# enclaive-docker-mariadb-sgx

## Running

```bash
docker-compose build
docker-compose up
```

## Connecting

Initial SQL commands are defined in `conf/init.sql`.

Login with the default `root` user and password `enclaive`.

## Notes

The manifest uses a hardcoded encryption key for the data directory.

The RocksDB storage engine is currently broken on restart.
