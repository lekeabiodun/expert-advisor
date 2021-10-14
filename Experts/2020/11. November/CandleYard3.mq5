#include <Trade\Trade.mqh>
CTrade trade;

enum marketSignal{ BUY, SELL };
enum marketEntry { LONG, SHORT };
enum tradeBehaviour { REGULAR, OPPOSITE };
enum marketTrend{ BULLISH, BEARISH, SIDEWAYS };

input double                                        takeProfit = 0.0; // Take profit
input double                                        stopLoss = 0.0; // Stop loss
input double                                        lotSize = 1; // lotsize
input int                                           sellTarget = 1; // Sell Target
input int                                           buyTarget = 1; // Buy Target
input int                                           candleRange = 1; // Candle Range

input group                                         "============  Scalp Settings ===============";
input bool                                          expertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          expertIsTakingSellTrade = false; // Take Sell Trade

int count = 0;
int buyCount = 0;
int sellCount = 0;
int maxBuyCount = 0;
int maxSellCount = 0;
int minBuyCount = candleRange;
int minSellCount = candleRange;
void OnTick() 
{
    if(!spikeLatency()) { return ; }

    close_all_positions();

    for(int i =1; i<candleRange; i++)
    {
        if(iClose(Symbol(), Period(), 1440*i) > iOpen(Symbol(), Period(),  1440*i)) 
        {
            buyCount = buyCount + 1;
        } else {
            sellCount = sellCount + 1;
        }

    }

    count = count + 1;

    maxSellCount = MathMax(sellCount, maxSellCount);
    maxBuyCount = MathMax(buyCount, maxBuyCount);

    minSellCount = MathMin(sellCount, minSellCount);
    minBuyCount = MathMin(buyCount, minBuyCount);

    Print("Candle: ", count);

    Print("Buy Count: ", buyCount);

    Print("Sell Count: ", sellCount);

    Print("Max Buy Count: ", maxBuyCount);
    
    Print("Max Sell Count: ", maxSellCount);

    Print("Min Buy Count: ", minBuyCount);
    
    Print("Min Sell Count: ", minSellCount);

    // if(buyCount >= 14  buyTarget) { takeTrade(LONG); }

    // if(sellCount == sellTarget) { takeTrade(SHORT); }

    if(buyCount >= sellTarget) { takeTrade(SHORT); }

    sellCount = 0;
    buyCount = 0;
    
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


void close_all_positions() {
    if(PositionsTotal() > 0) {
        for(int i = PositionsTotal()-1; i >= 0; i--) {
            ulong ticket = PositionGetTicket(i);
            trade.PositionClose(ticket);
        }
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
