FROM ubuntu:jammy

RUN apt-get update \
    && apt-get install -y --no-install-recommends mariadb-server mariadb-client

RUN apt-get install -y --no-install-recommends fswatch xxd binutils

COPY --from=enclaive/mariadb-sgx:latest /etc/my.cnf /etc/my.cnf
COPY --from=enclaive/mariadb-sgx:latest /app/init.sql /app/init.sql

ENTRYPOINT [ "/usr/sbin/mariadbd", "--bind-address=0.0.0.0", "--init-file=/app/init.sql" ]
