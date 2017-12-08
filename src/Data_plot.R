library(tidyverse)
library(stringr)

# read terminal input argument
args <- commandArgs(trailingOnly = TRUE)
inputfile <- args[1]
outputfile = list()
outputfile[[1]] <- args[2]
outputfile[[2]] <- args[3]
outputfile[[3]] <- args[4]
outputfile[[4]] <- args[5]
outputfile[[5]] <- args[6]



# read data (after cleaning)
stock <- suppressMessages(read_csv(inputfile))


# generate plots
g1 = stock %>% filter( Year == 2016 ) %>%
  ggplot(aes(y = MarketCap, x = Sector))+
  geom_jitter(size = 1, alpha = 0.3)+
  geom_boxplot(fill = "blue", alpha = 0.3, color = "blue")+
  theme(axis.text.x = element_text(angle = 45, hjust = 1))+
  scale_y_log10("Market Capitalization", breaks = c(1,10,100)*10000000000) +
  scale_x_discrete("Sectors")

g2 =  stock %>%
  ggplot(aes(x = ROE_5Y, y = Median_Q_Growth))+
  geom_point(alpha = 0.1)+
  geom_smooth(method = lm)+
  scale_x_continuous("Return on Equity (past 5 years mean)",limits = c(-0.25 ,0.5))+
  scale_y_continuous("Price growth rate",limits = c(-0.5, 1))

g3 =  stock %>%
  ggplot(aes(x = DEratio_5Y, y = Median_Q_Growth))+
  geom_point(alpha = 0.1)+
  geom_smooth(method = lm)+
  scale_x_continuous("Debt to equity ratio (past 5 years mean)",limits = c(-0.25 , 3))+
  scale_y_continuous("Price growth rate", limits = c(-0.5, 1))

g4 =  stock %>%
  ggplot(aes(x = Profit_Margin_5Y, y = Median_Q_Growth))+
  geom_point(alpha = 0.1)+
  geom_smooth(method = lm)+
  scale_x_continuous("Profit margin (past 5 years mean)",limits = c(-0.2 , 0.4))+
  scale_y_continuous("Price growth rate", limits = c(-0.5, 1))

g5 = stock %>%
  ggplot(aes(x = PEratio, y = Median_Q_Growth))+
  geom_point(alpha = 0.1)+
  geom_smooth(method = lm)+
  scale_x_continuous("Price to earning ratio",limits = c(0 , 40))+
  scale_y_continuous("Price growth rate", limits = c(-0.5, 1))


# save plots
myplots <- list()
myplots[[1]] <- g1
myplots[[2]] <- g2
myplots[[3]] <- g3
myplots[[4]] <- g4
myplots[[5]] <- g5

names <- c("sectorsummary.png", "ROE.png","DER.png","Profit.png", "PE.png")
for (i in 1:5){
  suppressMessages(ggsave(outputfile[[i]], plot = myplots[[i]], device = "png"))
  print(paste("Saving graph", names[i]))
}



##################################################
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