# coding: utf-8
# # Data scraping from websites (public data)
"""
### Download historical financial data from stockrow.com

Ten years historical finanical data can be downloaded from [stockrow.com](stockrow.com)

The following urls are sample links to five types of hitorical data

* https://stockrow.com/api/companies/AAPL/financials.xlsx?dimension=MRY&section=Balance%20Sheet
* https://stockrow.com/api/companies/AAPL/financials.xlsx?dimension=MRY&section=Income%20Statement
* https://stockrow.com/api/companies/AAPL/financials.xlsx?dimension=MRY&section=Cash%20Flow
* https://stockrow.com/api/companies/AAPL/financials.xlsx?dimension=MRY&section=Metrics
* https://stockrow.com/api/companies/AAPL/financials.xlsx?dimension=MRY&section=Growth

For _dimension=MR*_ , here MRY -> Annual data, MRQ -> Quarterly data

### Obtain historical quotes from Yahoo Finance

Historical price data in daily frequency can be downloaded from [Yahoo Finance](http://finance.yahoo.com).
The following url is an example link to hitorical qoutes of AAPL

https://query1.finance.yahoo.com/v7/finance/download/AAPL?period1=1167638400&period2=1510992000&interval=1d&events=history&crumb=SkLNFzvwnuu
"""

# In[2]:

import requests
import pandas as pd
import numpy as np
import feather
import time
import datetime
import re


def main():
    """
    Download stock data and save to data directory

    :return: None
    """

    # read all stock symbols for analysis
    tickers_TenBillion = pd.read_csv("./data/data_Ticker/tickers_TenBillion.csv")

    financial_list = ["Income%20Statement", "Balance%20Sheet", "Cash%20Flow", "Metrics", "Growth"]

    for symbol in tickers_TenBillion.Symbol[0:2]:

        # download historical financial data
        for financial in financial_list:
            download_financials(symbol, financial)
            time.sleep(0.01)

        # get historical price data for all symbols
        download_historyPrice(symbol)
        time.sleep(0.01)
        print("Downloaded stock data for", symbol)


def download_financials(symbol, financial):
    """
    Download financial data
    
    There are five financial sheets: Balance, Income, Cash, Metrics, Growth
    
    Inputs:
    symbol: str that represent a stock symbol, e.g. "AAPL"
    financial: str that represent a type of stock financial, e.g. "Balance"
    
    Outputs:
    Write data into a file in data directory
    """

    # construct url
    url_income = "https://stockrow.com/api/companies/" + symbol + "/financials.xlsx?dimension=MRY&section=" + financial

    # web scrapping
    readdata = requests.get(url_income, allow_redirects=True)

    # write to a file
    file = open("./data/data_financials/" + symbol + "_" + financial.split("%")[0] + ".xlsx", 'wb')
    file.write(readdata.content)
    file.close()


# in yahoo finance, a cookie/crumb pair need to be find.
def get_yahoo_crumb_cookie():
    """
    Get Yahoo crumb cookie value.
    
    Original Source: https://pypi.python.org/pypi/fix-yahoo-finance
    """
    res = requests.get('https://finance.yahoo.com/quote/SPY/history')
    yahoo_cookie = res.cookies['B']
    yahoo_crumb = None
    pattern = re.compile('.*"CrumbStore":\{"crumb":"(?P<crumb>[^"]+)"\}')
    for line in res.text.splitlines():
        m = pattern.match(line)
        if m is not None:
            yahoo_crumb = m.groupdict()['crumb']
    return yahoo_cookie, yahoo_crumb


def download_historyPrice(symbol, start_Date="20060101", end_Date="20171118"):
    """
    Download stock historical data
    
    Download data from Yahoo finance website
    
    Inputs:
    symbol: str that represent a stock symbol, e.g. "AAPL"
    start_Date: str that represent a date as format "YYYYMMDD"
    end_Date: str that represent a date as format "YYYYMMDD"
    
    Outputs:
    Write data into a file in data directory
    """

    # get yahoo crumb cookie value
    cookie_tuple = get_yahoo_crumb_cookie()

    start_Date_Unix = time.mktime(datetime.datetime.strptime(start_Date, "%Y%m%d").timetuple())
    end_Date_Unix = time.mktime(datetime.datetime.strptime(end_Date, "%Y%m%d").timetuple())

    start_Date_Unix = str(int(start_Date_Unix))
    end_Date_Unix = str(int(end_Date_Unix))

    url_price = "https://query1.finance.yahoo.com/v7/finance/download/" + symbol + "?period1=" + start_Date_Unix + "&period2=" + end_Date_Unix + "&interval=1d&events=history&crumb=" + \
                cookie_tuple[1]
    readdata = requests.get(url_price, allow_redirects=True, cookies={'B': cookie_tuple[0]})
    file = open(
        "./data/data_historyPrice/" + symbol + "_" + "historyPricefrom" + start_Date + "to" + end_Date + ".csv", 'wb')
    file.write(readdata.content)
    file.close()

#main()