library(tidyverse)
#library(feather)
library(XLConnect)
library(stringr)
library(lubridate)



main <- function(tickers){
  
  # assure the code runs in either project root or /src directories
  cwd <- getwd()
  if (str_sub(cwd, -4, -1) == "/src"){
    project_dir_ref <- "../"
  }else if(str_sub(cwd, -3, -1) == "ting"){
    project_dir_ref <- "./"
  }else{
    print("Please run the script in project root directory or /src directory")
    exit()
  }
  
  # obtain a combined dataframe from both stock historical qoutes and financial statistics
  stock_all <- data_combine(paste0(project_dir_ref,tickers))
  
  # select all relevent data
  colum_list_to_keep <- c("Symbol", "Name", "MarketCap", "Sector", "Industry", "Date", "Median_Quote", "Median_Q_Increase", "UpLow_Q_Var90", "Lower_Quote", "Upper_Quote", "Revenues", "Revenue_Growth", "Profit_Margin", "Debt_to_Equity_Ratio","Net_Income", "Shareholders_Equity", "Total_Liabilities", "Cash_per_Share", "EPS", "Book_Value_per_Share")
  
  stock_filtered <- stock_all %>% 
    select(colum_list_to_keep)
  
  # characters to factors
  stock_filtered$Sector <- factor(stock_filtered$Sector)
  stock_filtered$industry <- factor(stock_filtered$Industry)
  stock_filtered$Symbol <- factor(stock_filtered$Symbol)
  
  # extract year from Data
  stock_filtered <- mutate(stock_filtered, Year = year(Date))
  
  # 
  stock_filtered <- 
    stock_filtered %>% 
    mutate(PEratio = Median_Quote/EPS, 
           ROE = Net_Income/Shareholders_Equity, 
           DEratio = Debt_to_Equity_Ratio,
           Median_Q_Growth = Median_Q_Increase/Median_Quote) 
  
  stock_filtered <- 
    stock_filtered %>% 
    group_by(Symbol) %>% 
    mutate(ROE_5Y = FiveYearMean(ROE),
           DEratio_5Y = FiveYearMean(DEratio),
           Profit_Margin_5Y = FiveYearMean(Profit_Margin)
    )
  
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
  write_csv(stock_cleaned, paste0(project_dir_ref,"results/stock_data_clean.csv"))
  #write_feather(stock_finan, "../data/stock_data_clean.feather")
}

data_combine <- function(tickers){
  
  # assure the code runs in either project root or /src directories
  cwd <- getwd()
  if (str_sub(cwd, -4, -1) == "/src"){
    project_dir_ref <- "../"
  }else if(str_sub(cwd, -3, -1) == "ting"){
    project_dir_ref <- "./"
  }else{
    print("Please run the script in project root directory or /src directory")
    exit()
  }
  
        #tickers <- read_feather(tickers)
        tickers <- read_csv(tickers)  
        colnames(tickers) <- str_replace_all(colnames(tickers), pattern = " ", replacement = "_")
  
        all_financials <- tibble(Symbolb = character())
        
        for (symbol in tickers$Symbol){
                print(symbol)
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

read_financials <- function(symbol){
  
  # assure the code runs in either project root or /src directories
  cwd <- getwd()
  if (str_sub(cwd, -4, -1) == "/src"){
    project_dir_ref <- "../"
  }else if(str_sub(cwd, -3, -1) == "ting"){
    project_dir_ref <- "./"
  }else{
    print("Please run the script in project root directory or /src directory")
    exit()
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

# AAPL_financials <- read_financials("AAPL")

read_history <- function(symbol){
  
  # assure the code runs in either project root or /src directories
  cwd <- getwd()
  if (str_sub(cwd, -4, -1) == "/src"){
    project_dir_ref <- "../"
  }else if(str_sub(cwd, -3, -1) == "ting"){
    project_dir_ref <- "./"
  }else{
    print("Please run the script in project root directory or /src directory")
    exit()
  }
  
        datafile <- str_c(c(project_dir_ref, "data/data_historyPrice/", symbol, "_historyPricefrom20060101to20171118.csv"), collapse = "")
        raw_data <- suppressMessages(read_csv(datafile))
        
        colnames(raw_data) <- str_replace_all(colnames(raw_data), pattern = " ", replacement = "_")
        
        return(raw_data)
}

#AAPL_history <- read_history("AAPL")



get_quotes <- function(financials, history_quotes, lower = 0.05, upper = 0.95){
        size <- dim(financials)
        median_quotes <- rep(0, size[1])
        median_year_diff <- rep(0, size[1])
        lower_quotes <- rep(0, size[1])
        upper_quotes <- rep(0, size[1])
        upper_lower_diff <- rep(0, size[1])
        
        for (i in 1:size[1]){
                Index = history_quotes$Date >= financials$Date[i] & history_quotes$Date < (financials$Date[i] %m+% years(1))
                year_quotes_after <- history_quotes[Index,]$Adj_Close
                
                Index = history_quotes$Date <= financials$Date[i] & history_quotes$Date < (financials$Date[i] %m-% years(1))
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
                        lower_quotes[i] <- quantile(year_quotes_after, probs = 0.05, na.rm = TRUE)
                        upper_quotes[i] <- quantile(year_quotes_after, probs = 0.95, na.rm = TRUE)
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

#AAPL_financials <- get_quotes(AAPL_financials, AAPL_history)

# Funtion to calculate the previous five years' mean of selected quantity
FiveYearMean <- function(x){
  len <- length(x)
  means <- rep(NA_real_, len)
  for (i in 1:(len-4)){
    means[i] <- mean(x[i:(i+4)])
  }
  return(means)
}

# call main() function
 main("data/data_Ticker/tickers_TenBillion.csv")



