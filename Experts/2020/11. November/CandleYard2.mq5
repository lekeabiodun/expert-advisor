#include <Trade\Trade.mqh>
CTrade trade;

enum marketSignal{ BUY, SELL };
enum marketEntry { LONG, SHORT };
enum tradeBehaviour { REGULAR, OPPOSITE };
enum marketTrend{ BULLISH, BEARISH, SIDEWAYS };

input double                                        takeProfit = 0.0; // Take profit
input double                                        stopLoss = 0.0; // Stop loss
input double                                        lotSize = 1; // lotsize
input int                                           targetDay = 1; // Target Day

input group                                         "============  Scalp Settings ===============";
input bool                                          expertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          expertIsTakingSellTrade = false; // Take Sell Trade

void OnTick() 
{
    if(!spikeLatency()) { return ; }

    close_all_positions();

    if(iClose(Symbol(), Period(), 1440*targetDay) > iOpen(Symbol(), Period(),  1440*targetDay)) 
    {

        takeTrade(LONG);

    } else {

        takeTrade(SHORT);

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
