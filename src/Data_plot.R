# Data_plot.R
# Shun Chi, Dec 2017
# 
# This script imports the cleaned ./results/stock_data_clean.csv
# and use it to output five plots: results/img/sectorsummary.png,
# results/img/ROE.png, results/img/DER.png, results/img/Profit.png
# results/img/PE.png
#
# Usage: Rscript ./src/Data_plot.R ./results/stock_data_clean.csv results/img/sectorsummary.png results/img/ROE.png results/img/DER.png results/img/Profit.png results/img/PE.png


library(tidyverse)
library(stringr)

# read terminal input argument
args <- commandArgs(trailingOnly = TRUE)

# read input data file
inputfile <- args[1]

# read output figure files
outputfile = list()
outputfile[[1]] <- args[2]
outputfile[[2]] <- args[3]
outputfile[[3]] <- args[4]
outputfile[[4]] <- args[5]
outputfile[[5]] <- args[6]


# read data (after cleaning)
stock <- suppressMessages(read_csv(inputfile))
# data filtering, remove outliers
stock <- filter(stock, stock$ROE_5Y<0.5, 
                stock$ROE_5Y> -0.25, 
                stock$DEratio_5Y>-0.5, 
                stock$DEratio_5Y<3, 
                stock$PEratio > 0, 
                stock$PEratio < 40, 
                stock$Profit_Margin_5Y >-0.2, 
                stock$Profit_Margin_5Y < 0.4)


# generate plots
g1 = stock %>% filter( Year == 2016 ) %>%
  ggplot(aes(y = MarketCap, x = Sector))+
  geom_jitter(size = 1, alpha = 0.3)+
  geom_boxplot(fill = "blue", alpha = 0.3, color = "blue")+
  theme(axis.text.x = element_text(angle = 45, hjust = 1))+
  scale_y_log10("Market Capitalization", breaks = c(1,10,100)*10000000000) +
  scale_x_discrete("Sectors")+
  ggtitle("Market Capitalization distributions in different Sectors")

g2 =  stock %>%
  ggplot(aes(x = ROE_5Y, y = Median_Q_Growth))+
  geom_point(alpha = 0.1)+
  geom_smooth(method = lm)+
  scale_x_continuous("Return on Equity (past 5 years mean)",limits = c(-0.25 ,0.5))+
  scale_y_continuous("Price growth rate",limits = c(-0.5, 1))+
  ggtitle("Price Growth v.s. Return on Equity")

g3 =  stock %>%
  ggplot(aes(x = DEratio_5Y, y = Median_Q_Growth))+
  geom_point(alpha = 0.1)+
  geom_smooth(method = lm)+
  scale_x_continuous("Debt to equity ratio (past 5 years mean)",limits = c(-0.25 , 3))+
  scale_y_continuous("Price growth rate", limits = c(-0.5, 1))+
  ggtitle("Price Growth v.s. Debt to Equity Ratio")

g4 =  stock %>%
  ggplot(aes(x = Profit_Margin_5Y, y = Median_Q_Growth))+
  geom_point(alpha = 0.1)+
  geom_smooth(method = lm)+
  scale_x_continuous("Profit margin (past 5 years mean)",limits = c(-0.2 , 0.4))+
  scale_y_continuous("Price growth rate", limits = c(-0.5, 1))+
  ggtitle("Price Growth v.s. Profit Margin")

g5 = stock %>%
  ggplot(aes(x = PEratio, y = Median_Q_Growth))+
  geom_point(alpha = 0.1)+
  geom_smooth(method = lm)+
  scale_x_continuous("Price to earning ratio",limits = c(0 , 40))+
  scale_y_continuous("Price growth rate", limits = c(-0.5, 1))+
  ggtitle("Price Growth v.s. Price to Earning Ratio")


# put all plots in a list
myplots <- list()
myplots[[1]] <- g1
myplots[[2]] <- g2
myplots[[3]] <- g3
myplots[[4]] <- g4
myplots[[5]] <- g5

names <- c("sectorsummary.png", "ROE.png","DER.png","Profit.png", "PE.png")

# save plots
for (i in 1:5){
  suppressMessages(ggsave(outputfile[[i]], plot = myplots[[i]], device = "png"))
  print(paste("Saving graph", names[i]))
}





##################################################

## codes for runing without input arguments

# # assure the code runs in either project root or ./src directory
# cwd <- getwd()
# if (str_sub(cwd, -4, -1) == "/src"){
#   project_dir_ref <- "../"
# }else if(str_sub(cwd, -4, -1) == "ting"){
#   project_dir_ref <- "./"
# }else{
#   print("Please run the script in project root directory or /src directory")
#   exit()
# }
#stock <- suppressMessages(read_csv(paste0(project_dir_ref,"results/stock_data_clean.csv")))


# # Output figure files without terminal arguments
# names <- c("sectorsummary.png", "ROE.png","DER.png","Profit.png", "PE.png")
#for (i in 1:5){
#  suppressMessages(ggsave(paste0(project_dir_ref,"results/img/",names[i]), plot = myplots[[i]], device = "png"))
#  print(paste("Saving graph", i))
#}


##################################################3

# # read input data file
#inputfile <- './results/stock_data_clean.csv' # args[1]

# read output figure files
#outputfile = list()
#outputfile[[1]] <-"results/img/sectorsummary.png"# args[2]
#outputfile[[2]] <-"results/img/ROE.png"  #  args[3]
#outputfile[[3]] <-  "results/img/DER.png" #args[4]
#outputfile[[4]] <- "results/img/Profit.png"  # args[5]
#outputfile[[5]] <- "results/img/PE.png"  #args[6]

