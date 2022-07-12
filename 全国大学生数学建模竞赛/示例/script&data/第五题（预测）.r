library(fpp2)
needs = read.csv("script&data/needs.csv",
                 header = FALSE)
needs = needs[, -ncol(needs)]
needs_l = as.numeric(needs[1, ])
for (i in 1:nrow(needs)-1){
    needs_l = c(needs_l, as.numeric(needs[i+1, ]))
}
needs_l = needs_l[-1:-8]
needs_t = ts(needs_l, start = c(1,1), frequency = 4)

# 测试精确度
train = window(needs_t, end = c(22, 4))
h <- 4
ETS <- forecast(ets(train), h=h)
ARIMA <- forecast(auto.arima(train, lambda=0, biasadj=TRUE), h=h)
STL <- stlf(train, lambda=0, h=h, biasadj=TRUE)
NNAR <- forecast(nnetar(train), h=h)
TBATS <- forecast(tbats(train, biasadj=TRUE), h=h)
Combination <- (ETS[["mean"]] + ARIMA[["mean"]] +
                    STL[["mean"]] + NNAR[["mean"]] + TBATS[["mean"]])/5

the_test = c(ETS=accuracy(ETS, needs_t)["Test set","RMSE"],
              ARIMA=accuracy(ARIMA, needs_t)["Test set","RMSE"],
              `STL-ETS`=accuracy(STL, needs_t)["Test set","RMSE"],
              NNAR=accuracy(NNAR, needs_t)["Test set","RMSE"],
              TBATS=accuracy(TBATS, needs_t)["Test set","RMSE"],
              Combination=accuracy(Combination, needs_t)["Test set","RMSE"])

# 预测
train = window(needs_t)
h <- 8
ETS <- forecast(ets(train), h=h)
ARIMA <- forecast(auto.arima(train, lambda=0, biasadj=TRUE), h=h)
STL <- stlf(train, lambda=0, h=h, biasadj=TRUE)
NNAR <- forecast(nnetar(train), h=h)
TBATS <- forecast(tbats(train, biasadj=TRUE), h=h)
Combination <- (ETS[["mean"]] + ARIMA[["mean"]] +
                    STL[["mean"]] + NNAR[["mean"]] + TBATS[["mean"]])/5
# 画图
autoplot(train) +
    autolayer(ETS, series="ETS", PI=FALSE) +
    autolayer(ARIMA, series="ARIMA", PI=FALSE) +
    autolayer(STL, series="STL", PI=FALSE) +
    autolayer(NNAR, series="NNAR", PI=FALSE) +
    autolayer(TBATS, series="TBATS", PI=FALSE) +
    autolayer(Combination, series="Combination") +
    xlab("周期") + ylab("需求量") + 
    labs(colour = "预测方法") +
    theme(text = element_text(family = "STHeiti")) + 
    theme_minimal()

the_test # 精度
round(Combination) # 预测值
