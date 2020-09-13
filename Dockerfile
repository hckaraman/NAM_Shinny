# get shiny serves plus tidyverse packages image
FROM rocker/shiny-verse:latest

WORKDIR /srv/shiny-server/NAM/


# system libraries of general use
RUN apt-get update && apt-get install -y \
    sudo \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    libssl-dev \
    libssh2-1-dev \
    libgdal-dev \
    libproj-dev \
    libudunits2-0 \
    libudunits2-dev \
    python3-pip

  

# install R packages required 
# (change it dependeing on the packages you need)
RUN R -e 'install.packages(c("shiny","shinyFiles","RSQLite","stringr","ggplot2","zoo","DT","sf","rgdal","tidyverse","raster","reticulate","shinydashboard","plotly","vroom","hrbrthemes","openxlsx"), repos="http://cran.rstudio.com/")'

# copy the app to the image


COPY NAM_Shinny.Rproj .
COPY server.R .
COPY ui.R .
COPY Nam/ .
copy requirements.txt .


RUN pip3 install -r requirements.txt

# select port
EXPOSE 3838

# allow permission
RUN sudo chown -R shiny:shiny /srv/shiny-server
# COPY shiny-server.sh /usr/bin/shiny-server.sh

# run app
CMD ["R", "-e", "shiny::runApp('/srv/shiny-server/NAM', host = '0.0.0.0', port = 3838)"]

#CMD ["/usr/bin/shiny-server.sh"]
