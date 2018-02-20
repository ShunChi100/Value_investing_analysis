# data_cleaning.R
# Shun Chi, Dec 2017
# 
# This script imports all stock historical data and financial data.
# All data are combined to a single dataframe. Missing data are deleted.
# Only useful data for this analysis are selected.
#
# Usage: Rscript ./src/data_cleaning.R ./data/data_Ticker/tickers_TenBillion.csv results/stock_data_clean.csv

library(tidyverse)
library(XLConnect)
library(stringr)
library(lubridate)
#library(feather)


# # main function for data cleaning
# # inputs: tickers -- path for the stock ticker symbol list file tickers_TenBillion.csv
# #         outputfile -- path for the output stock_data_clean.csv
# # outputs: write the cleaned data to stock_data_clean.csv
main <- function(tickers, outputfile){

  # assure the code runs in either project root or /src directories
  cwd <- getwd()
  print(cwd)
  print(str_sub(cwd, -4, -1))
  if (str_sub(cwd, -4, -1) == "/src"){
    project_dir_ref <- "../"
  }else{
    project_dir_ref <- "./"
  }

  # obtain a combined dataframe from both stock historical qoutes and financial statistics
  # stock_all <- data_combine(paste0(project_dir_ref,tickers))
  stock_all <- data_combine(tickers)

  # select all relevent data
  colum_list_to_keep <- c("Symbol", "Name", "MarketCap", 
                          "Sector", "Industry", "Date", 
                          "Median_Quote", "Median_Q_Increase", 
                          "UpLow_Q_Var90", "Lower_Quote", 
                          "Upper_Quote", "Revenues", 
                          "Revenue_Growth", "Profit_Margin", 
                          "Debt_to_Equity_Ratio","Net_Income", 
                          "Shareholders_Equity", "Total_Liabilities", 
                          "Cash_per_Share", "EPS", "Book_Value_per_Share")

  stock_filtered <- stock_all %>%
    select(colum_list_to_keep)

  # in stock dataframe: characters to factors
  stock_filtered$Sector <- factor(stock_filtered$Sector)
  stock_filtered$industry <- factor(stock_filtered$Industry)
  stock_filtered$Symbol <- factor(stock_filtered$Symbol)

  # in stock dataframe:  add a `Year` column
  stock_filtered <- mutate(stock_filtered, Year = year(Date))

  # in stock dataframe:  add `PEratio`, `ROE`, `DEratio`, `Median_Q_Growth` columns
  stock_filtered <-
    stock_filtered %>%
    mutate(PEratio = Median_Quote/EPS,
           ROE = Net_Income/Shareholders_Equity,
           DEratio = Debt_to_Equity_Ratio,
           Median_Q_Growth = Median_Q_Increase/Median_Quote)

  # in stock dataframe:  add `ROE_5Y`, `DEratio_5Y`, `Profit_Margin_5Y` columns
  stock_filtered <-
    stock_filtered %>%
    group_by(Symbol) %>%
    mutate(ROE_5Y = FiveYearMean(ROE),
           DEratio_5Y = FiveYearMean(DEratio),
           Profit_Margin_5Y = FiveYearMean(Profit_Margin)
    )
  # Select desired columns for the cleaned data 
  stock_cleaned <- stock_filtered %>%
    select(Symbol,
           Name,
           MarketCap,
           Sector,
           Industry,
           Year,
           Date,
           Median_Quote,
           Median_Q_Growth,
           ROE,
           ROE_5Y,
           DEratio,
           DEratio_5Y,
           Profit_Margin,
           Profit_Margin_5Y,
           PEratio,
           Revenue_Growth)

  # remove rows with NA values
  stock_cleaned <-
    stock_cleaned %>%
    na.omit()

  # save the cleaned final data into the result folder
  #write_csv(stock_cleaned, paste0(project_dir_ref,"results/stock_data_clean.csv"))
  write_csv(stock_cleaned, outputfile)
  
  # save in feather format for using in python pandas
  #write_feather(stock_finan, "../data/stock_data_clean.feather")
}


