FROM rocker/shiny@sha256:627a2b7b3b6b1f6e33d37bdba835bbbd854acf70d74010645af71fc3ff6c32b6

WORKDIR /srv/shiny-server

RUN sed -i 's%deb.debian.org%mirror.bytemark.co.uk%' /etc/apt/sources.list

# Cleanup shiny-server dir
RUN rm -rf ./*

# Make sure the directory for individual app logs exists
RUN mkdir -p /var/log/shiny-server

# Install dependency on xml2
RUN apt-get update
RUN apt-get install libxml2-dev --yes
RUN apt-get install libssl-dev --yes
RUN apt-get install libpng-dev --yes 
RUN apt-get install libglu1-mesa-dev --yes

# Add Packrat files individually so that next install command
# can be cached as an image layer separate from application code
ADD packrat packrat

# Install packrat itself then packages from packrat.lock
RUN R -e "install.packages('packrat'); packrat::restore()"

# Add shiny app code
ADD . .

# Shiny runs as 'shiny' user, adjust app directory permissions
RUN chown -R shiny:shiny .

# APT Cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/

# Run shiny-server on port 80
RUN sed -i 's/3838/80/g' /etc/shiny-server/shiny-server.conf
EXPOSE 80

# Run update commands
source('./update_commands.R')
