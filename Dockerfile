ARG PGVERSION=16
ARG VERSION=16-bullseye

FROM registry.cn-hangzhou.aliyuncs.com/ymmirror/postgres:$VERSION as build

ARG PGVERSION
ARG VERSION

USER root

COPY extension/pgvector-0.7.4.tar.gz /tmp/
COPY extension/pg_partman-5.1.0.tar.gz /tmp/
COPY extension/pg_embedding-0.3.6.tar.gz /tmp/
COPY extension/postgresql_anonymizer-1.3.2.tar.gz /tmp/
# COPY extension/pgroonga-3.2.2.tar.gz /tmp/

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
	curl \
    gnupg ;

RUN curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN echo "deb http://apt.postgresql.org/pub/repos/apt bullseye-pgdg main ${PGVERSION}" > /etc/apt/sources.list.d/pgdg.list

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
	curl \
	gnupg \
    make \
    gcc \
    git \
    g++ \
    cmake \
    ninja-build \
    libssl-dev \
    clang \
    pkg-config \
    libopenblas-dev \
	libcurl4-gnutls-dev \
    libmsgpack-dev \
    libgroonga-dev \
    libzstd-dev \
    liblz4-dev \
	postgresql-common \
    postgresql-server-dev-${PGVERSION} \
    libpq-dev

# pgvector
RUN cd /tmp/; \
    tar -zxvf pgvector-0.7.4.tar.gz; \
    cd pgvector-0.7.4 ; \
    make OPTFLAGS="" ; \
    make install ; 

# pgembedding can't coexist with pgvector
# RUN cd /tmp/; \
#     tar -zxvf pg_embedding-0.3.6.tar.gz; \
#     cd pg_embedding-0.3.6 ; \
#     make ; \
#     make install ; \
#     ls -ahl;

# pg_partman
RUN cd /tmp/; \
    tar -zxvf pg_partman-5.1.0.tar.gz; \
    cd pg_partman-5.1.0 ; \
    make OPTFLAGS="" ; \
    make NO_BGW=1 install ; 

# Anonymizer
# https://postgresql-anonymizer.readthedocs.io/en/stable/INSTALL/#install-from-source
RUN cd /tmp/; \
    tar -zxvf postgresql_anonymizer-1.3.2.tar.gz; \
    cd postgresql_anonymizer-1.3.2 ; \
    make extension ; \
    make install ;

# RUN cd /tmp/; \
#     git clone --recurse-submodules https://github.com/duckdb/pg_duckdb; \
#     cd pg_duckdb; \
#     make install;


RUN rm -rf /var/lib/apt/lists/*


FROM registry.cn-hangzhou.aliyuncs.com/ymmirror/postgres:$VERSION

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
	curl

RUN curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN echo "deb http://apt.postgresql.org/pub/repos/apt bullseye-pgdg main ${PGVERSION}" > /etc/apt/sources.list.d/pgdg.list    

ARG PGVERSION

#
RUN apt-get install -y postgresql-${PGVERSION}-wal2json postgresql-${PGVERSION}-decoderbufs postgresql-${PGVERSION}-cron postgresql-${PGVERSION}-postgis-3 postgresql-${PGVERSION}-pgrouting

# RUN apt-get install -y postgresql-${PGVERSION}-decoderbufs
# RUN apt-get install -y postgresql-${PGVERSION}-cron
# RUN apt-get install -y postgresql-${PGVERSION}-postgis-3
# https://pgroonga.github.io/install/debian.html
# RUN apt-get install -y postgresql-${PGVERSION}-pgroonga

# copy pgvector
COPY --from=build /usr/lib/postgresql/${PGVERSION}/lib/vector*.so /usr/lib/postgresql/${PGVERSION}/lib
COPY --from=build /usr/share/postgresql/${PGVERSION}/extension/vector* /usr/share/postgresql/${PGVERSION}/extension/


# copy pg_embedding
# COPY --from=build /opt/bitnami/postgresql/lib/ /opt/bitnami/postgresql/lib/
# COPY --from=build /opt/bitnami/postgresql/share/ /opt/bitnami/postgresql/share/

# copy pg_partman
COPY --from=build /usr/lib/postgresql/${PGVERSION}/lib/pg_partman*.so /usr/lib/postgresql/${PGVERSION}/lib
COPY --from=build /usr/share/postgresql/${PGVERSION}/extension/pg_partman* /usr/share/postgresql/${PGVERSION}/extension/


# anno
COPY --from=build /usr/lib/postgresql/${PGVERSION}/lib/anon*.so /usr/lib/postgresql/${PGVERSION}/lib
COPY --from=build /usr/share/postgresql/${PGVERSION}/extension/anon* /usr/share/postgresql/${PGVERSION}/extension/

# pgroonga
#COPY --from=build /usr/lib/postgresql/${PGVERSION}/lib/pgroonga*.so /usr/lib/postgresql/${PGVERSION}/lib
#COPY --from=build /usr/share/postgresql/${PGVERSION}/extension/pgroonga* /usr/share/postgresql/${PGVERSION}/extension/

# pg_cron,pgaudit,pgoutput,anon,decoderbufs,wal2json
RUN echo "shared_preload_libraries='pg_cron,pgoutput,anon,decoderbufs,wal2json'" >> /usr/share/postgresql/postgresql.conf.sample

RUN rm -rf /var/lib/apt/lists/*