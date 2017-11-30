
# coding: utf-8

# # Stock Ticker Symbol Data cleaning

# The ticker symbol data is downloaded from [NASDAQ.com](http://www.nasdaq.com/screening/company-list.aspx). For this project we would like to select stocks with marketcapital larger than 10 billion.

import requests
import pandas as pd
import numpy as np
import argparse
import Data_download_historical as download

# parser argument inputs
parser = argparse.ArgumentParser()

parser.add_argument("exchange1")
parser.add_argument("exchange2")
parser.add_argument("exchange3")
parser.add_argument("save_path_filename")

args = parser.parse_args()

# ### Download ticker symbols data for US exchanges

exchanges = [args.exchange1, args.exchange2, args.exchange3]
#exchanges = ["NASDAQ", "NYSE", "AMEX"]

for exchange in exchanges:

    # construct the url to download data
    url_exchange = "http://www.nasdaq.com/screening/companies-by-industry.aspx?exchange=" + exchange + "&render=download"

    # web scrapping
    readdata = requests.get(url_exchange, allow_redirects=True)

    # write to a file
    file = open("./data/data_Ticker/" + exchange + ".csv", 'wb')
    file.write(readdata.content)
    file.close()

    print("Saved ticker symbols for", exchange)


# ### Read data

# read ticker symbols from all US stocks, data source (http://www.nasdaq.com/screening/company-list.aspx)
tickers_NASDAQ = pd.read_csv("./data/data_Ticker/NASDAQ.csv", skiprows=None)
tickers_NASDAQ["Exchange"] = "NASDAQ"

tickers_NYSE = pd.read_csv("./data/data_Ticker/NYSE.csv", skiprows=None)
tickers_NYSE["Exchange"] = "NYSE"

tickers_AMEX = pd.read_csv("./data/data_Ticker/AMEX.csv", skiprows=None)
tickers_AMEX["Exchange"] = "AMEX"

# combine all symbols from three exchanges into one dataframe
tickers = tickers_NASDAQ.append(tickers_NYSE)
tickers = tickers.append(tickers)


# __Data cleaning:__
#
# * remove symbols with `^`
# * reomve symbols without stock price `LastSale == n/a`
# * reomve symbols without market captical `MarketCap == n/a`

# remove stocks with ^ signs
data_size = tickers.shape
data_size = np.arange(data_size[0])   # give a integer vector for indexing in tickers.
tickers = tickers.reset_index()     # reset index after joining multiple dataframes
tickers.drop(list(data_size[tickers.Symbol.str.contains("\^").tolist()]),axis = 0, inplace=True)
tickers = tickers.reset_index()    # reset index after deleting some rows

# drop colums created when reseting index.
tickers.drop(["level_0", "index"], axis=1, inplace=True)

# reomve symbols without market captical `MarketCap == n/a`
tmp = tickers.shape
tmp = np.arange(tmp[0])
tickers.drop(list(tmp[tickers.MarketCap < 10]), axis=0, inplace=True)
tickers = tickers.reset_index()

# delete duplicated names
tickers.drop_duplicates(["Name"], inplace=True)

# delete rows with Sector == n/a
tmp = tickers.shape
tmp = np.arange(tmp[0])
tickers = tickers.reset_index()
tickers.drop(["level_0", "index"], axis=1, inplace=True)
tickers.drop(list(tmp[tickers.Sector=="n/a"]), axis=0, inplace=True)
tickers = tickers.reset_index()

# drop colums created when reseting index.
tickers.drop(["index"], axis=1, inplace=True)

print("ticker symbol list is cleaned! All unusual symbols are deleted!")

# ### Select tickers with only market cap larger than 10 Billion

# Here we only select stocks with market cap that is larger than 10 billion in 2017-11. To do that, we can first select rows in which `MarketCap` column contains `B` (billion). Then covert the type to numeric and selecting values larger than 10.

# select ticker symbols with `MarketCap` contains "B"
tickers_TenBillion = tickers.loc[tickers.MarketCap > 10000000000]

# see the filtered symbols
tickers_TenBillion = tickers_TenBillion.reset_index();
tickers_TenBillion.drop(["index"], axis=1, inplace=True)

# convert last sale price type to numeric
tickers_TenBillion.loc[:,"LastSale"] = tickers_TenBillion.loc[:, "LastSale"].astype(float);

print("Symbols with market cap larger than 10 billion are selected")

# #### Save the ticker symbols dataframe to feature (for read in R)

# Write to a csv file
#tickers_TenBillion.to_csv("../data/data_Ticker/tickers_TenBillion.csv")
tickers_TenBillion.to_csv(args.save_path_filename)

print("Selected symbol list is saved in", args.save_path_filename)

print("downloading stock data from the ticker symbols selected.")

download.main()