# # data_combine(tickers): function for read all data from data files and combine them into a single dataframe
# # input: tickers -- path for the stock ticker symbol list file tickers_TenBillion.csv
# # output: return a all data combined dataframe
data_combine <- function(tickers){

  # assure the code runs in either project root or /src directories
  cwd <- getwd()
  if (str_sub(cwd, -4, -1) == "/src"){
    project_dir_ref <- "../"
  }else{
    project_dir_ref <- "./"
  }

        #tickers <- read_feather(tickers)
        tickers <- read_csv(tickers)
        colnames(tickers) <- str_replace_all(colnames(tickers), pattern = " ", replacement = "_")

        all_financials <- tibble(Symbolb = character())

        for (symbol in tickers$Symbol){
                print(paste("reading data for stock",symbol))
                file_name_Growth <- str_c(c(project_dir_ref, "data/data_financials/", symbol, "_Growth.xlsx"), collapse = "")
                file_name_Balance <- str_c(c(project_dir_ref, "data/data_financials/", symbol, "_Balance.xlsx"), collapse = "")
                file_name_Income <- str_c(c(project_dir_ref, "data/data_financials/", symbol, "_Income.xlsx"), collapse = "")
                file_name_Metrics <- str_c(c(project_dir_ref, "data/data_financials/", symbol, "_Metrics.xlsx"), collapse = "")
                file_name_Cash <- str_c(c(project_dir_ref, "data/data_financials/", symbol, "_Cash.xlsx"), collapse = "")


                read_flag1 <- file.exists(file_name_Growth)

                read_flag2 <- any(file.info(file_name_Growth)$size < 4500,
                                  file.info(file_name_Balance)$size < 4500,
                                  file.info(file_name_Income)$size < 4500,
                                  file.info(file_name_Metrics)$size < 4500,
                                  file.info(file_name_Cash)$size < 4500)

                if (read_flag1){
                        if(read_flag2){
                                next
                        }else{
                                tmp_financials <- read_financials(symbol )
                                tmp_history <- read_history(symbol)
                                tmp_financials <- get_quotes(tmp_financials, tmp_history)

                                tmp_financials <- tmp_financials %>%
                                        mutate(Symbol = symbol)

                                all_financials <- bind_rows(all_financials, tmp_financials)
                        }
                }

        }

        all_financials <- inner_join(tickers, all_financials, by = "Symbol")
        return(all_financials)

}


# # read_single_financial(datafile): function for read a single historical financial data from ./data/financials/
# # input: datafile -- path for the datafile to read
# # output: return a dataframe
read_single_financial<- function(datafile){

        # read raw data from xlsx using XLConnect pacakge #".../data/data_financials/AAPL_Balance.xlsx"
        raw_data <- readWorksheetFromFile(datafile, sheet = 1, startRow = 1)
        # rotate the raw data
        data_t <- t(raw_data[,-1])

        # give the column names by the financial indicators,
        ## first delete all uncommon characters: " ", ",", "/", "-", "&"
        items <- str_trim(raw_data[,1])
        items <- str_replace_all(items, pattern = " ", replacement = "_")
        items <- str_replace_all(items, pattern = "`", replacement = "")
        items <- str_replace_all(items, pattern = ",", replacement = "")
        items <- str_replace_all(items, pattern = "&", replacement = "and")
        items <- str_replace_all(items, pattern = "-", replacement = "_")
        items <- str_replace_all(items, pattern = "/", replacement = "_")
        items <- str_replace_all(items, pattern = "\\(", replacement = "")
        items <- str_replace_all(items, pattern = "\\)", replacement = "")

        colnames(data_t) <- items

        # get the row names which are the dates for the financial reports
        times <- rownames(data_t)
        Date <- str_c(str_sub(times, start = 2, end = 5),str_sub(times, 7, 8),str_sub(times, 10, 11), sep = "-")


        # extract date and convert to Date format
        data_f <- as_tibble(data_t) %>%
                mutate(Date = as.Date(Date)) %>%
                select(Date, everything())

        return(data_f) # data_f the final data
}


# # read_financials(symbol): function for read all historical financial data for stock symbol
# # input: symbol -- the stock symbol for whose data to be read
# # output: return a combined dataframe for a single stock symbol
# # example: AAPL_financials <- read_financials("AAPL")
read_financials <- function(symbol){

  # assure the code runs in either project root or /src directories
  cwd <- getwd()
  if (str_sub(cwd, -4, -1) == "/src"){
    project_dir_ref <- "../"
  }else{
    project_dir_ref <- "./"
  }

        flag = FALSE
        for (financial in c("Income", "Metrics","Balance","Growth","Cash")){
                datafile <- str_c(c(project_dir_ref, "data/data_financials/", symbol, "_", financial, ".xlsx"), collapse = "")
                if (file.exists(datafile)){
                        wb <- loadWorkbook(datafile)
                        if (existsSheet(wb, symbol)){
                                data <- read_single_financial(datafile)
                                if (flag){
                                        data_financials <- left_join(data_financials, data, by = "Date")# by = c("Year", "Month", "Day"))
                                }
                                else{
                                        data_financials <- data
                                        flag = TRUE
                                }
                        }

                }


        }

        return(data_financials)
}


