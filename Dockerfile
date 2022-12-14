# mariadb with patches

FROM ubuntu:jammy AS mariadb

RUN apt-get update \
    && apt-get install -y --no-install-recommends git ca-certificates \
        cmake gcc g++ make bison patch \
        libc-dev libssl-dev libncurses-dev libcurl4-openssl-dev \
        zlib1g-dev liblz4-dev liblzma-dev liblzo2-dev \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --branch=10.6 --depth=1 https://github.com/MariaDB/server /server/

WORKDIR /build/

COPY ./mariadb.diff ./

RUN patch -p1 -d/server/ < ./mariadb.diff \
    && cmake /server/ -DCOMPILATION_COMMENT="Enclaive" -Wno-dev \
        -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DMYSQL_DATADIR=/var/lib/mysql -DPLUGIN_FEEDBACK=NO \
        -DINSTALL_UNIX_ADDRDIR=/run/mysqld/mysqld.sock -DINSTALL_PLUGINDIR=lib/mysql/plugin \
        -DDEFAULT_CHARSET=utf8mb4 -DDEFAULT_COLLATION=utf8mb4_unicode_ci \
        -DWITH_DBUG_TRACE=OFF -DWITH_EMBEDDED_SERVER=OFF -DWITH_READLINE=ON -DWITH_UNIT_TESTS=OFF \
        -DWITH_EXTRA_CHARSETS=complex -DWITH_PCRE=bundled -DWITH_ZLIB=system -DWITH_SSL=system \
    && make -j`nproc` mariadbd \
    && strip sql/mariadbd

RUN make -j`nproc` archive blackhole connect federatedx rocksdb \
    && strip storage/*/*.so

RUN make -j`nproc` my_print_defaults resolveip \
    && cp -r /server/scripts/* scripts/ \
    && useradd mysql \
    && ./scripts/mariadb-install-db --user=mysql --datadir=/var/lib/mysql \
        --skip-test-db --cross-bootstrap --no-defaults \
    && rm /var/lib/mysql/ib_logfile0 \
    && tar -cz --xform s:'^\./':: -f mysql.tar.gz -C /var/lib/mysql/ .

# middlemain with patched libtar

FROM ubuntu:jammy AS middlemain

RUN apt-get update \
    && apt-get install -y --no-install-recommends git ca-certificates \
        autoconf automake make libtool \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --branch=master --depth=1 https://github.com/tklauser/libtar.git /build/

WORKDIR /build/

COPY ./launcher/libtar.diff ./

RUN git checkout 6379b5d2ae777dad576aeae70566740670057821 \
    && git apply libtar.diff \
    && autoreconf --force --install \
    && ./configure --disable-shared \
    && make -j

COPY ./launcher/main.c ./

RUN gcc main.c -Wall -Wextra -Werror -Wpedantic -Wno-unused-parameter -O3 \
        -Llib/.libs -Ilib -Ilisthash -ltar -lz -o launcher

# final stage

FROM enclaive/gramine-os:jammy-7e9d6925

RUN apt-get update \
    && apt-get install -y --no-install-recommends liblzo2-2 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app/

RUN useradd mysql \
    && mkdir -p /run/mysqld/ /var/lib/mysql/ \
    && chown -R mysql:mysql /run/mysqld/ /var/lib/mysql/

COPY --from=mariadb /build/sql/mariadbd /build/mysql.tar.gz /app/
COPY --from=mariadb /build/storage/*/ha_*.so /usr/lib/mysql/plugin/

COPY --from=middlemain /build/launcher /app/

COPY ./mariadb.manifest.template ./entrypoint.sh ./conf/init.sql /app/
COPY ./conf/my.cnf /etc/

RUN gramine-argv-serializer "/app/mariadbd" "--init-file=/app/init.sql" > ./argv \
    && gramine-manifest -Darch_libdir=/lib/x86_64-linux-gnu mariadb.manifest.template mariadb.manifest \
    && gramine-sgx-sign --key "$SGX_SIGNER_KEY" --manifest mariadb.manifest --output mariadb.manifest.sgx

VOLUME /data/

EXPOSE 3306/tcp

ENTRYPOINT [ "/app/entrypoint.sh" ]
