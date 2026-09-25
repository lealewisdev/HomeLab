# syntax=docker/dockerfile:1
FROM dhi.io/docker:29-cli-dev@sha256:d5570a4bab6149d3dfcb34705458ff908dd56159db24ac7804c9403b819c381c

# renovate: datasource=deb depName=bash versioning=deb registryUrl=https://dhi.io/deb/debian?suite=trixie&components=main&binaryArch=amd64
ARG BASH_PKG_VERSION=5.2.37-2+dhi1
# renovate: datasource=deb depName=ca-certificates versioning=deb registryUrl=https://dhi.io/deb/debian?suite=trixie&components=main&binaryArch=amd64
ARG CA_CERTIFICATES_VERSION=20250419+dhi2
# renovate: datasource=deb depName=curl versioning=deb registryUrl=https://dhi.io/deb/debian?suite=trixie&components=main&binaryArch=amd64
ARG CURL_VERSION=8.14.1-2+deb13u5+dhi0
# renovate: datasource=deb depName=libcurl4t64 versioning=deb registryUrl=https://dhi.io/deb/debian?suite=trixie&components=main&binaryArch=amd64
ARG LIBCURL4T64_VERSION=8.14.1-2+deb13u5+dhi0
# renovate: datasource=deb depName=git versioning=deb registryUrl=https://dhi.io/deb/debian?suite=trixie&components=main&binaryArch=amd64
ARG GIT_VERSION=1:2.47.3-0+deb13u1+dhi2
# renovate: datasource=deb depName=nodejs versioning=deb registryUrl=https://deb.debian.org/debian?suite=trixie&components=main&binaryArch=amd64
ARG NODEJS_VERSION=20.19.2+dfsg-1+deb13u2
# renovate: datasource=deb depName=jq versioning=deb registryUrl=https://dhi.io/deb/debian?suite=trixie&components=main&binaryArch=amd64
ARG JQ_VERSION=1.8.2-1+dhi1
# renovate: datasource=deb depName=unzip versioning=deb registryUrl=https://dhi.io/deb/debian?suite=trixie&components=main&binaryArch=amd64
ARG UNZIP_VERSION=6.0-29+deb13u1+dhi0
# renovate: datasource=deb depName=zstd versioning=deb registryUrl=https://dhi.io/deb/debian?suite=trixie&components=main&binaryArch=amd64
ARG ZSTD_VERSION=1.5.7+dfsg-1+dhi2
# renovate: datasource=deb depName=gzip versioning=deb registryUrl=https://dhi.io/deb/debian?suite=trixie&components=main&binaryArch=amd64
ARG GZIP_VERSION=1.13-1+dhi1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
        bash="${BASH_PKG_VERSION}" \
        ca-certificates="${CA_CERTIFICATES_VERSION}" \
        curl="${CURL_VERSION}" \
        libcurl4t64="${LIBCURL4T64_VERSION}" \
        git="${GIT_VERSION}" \
        nodejs="${NODEJS_VERSION}" \
        jq="${JQ_VERSION}" \
        unzip="${UNZIP_VERSION}" \
        zstd="${ZSTD_VERSION}" \
        gzip="${GZIP_VERSION}" \
    && rm -rf /var/lib/apt/lists/* \
    && rm -f /usr/local/libexec/docker/cli-plugins/docker-scout \
    && rm -f /usr/local/libexec/docker/cli-plugins/docker-compose

COPY --from=dhi.io/trivy:0-compat@sha256:79df1739288c1550178258939737439fda6132270b768d63a3ddeee291aeae47 \
    /usr/bin/trivy /usr/local/bin/trivy

COPY --from=dhi.io/cosign:3@sha256:081f0b0c107251081787f4e5e3e090cc975351f92994990119dbc990aa08442f \
    /usr/bin/cosign /usr/local/bin/cosign

COPY --from=dhi.io/trufflehog:3@sha256:a4be6b49a65b680590f442b0ff41693804c6f5bce6aea003b874b046cfafcc52 \
    /usr/bin/trufflehog /usr/local/bin/trufflehog

COPY --from=hadolint/hadolint:v2.15.1-debian@sha256:9a3944b7fddcb947d1ffd90829ac1a6e5c30479223358f249d8b96c7d0019e27 \
    /bin/hadolint /usr/local/bin/hadolint

COPY --from=dhi.io/uv:0@sha256:ff4c5dfc67f9783dc3217deaf66b88a10c2f7fb92f1ea6358feeaf84ac67bbaf \
    /usr/local/bin/uv /usr/local/bin/uvx /usr/local/bin/

RUN docker --version \
    && docker buildx version \
    && trivy --version \
    && cosign version \
    && trufflehog --version \
    && hadolint --version \
    && node --version \
    && uv --version
