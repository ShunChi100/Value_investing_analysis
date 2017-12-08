---
title: "Value investing analysis"
author: "Shun CHI"
date: "December 7, 2017"
output: github_document
---



# Value investing analysis

Investing is an important part of one's life. With a proper investing, one would have a retired life free of worrying money. Nowadays, most investing is done by financial institutes. However, many financial institutes charge a good amount of managing fee but have under average performance. Can we invest stocks by ourselves? Yes, we can but it can be very risky. One relatively less risky investing method is called value investing. It has been a hot topic in the stock market for decades. In particular, the success of Warren Buffett inspired many people to pursue this approach.

In this report, I did a quantitative analysis on the historical stock data to test the value investing method. Stock data were downloaded from [stockrow.com](stockrow.com) and [Yahoo finance](https://ca.finance.yahoo.com).

The six fundamental Buffett's methodologies can be found [here](https://www.investopedia.com/articles/01/071801.asp):

1. Has the company consistently performed well? (Return on Equity)
2. Has the company avoided excess debt? (Debt to Equity Ratio (DEratio))
3. Are profit margins high? Are they increasing? (Profit Margin)
4. Is the stock selling at a 25% discount to its real value? (Price to Earning ratio (PE))
5. How long has the company been public? (At least have previous five years data)
6. Do the company's products rely on a commodity? 

The first four rules can be quantified using historical data: Return on Equity (ROE), Debt to Equity Ratio (DEratio), Profit Margin (Profit_Margin), and Price to Earning ratio (PEratio). The fifth row is guaranteed by calculating the means of the first three quantities of previous five years, defined as `ROE_5Y`, `DEratio_5Y`, `Profit_Margin_5Y`. That means the companies are at least five years in public stock exchanges. The sixth rule requires expertise in finance, so will not be considered here. In this analysis, only stocks with market capital larger than ten billion US dollars are considered. For small market cap stocks, parameters fluctuate a lot, and hence value investing may not apply well in general.  

#### Analysis results

The data has 17 variables. In this study, we focus on the four quantities as discussed above.

```r
# Read cleaned data
library(tidyverse)
stock <- read_csv("./results/stock_data_clean.csv")
glimpse(stock)
```

```
## Observations: 3,155
## Variables: 17
## $ Symbol           <chr> "ATVI", "ATVI", "ATVI", "ATVI", "ATVI", "ADBE...
## $ Name             <chr> "Activision Blizzard, Inc", "Activision Blizz...
## $ MarketCap        <dbl> 46553043444, 46553043444, 46553043444, 465530...
## $ Sector           <chr> "Technology", "Technology", "Technology", "Te...
## $ Industry         <chr> "Computer Software: Prepackaged Software", "C...
## $ Year             <int> 2016, 2015, 2014, 2013, 2012, 2016, 2015, 201...
## $ Date             <date> 2016-12-31, 2015-12-31, 2014-12-31, 2013-12-...
## $ Median_Quote     <dbl> 58.51000, 37.63955, 25.20926, 20.09384, 14.63...
## $ Median_Q_Growth  <dbl> 0.8087211, 0.7089836, 0.5745195, 0.4776041, 0...
## $ ROE              <dbl> 0.10593267, 0.11056024, 0.11544311, 0.1525219...
## $ ROE_5Y           <dbl> 0.11719732, 0.11669321, 0.10277483, 0.0817873...
## $ DEratio          <dbl> 0.5359, 0.5050, 0.5978, 0.7087, 0.0000, 0.254...
## $ DEratio_5Y       <dbl> 0.46948, 0.36230, 0.26130, 0.14174, 0.00000, ...
## $ Profit_Margin    <dbl> 0.146, 0.191, 0.189, 0.220, 0.237, 0.200, 0.1...
## $ Profit_Margin_5Y <dbl> 0.1966, 0.2130, 0.1936, 0.1610, 0.1408, 0.131...
## $ PEratio          <dbl> 45.00769, 31.10707, 22.11338, 20.93108, 14.49...
## $ Revenue_Growth   <dbl> 0.4168, 0.0581, -0.0382, -0.0562, 0.0212, 0.2...
```

Here, we also filter out "outliers" that give abnormal values. These "outliers" don't help for analyzing the average case. Non-interactive linear regression result is shown below.


```r
stock <- filter(stock, stock$ROE_5Y<0.5, stock$ROE_5Y> -0.25, stock$DEratio_5Y>-0.5, stock$DEratio_5Y<3, stock$PEratio > 0, stock$PEratio < 40, stock$Profit_Margin_5Y >-0.2, stock$Profit_Margin_5Y < 0.4)

lm <- summary(lm(Median_Q_Growth~ROE_5Y + DEratio_5Y + Profit_Margin_5Y + PEratio, data = stock))
broom::tidy(lm)
```

```
##               term    estimate    std.error  statistic      p.value
## 1      (Intercept) 0.080242159 0.0197634911  4.0601207 5.074357e-05
## 2           ROE_5Y 0.699006504 0.0615021845 11.3655557 3.882601e-29
## 3       DEratio_5Y 0.007309049 0.0095910175  0.7620723 4.460976e-01
## 4 Profit_Margin_5Y 0.032303039 0.0719744913  0.4488123 6.536107e-01
## 5          PEratio 0.010681493 0.0007460213 14.3179458 1.513597e-44
```

Here we set the allowed type I error is $\alpha = 0.05$. We can see that `ROE_5Y`, and `PEratio` probably have effects on the price growth of the stocks since their P-values are very small. `DEratio_5Y` and `Profit_Margin_5Y` have relative large P-values, so we cannot safely reject the null hypothesis that they don't affect the growth of stock prices. To have a better feeling of the relationships. the linear fits between the growth of stock price and the four quantities are shown below. 

In summary, according to this analysis, at least two parameters can be used as indicators for value investing. Next, we can apply supervised learning algorithms by using these quantities (features) and find a model to predict stocks that have good pentetial to grow.

![](../results/img/sectorsummary.png)
![](../results/img/ROE.png)
![](../results/img/DER.png)
![](../results/img/Profit.png)
![](../results/img/PE.png)



