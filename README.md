# Value Investment Analysis
Value investing has been a hot topic in the stock market. In particular, the success of Warren Buffett inspired many people to pursue the value investing approach. In this project, I would like to test value investing method using ten years historical stock data.

The six known Buffett's methodologies can be found [here](https://www.investopedia.com/articles/01/071801.asp):

1. Has the company consistently performed well?
2. Has the company avoided excess debt?
3. Are profit margins high? Are they increasing?
4. How long has the company been public?
5. Do the company's products rely on a commodity?
6. Is the stock selling at a 25% discount to its real value?

 The first four rules can be quantified using historical stock data. The other two require expertise in finance, so will not be considered here.

 __The null hypothesis__ (need to be refined as the project evolving): The true means of returns are the same for two groups that classified by the first four rules. Classification methods is discussed in the __Analysis__ section below.


### Data Description
Stock data were downloaded from [stockrow.com](stockrow.com) and [Yahoo finance](https://ca.finance.yahoo.com). Thanks to them for making the data publicly available.

Data is cleaned using R language, including all financial data as well as median stock prices for each year. I will perform analysis of this cleaned dataset.


### Analysis
In this analysis, only stocks in US stock exchanges and have market capital larger than ten billion US dollars are considered. For small market cap stocks, parameters fluctuate a lot, and hence value investing may not apply well in general.  

I will use some criteria based on the first four rules to classify stocks into two or more groups. For example, the revenue growth rate is larger than 5%. After classification, we can visualize the stock average price growth verse the groups. We can also try to optimize the criteria so that we can separate a group from the other, which gives the maximum returns in stock growth. These visualization and analysis will conducted in next two milestones and results will be summarized in the final report.

(To be continued as the project evolving.)

### Required packages
#####python
```
import requests
import pandas as pd
import numpy as np
import argparse
import time
import datetime
import re
```
#####R
```
library(tidyverse)
library(XLConnect)
library(stringr)
library(lubridate)
```
