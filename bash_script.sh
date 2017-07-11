sudo apt-get -y update
sudo chown -R ubuntu /etc/apt
sudo apt-key adv -keyserver keyserver.ubuntu.com -recv-keys E084DAB9
sudo add-apt-repository 'deb http://star-www.st-andrews.ac.uk/cran/bin/linux/ubuntu trusty/'
sudo apt-get -y update
sudo apt-get install -y --force-yes r-base-core
sudo su -\-c "R -e \"install.packages( c('Rcpp' ,'git2r' ,'base64enc' ,'tools' ,'digest' ,'packrat' ,'jsonlite' ,'memoise' ,'tibble' ,'gtable' ,'viridisLite' ,'DBI' ,'yaml' ,'parallel' ,'curl' ,'xml2' ,'withr' ,'httr' ,'htmlwidgets' ,'grid' ,'R6' ,'XML' ,'ramazon' ,'purrr' ,'tidyr' ,'magrittr' ,'scales' ,'htmltools' ,'assertthat' ,'aws.signature' ,'mime' ,'xtable' ,'colorspace' ,'httpuv' ,'lazyeval' ,'munsell' ,'stats' ,'graphics' ,'grDevices' ,'utils' ,'datasets' ,'methods' ,'base' ,'aws.s3' ,'data.table' ,'slam' ,'cluster' ,'lsa' ,'SnowballC' ,'tm' ,'NLP' ,'wordcloud' ,'RColorBrewer' ,'plotly' ,'ggplot2' ,'plyr' ,'dplyr' ,'DT' ,'shiny' ,'devtools' ) , repos = 'http://cran.rstudio.com/', dep = TRUE)\""
echo 'R installed'
sudo apt-get install -y gdebi-core
wget https://download3.rstudio.org/ubuntu-12.04/x86_64/shiny-server-1.5.4.852-amd64.deb
sudo gdebi --non-interactive shiny-server-1.5.4.852-amd64.deb

sudo chown -R ubuntu /srv/
rm -Rf /srv/shiny-server/index.html
rm -Rf /srv/shiny-server/sample-apps
