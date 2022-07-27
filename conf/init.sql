-- RocksDB is currently broken on restart
-- because <datadir>/#rocksdb/LOCK is empty
-- and gramine can not handle empty encrypted files
--INSTALL SONAME 'ha_rocksdb';

CREATE OR REPLACE USER root IDENTIFIED BY 'enclaive';
GRANT ALL ON *.* TO root WITH GRANT OPTION;
