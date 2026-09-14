# syntax=docker/dockerfile:1
FROM dhi.io/docker:29-cli-dev@sha256:3d0924938c1f8c73e4ab1d44f2b151c254365b95a71082e46dc3abb49a234cbd

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

COPY --from=dhi.io/trivy:0-compat@sha256:f83fae336fd804120279fef4f05d661f47ac1e86c06f477b169fd1d383bc455f \
    /usr/bin/trivy /usr/local/bin/trivy

COPY --from=dhi.io/cosign:3@sha256:f6ddafbcae5d3a4af6c73a58491a7f2af9b41a0dcabc5712cad0efde944260f6 \
    /usr/bin/cosign /usr/local/bin/cosign

COPY --from=dhi.io/trufflehog:3@sha256:d0bc1f26dbb988bf4b61e6ad48a64fcbbb87499273740df3132fde3b805db00e \
    /usr/bin/trufflehog /usr/local/bin/trufflehog

COPY --from=hadolint/hadolint:v2.15.1-debian@sha256:9a3944b7fddcb947d1ffd90829ac1a6e5c30479223358f249d8b96c7d0019e27 \
    /bin/hadolint /usr/local/bin/hadolint

RUN docker --version \
    && docker buildx version \
    && trivy --version \
    && cosign version \
    && trufflehog --version \
    && hadolint --version \
    && node --version
