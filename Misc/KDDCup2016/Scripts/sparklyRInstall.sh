sudo apt-get install libcurl4-openssl-dev
cd /usr/lib64/MRO-for-MRS-8.0.3/R-3.2.2/lib/R
sudo rm -r sparklyr sparkapi rprojroot dplyr Rcpp DBI config tibble devtools rmarkdown
cd
sudo R --vanilla --quiet  <  /home/remoteuser/Scripts/github_installs.R
