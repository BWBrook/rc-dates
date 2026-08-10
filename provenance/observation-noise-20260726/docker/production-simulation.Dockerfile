FROM rocker/r-ver:4.5.3@sha256:c3f39b365d1077fe24f8e9ab2742e352b6d3950897f51af1624a5bb5550c21c0

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        cmake \
        g++ \
        gfortran \
        git \
        libcurl4-openssl-dev \
        libfontconfig1-dev \
        libfreetype6-dev \
        libfribidi-dev \
        libgdal-dev \
        libgeos-dev \
        libharfbuzz-dev \
        libicu-dev \
        libjpeg-dev \
        libpng-dev \
        libproj-dev \
        libssl-dev \
        libtiff-dev \
        libudunits2-dev \
        libxml2-dev \
        libx11-dev \
        libxt-dev \
        make \
    && rm -rf /var/lib/apt/lists/*

ENV RENV_CONFIG_PAK_ENABLED=FALSE \
    RENV_CONFIG_USE_CACHE=TRUE \
    RENV_PATHS_CACHE=/opt/renv/cache \
    RENV_PATHS_LIBRARY=/opt/rc-dates-library \
    R_LIBS_USER=/opt/rc-dates-library/linux-ubuntu-noble/R-4.5/x86_64-pc-linux-gnu \
    MAKEFLAGS=-j16

WORKDIR /opt/rc-dates
COPY renv.lock renv.lock
COPY renv/ renv/
COPY docker/install-production-packages.R docker/install-production-packages.R

RUN Rscript docker/install-production-packages.R

WORKDIR /workspace
