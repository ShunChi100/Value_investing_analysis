library(tidyverse)
library(feather)
library(XLConnect)
library(stringr)
library(lubridate)



main <- function(tikers){
        #tickers <- read_feather(tikers)
        tickers <- read_csv(tikers)      
  
        all_financials <- tibble(Symbolb = character())
        
        for (symbol in tickers$Symbol){
                print(symbol)
                file_name_Growth <- str_c(c("../data/data_financials/", symbol, "_Growth.xlsx"), collapse = "")
                file_name_Balance <- str_c(c("../data/data_financials/", symbol, "_Balance.xlsx"), collapse = "")
                file_name_Income <- str_c(c("../data/data_financials/", symbol, "_Income.xlsx"), collapse = "")
                file_name_Metrics <- str_c(c("../data/data_financials/", symbol, "_Metrics.xlsx"), collapse = "")
                file_name_Cash <- str_c(c("../data/data_financials/", symbol, "_Cash.xlsx"), collapse = "")
                
                read_flag <- any(file.info(file_name_Growth)$size < 4500, 
                                 file.info(file_name_Balance)$size < 4500, 
                                 file.info(file_name_Income)$size < 4500, 
                                 file.info(file_name_Metrics)$size < 4500, 
                                 file.info(file_name_Cash)$size < 4500)
                
                if (read_flag){
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
        
        all_financials <- inner_join(tickers, all_financials, by = "Symbol")
        return(all_financials)
        
}



read_single_financial<- function(datafile){
        
        # read raw data from xlsx using XLConnect pacakge #".../data/data_financials/AAPL_Balance.xlsx"
        raw_data <- readWorksheetFromFile(datafile, sheet = 1, startRow = 1)
        # rotate the raw data
        data_t <- t(raw_data[,-1])
        
        # give the column names by the financial indicators, 
        ## first delete all uncommon characters: " ", ",", "/", "-", "&"
        items <- str_trim(raw_data[,1])
        items <- str_replace_all(items, pattern = " ", replacement = "_")
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

read_financials <- function(symbol){
        
        flag = FALSE
        for (financial in c("Income", "Metrics","Balance","Growth","Cash")){
                datafile <- str_c(c("../data/data_financials/", symbol, "_", financial, ".xlsx"), collapse = "")
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

# AAPL_financials <- read_financials("AAPL")

read_history <- function(symbol){
        datafile <- str_c(c("../data/data_historyPrice/", symbol, "_historyPricefrom20060101to20171118.csv"), collapse = "")
        raw_data <- read_csv(datafile)
        
        colnames(raw_data) <- str_replace_all(colnames(raw_data), pattern = " ", replacement = "_")
        
        return(raw_data)
}

#AAPL_history <- read_history("AAPL")



get_quotes <- function(financials, history_quotes, lower = 0.05, upper = 0.95){
        size <- dim(financials)
        median_quotes <- rep(0, size[1])
        lower_quotes <- rep(0, size[1])
        upper_quotes <- rep(0, size[1])
        
        for (i in 1:size[1]){
                Index = history_quotes$Date >= financials$Date[i] & history_quotes$Date < (financials$Date[i] %m+% years(1))
                year_quotes <- history_quotes[Index,]$Adj_Close
                
                if (is.null(year_quotes)){
                        median_quotes[i] <- NA_real_
                        lower_quotes[i] <- NA_real_
                        upper_quotes[i] <- NA_real_
                }else{  
                        year_quotes <- as.numeric(year_quotes)
                        median_quotes[i] <- median(year_quotes, na.rm = TRUE)
                        lower_quotes[i] <- quantile(year_quotes, probs = 0.05, na.rm = TRUE)
                        upper_quotes[i] <- quantile(year_quotes, probs = 0.95, na.rm = TRUE)
                }
                
        }
        
        financials <- financials %>% 
                mutate(Median_Quote = median_quotes, Lower_Quote = lower_quotes, Upper_Quote = upper_quotes) %>% 
                select(Date, Median_Quote, Lower_Quote, Upper_Quote, everything())
        return(financials)
}

#AAPL_financials <- get_quotes(AAPL_financials, AAPL_history)


# call main() function
stock_finan <- main("../data/data_Ticker/tikers_TenBillion.feather")

write_csv(stock_finan, "../data/stock_data_clean.feather")
#write_feather(stock_finan, "../data/stock_data_clean.feather")

