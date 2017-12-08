# Makefile
# Shun CHI, Dec 2017
#
# This is a makefile, used to generate results and reports for this project
# To run all steps, `make all`


# make all
all: results/img/sectorsummary.png doc/Analysis_report.md

# create ticker symbol data and downloading online data
data/data_Ticker/tickers_TenBillion.csv: ./src/stock_symbol_selecting.py
	python ./src/stock_symbol_selecting.py NASDAQ NYSE AMEX data/data_Ticker/tickers_TenBillion.csv

# clean data and create a dataframe with desired testing variables
results/stock_data_clean.csv: ./src/data_cleaning.R ./data/data_Ticker/tickers_TenBillion.csv
	Rscript ./src/data_cleaning.R ./data/data_Ticker/tickers_TenBillion.csv results/stock_data_clean.csv

# read cleaned data and use these data for figures. There are five output figures, however make does not support multiple targets, so I only use one output figure as the target.
results/img/sectorsummary.png: ./src/Data_plot.R ./results/stock_data_clean.csv
	Rscript ./src/Data_plot.R ./results/stock_data_clean.csv results/img/sectorsummary.png results/img/ROE.png results/img/DER.png results/img/Profit.png results/img/PE.png

# knitr the Analysis_report.Rmd to markdown file
doc/Analysis_report.md: src/Analysis_report.Rmd
	Rscript -e 'ezknitr::ezknit("src/Analysis_report.Rmd", out_dir = "doc")'


# clean files
clean:
	rm data/data_Ticker/tickers_TenBillion.csv
	rm data/data_financials/ATVI*
	rm data/data_financials/ADBE*
	rm data/data_historyPrice/ADBE*
	rm data/data_historyPrice/ATVI*
	rm results/stock_data_clean.csv
	rm results/img/*.png
	rm -rf doc/Analysis_report*
