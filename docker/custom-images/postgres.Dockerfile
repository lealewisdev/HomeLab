FROM ghcr.io/immich-app/postgres:18-vectorchord1.1.1@sha256:6e384bf4aa03866473395961786f40006555e4cd008b98f92bf4a44e5ab7b012
USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        postgresql-18-postgis-3=3.6.4+dfsg-2.pgdg12+1 && \
    rm -rf /var/lib/apt/lists/*
COPY initdb/ /docker-entrypoint-initdb.d/
USER postgres
