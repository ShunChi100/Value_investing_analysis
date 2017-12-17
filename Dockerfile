# Docker file for value_investing project
# Shun CHI, Dec, 2017

# use rocker/tidyverse as the base image and
FROM rocker/tidyverse:latest

# Make ~/.R 
RUN mkdir -p $HOME/.R

# $HOME doesn't exist in the COPY shell, so be explicit 
# COPY /home/shun/R/x86_64-pc-linux-gnu-library/3.4/RcppEigen/skeleton/Makevars /root/.R/Makevars

RUN apt-get update -qq \
    && apt-get -y --no-install-recommends install \
    liblzma-dev \
    libbz2-dev \
    clang  \
    ccache \
    default-jdk \
    default-jre \
    && R CMD javareconf \
    && install2.r --error \
        XLConnect \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
&& rm -rf /var/lib/apt/lists/*
        

# install the ezknitr packages
RUN Rscript -e "install.packages('ezknitr', repos = 'http://cran.us.r-project.org')"

# install XLConnect
# RUN Rscript -e "install.packages('XLConnect', repos = 'http://cran.us.r-project.org')"

# install packrat
# RUN R -e 'install.packages("packrat" , repos="http://cran.us.r-project.org")'

# install python 3
RUN apt-get update \
  && apt-get install -y python3-pip python3-dev \
  && cd /usr/local/bin \
  && ln -s /usr/bin/python3 python \
  && pip3 install --upgrade pip

# get python package dependencies
RUN apt-get install -y python3-tk

# install numpy & matplotlib
RUN pip3 install pandas
RUN pip3 install requests
RUN pip3 install argparse
RUN apt-get update && \
    pip3 install matplotlib && \
    rm -rf /var/lib/apt/lists/*
