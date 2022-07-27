#!/bin/bash

/aesmd.sh

gramine-sgx-get-token --output mariadb.token --sig mariadb.sig
gramine-sgx mariadb
