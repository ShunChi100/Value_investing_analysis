library(tidyverse)

# read data (after cleaning)
stock <- read_csv("../results/stock_data_clean.csv")

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
graphs <- c(g1, g2, g3, g4, g5)
names <- c("sectorsummary.pdf", "ROE.pdf","DER.pdf","Profit.pdf", "PE.pdf")

for (i in 1:5){
  ggsave(names[i], plot = graphs[i], device = "pdf")
}