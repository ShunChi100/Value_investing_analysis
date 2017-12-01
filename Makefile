## To be complete
# mkdir ./data/data_Tickers
# mkdir ./data/data_financials
# mkdir ./data/data_historyPrice


./data/data_Ticker/tickers_TenBillion.csv: ./src/stock_symbol_selecting.py
	python ./src/stock_symbol_selecting.py NASDAQ NYSE AMEX ./data/data_Ticker/tickers_TenBillion.csv

./results/stock_data_clean.csv: ./src/data_cleaning.R ./data/data_Ticker/tickers_TenBillion.csv
	Rscript ./src/data_cleaning.R ./data/data_Ticker/tickers_TenBillion.csv ./results/stock_data_clean.csv