# # read_history(symbol): function for read historical stock price data for the input stock symbol
# # input: symbol -- the stock symbol for whose data to be read
# # output: return a dataframe for a single stock symbol
# # example: AAPL_history <- read_history("AAPL")
read_history <- function(symbol){

  # assure the code runs in either project root or /src directories
  cwd <- getwd()
  if (str_sub(cwd, -4, -1) == "/src"){
    project_dir_ref <- "../"
  }else{
    project_dir_ref <- "./"
  }

        datafile <- str_c(c(project_dir_ref, "data/data_historyPrice/", symbol, "_historyPricefrom20060101to20171118.csv"), collapse = "")
        raw_data <- suppressMessages(read_csv(datafile))

        colnames(raw_data) <- str_replace_all(colnames(raw_data), pattern = " ", replacement = "_")

        return(raw_data)
}


# # get_quotes(financials, history_quotes, lower = 0.05, upper = 0.95): function for converint historical 
# # stock price data to yearly median, lower and upper price and then insert into financial dataframe
# # input: financials -- the financials dataframe
# #        history_qoutes -- the historical price dataframe
# #        lower --  the lower bound for defining lower
# #        upper --  the upper bound for defining upper
# # output: return a dataframe with both price and financial data
# # example: AAPL_financials <- get_quotes(AAPL_financials, AAPL_history)
get_quotes <- function(financials, history_quotes, lower = 0.1, upper = 0.9){
        size <- dim(financials)
        median_quotes <- rep(0, size[1])
        median_year_diff <- rep(0, size[1])
        lower_quotes <- rep(0, size[1])
        upper_quotes <- rep(0, size[1])
        upper_lower_diff <- rep(0, size[1])

        for (i in 1:size[1]){
                Index = history_quotes$Date >= financials$Date[i] & history_quotes$Date < (financials$Date[i] %m+% years(1))
                year_quotes_after <- history_quotes[Index,]$Adj_Close

                Index = history_quotes$Date <= financials$Date[i] & history_quotes$Date > (financials$Date[i] %m-% years(1))
                year_quotes_before <- history_quotes[Index,]$Adj_Close

                if (is.null(year_quotes_after)){
                        median_year_diff[i] <- NA_real_
                        median_quotes[i] <- NA_real_
                        lower_quotes[i] <- NA_real_
                        upper_quotes[i] <- NA_real_
                        upper_lower_diff[i] <- NA_real_
                }else{
                        year_quotes_after <- as.numeric(year_quotes_after)
                        year_quotes_before <- as.numeric(year_quotes_before)
                        median_quotes[i] <- median(year_quotes_after, na.rm = TRUE)
                        median_year_diff[i] <- median_quotes[i] - median(year_quotes_before, na.rm = TRUE)
                        lower_quotes[i] <- quantile(year_quotes_after, probs = lower, na.rm = TRUE)
                        upper_quotes[i] <- quantile(year_quotes_after, probs = upper, na.rm = TRUE)
                        upper_lower_diff[i] <- upper_quotes[i] - lower_quotes[i]
                }

        }

        financials <- financials %>%
                mutate(Median_Quote = median_quotes,
                       Median_Q_Increase = median_year_diff,
                       Lower_Quote = lower_quotes,
                       Upper_Quote = upper_quotes,
                       UpLow_Q_Var90 = upper_lower_diff
                       ) %>%
                select(Date, Median_Quote, Lower_Quote, Upper_Quote, everything())
        return(financials)
}


# # FiveYearMean(x): Funtion to calculate the previous five years' mean of selected quantity
# # input: x -- the yearly values of the quantity
# # output: return the means with each calculated from the previous five years, 
# # mean_2016 = mean(values(2012:2016))
FiveYearMean <- function(x){
  len <- length(x)
  means <- rep(NA_real_, len)
  for (i in 1:(len-4)){
    means[i] <- mean(x[i:(i+4)])
  }
  return(means)
}


# take the command line inputs
args <- commandArgs(trailingOnly = TRUE)
# the path to the input file 
inputfile <- args[1]
# the path to the output file 
outputfile <- args[2]

# call main() function
main(inputfile, outputfile)