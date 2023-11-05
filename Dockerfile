FROM rocker/r-ver:4.3.1

RUN apt-get update && apt-get install -y \
    libglpk-dev \
    libxml2-dev \
    libcairo2-dev \
    libgit2-dev \
    default-libmysqlclient-dev \
    libpq-dev \
    libsasl2-dev \
    libsqlite3-dev \
    libssh2-1-dev \
    libxtst6 \
    libcurl4-openssl-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    libxt-dev \
    unixodbc-dev \
    wget \
    pandoc \
    make \
    default-jdk

RUN R -e "install.packages('remotes')"

RUN R -e "remotes::install_github('rstudio/renv@v1.0.2')"

RUN mkdir /home/sjx

RUN mkdir /home/sjx/pipeline_output

RUN mkdir /home/sjx/shared_folder

COPY renv.lock /home/sjx/renv.lock

COPY sa_method_comparison.Rmd /home/sjx/sa_method_comparison.Rmd

COPY _targets.R /home/sjx/_targets.R

RUN R -e "setwd('/home/sjx');renv::init();renv::restore()"

RUN cd /home/sjx && R -e "targets::tar_make()"

CMD mv /home/sjx/pipeline_output/* /home/sjx/shared_folder/