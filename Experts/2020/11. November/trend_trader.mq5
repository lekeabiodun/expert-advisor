#include <Trade\Trade.mqh>
CTrade trade;
enum marketSignal{ BUY, SELL };
enum marketEntry { LONG, SHORT };
enum tradeBehaviour { REGULAR, OPPOSITE };
enum marketTrend{ BULLISH, BEARISH, SIDEWAYS };

input group                                         "============  EA Settings  ===============";
input int                                           EXPERT_MAGIC = 555784; // Magic Number
input tradeBehaviour                                expertBehaviour = REGULAR; // Trading Behaviour
input group                                         "============  Money Management Settings ===============";
input double                                        lotSize = 1; // Lot Size
input double                                        stopLoss = 0.0; // Stop Loss in Pips
input double                                        takeProfit = 0.0; // Take Profit in Pips
input group                                         "============  Scalp Settings ===============";
input bool                                          expertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          expertIsTakingSellTrade = false; // Take Sell Trade


marketSignal lastTrade = BUY;
int OnInit() {
    Print("1 Samuel 30:8 King James Version");
    Print("And David inquired at the LORD, saying, Shall I pursue after this troop? shall I overtake them?");
    Print("And he answered him, Pursue: for thou shalt surely overtake them, and without fail recover all.");
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
    Print("1 Samuel 30:8 King James Version");
    Print("And David inquired at the LORD, saying, Shall I pursue after this troop? shall I overtake them?");
    Print("And he answered him, Pursue: for thou shalt surely overtake them, and without fail recover all.");
}

void OnTick() 
{
    if(!spikeLatency()) { return ; }
    
    tradePositionManager();

    if(PositionsTotal() >= 2) { return ; }


    if(lastTrade == BUY) { 
        takeTrade(SHORT);
        lastTrade = SELL;
        return ;

    } else {
        takeTrade(LONG);
        lastTrade = BUY;
        return ;
    }

    
}

void takeTrade(marketEntry entry) {
   if(entry == LONG && expertIsTakingBuyTrade) {
        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        trade.Buy(lotSize, Symbol(), ask, 0, 0);
   }

   if(entry == SHORT && expertIsTakingSellTrade) {
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        trade.Sell(lotSize, Symbol(), bid, 0, 0);
   }
}

/* ##################################################### Trade Position Manager ##################################################### */
void tradePositionManager() {
    for(int i = PositionsTotal()-1; i >= 0; i--) {
        PositionGetSymbol(i);
        if(PositionGetDouble(POSITION_PROFIT) >= (lotSize * takeProfit)) {
            ulong ticket = PositionGetTicket(i);
            trade.PositionClose(ticket);
        }
        if(PositionGetDouble(POSITION_PROFIT) <= -(lotSize * stopLoss)) {
            ulong ticket = PositionGetTicket(i);
            trade.PositionClose(ticket);
        }
    }
}

/* ##################################################### Spike LATENCY ##################################################### */
datetime tradeCandleTime;
static datetime tradeTimestamp;
int tradeStartTime = (int)TimeCurrent();
int tradeCurrentTime = (int)TimeCurrent();
enum tradeLatency { ZEROLATENCY, TIMELATENCY, TIMEFRAMELATENCY };

input group                                         "============ Latency Settings ===============";
input tradeLatency                                  expertLatency = ZEROLATENCY; // Trade Latency
input int                                           expertLatencyTime = 50; // Time to trade
input ENUM_TIMEFRAMES                               expertLatencyTimeFrame = PERIOD_M1; // Timeframe

bool spikeLatency()
{
    tradeCurrentTime = (int)TimeCurrent();
    tradeCandleTime = iTime(Symbol(), expertLatencyTimeFrame, 0);
    if(expertLatency == ZEROLATENCY) {
        return true;
    }
    if(expertLatency == TIMELATENCY) {
        if(tradeCurrentTime - tradeStartTime >= expertLatencyTime) { 
            tradeStartTime = tradeCurrentTime;
            return true;
        }
    }
    if(expertLatency == TIMEFRAMELATENCY)
    {
        if(tradeTimestamp != tradeCandleTime) {
            tradeTimestamp = tradeCandleTime;
            return true;
        }
    }
    return false;
}


// /* ##################################################### QQE Filter Settings ##################################################### */
// input group                                         "============  QQE Filter Settings ===============";
// input bool                                          useQQEFilter = false; // Use QQE Filter
// input int                                           qqeFilterPeriod = 14; // QQE Period
// input int                                           qqeFilterSmothing = 5; // QQE Smothing Factor
// input double                                        qqeFilterFastPeriod = 2.618; // QQE Fast Period
// input double                                        qqeFilterSlowPeriod = 4.236; // QQE Period
// input ENUM_APPLIED_PRICE                            qqeFilterPrice = PRICE_CLOSE; // QQE Price
// input ENUM_TIMEFRAMES                               qqeFilterTimeFrame = PERIOD_D1; // QQE Timeframes

// int qqeFilterHandle = iCustom(NULL, qqeFilterTimeFrame, "QQE", qqeFilterPeriod, qqeFilterSmothing, qqeFilterFastPeriod, qqeFilterSlowPeriod, qqeFilterPrice);

// bool qqe_filter_signal(marketSignal signal){
//     if(!useQQEFilter) { return true; }
//     double colorArray[];
//     ArraySetAsSeries(colorArray, true);
//     CopyBuffer(qqeFilterHandle, 3, 1, 2, colorArray);
//     // Print("FIlter Price: ", colorArray[0]);
//     if(signal == BUY && colorArray[0] == 1) 
//     { 
//         return true; 
//     }
//     if(signal == SELL && colorArray[0] == 2) 
//     {
//         return true; 
//     }
//     return false;
// }

