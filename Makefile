## To be complete
# mkdir ./data/data_Tickers
# mkdir ./data/data_financials
# mkdir ./data/data_historyPrice

# make all
all: results/stock_data_clean.csv

# create ticker symbol data and downloading online data
data/data_Ticker/tickers_TenBillion.csv: ./src/stock_symbol_selecting.py
	python ./src/stock_symbol_selecting.py NASDAQ NYSE AMEX data/data_Ticker/tickers_TenBillion.csv

# clean data and create a dataframe with desired testing variables
results/stock_data_clean.csv: ./src/data_cleaning.R ./data/data_Ticker/tickers_TenBillion.csv
	Rscript ./src/data_cleaning.R ./data/data_Ticker/tickers_TenBillion.csv results/stock_data_clean.csv

# clean files
clean:
	rm data/data_Ticker/tickers_TenBillion.csv
	rm data/data_financials/ATVI*
	rm data/data_financials/ADBE*
	rm data/data_historyPrice/ADBE*
	rm data/data_historyPrice/ATVI*
	rm results/stock_data_clean.csv
