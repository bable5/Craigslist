#!/bin/sh
cd /home/susan/Documents/R\ Projects/Craigslist
R CMD BATCH ./ScrapeCLForSale.R
R CMD BATCH ./ScrapeCL.R
git commit -a -m "CRON Auto-Commit after script runs"
git push
