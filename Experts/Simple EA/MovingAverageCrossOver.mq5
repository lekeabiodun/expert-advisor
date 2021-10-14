#include <Trade\Trade.mqh>
CTrade trade;
enum marketSignal{ BUY, SELL };
enum marketEntry { LONG, SHORT };
enum tradeBehaviour { REGULAR, OPPOSITE };
enum marketTrend{ BULLISH, BEARISH, SIDEWAYS };

input group                                        "============  EA Settings  ===============";
input ulong                                        EXPERT_MAGIC = 787878; // Magic Number
input group                                         "============  Money Management Settings ===============";
input double                                        lotSize = 1; // Lot Size
input double                                        stopLoss = 0; // Stop Loss 
input double                                        takeProfit = 0; // Take Profit 
input group                                         "============  Position Management Settings ===============";
input bool                                          closePreviousTradeOnNewSignal = true; // Close Previous Trade on New Signal
input bool                                          closeOppositeTradeOnOppositeSignal = true; // Close Opposite Trade on Opposite Signal
input group                                         "============  Scalp Settings ===============";
input bool                                          expertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          expertIsTakingSellTrade = false; // Take Sell Trade

void OnTick() 
{
    if(!spikeLatency()) { return ; }

    tradeManager();

    if(ma_signal(BUY)) {
        if(closePreviousTradeOnNewSignal){ close_all_positions(); }
        takeTrade(LONG);
    } 
    else if(ma_signal(SELL)) { 
        if(closePreviousTradeOnNewSignal){ close_all_positions(); }
        takeTrade(SHORT);

    }
}

void takeTrade(marketEntry entry) {      
   if(entry == LONG && expertIsTakingBuyTrade) {
        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Buy(lotSize, Symbol(), ask, 0, 0);
   }
   if(entry == SHORT && expertIsTakingSellTrade) {
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
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

void tradeManager() {
    for(int i = PositionsTotal()-1; i >= 0; i--) {
        PositionGetSymbol(i);
        if(takeProfit && (PositionGetDouble(POSITION_PROFIT) / lotSize) >= takeProfit) {
            ulong ticket = PositionGetTicket(i);
            trade.PositionClose(ticket);
        }
        if(stopLoss && ( PositionGetDouble(POSITION_PROFIT) / lotSize ) <= -stopLoss) {
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

/* ##################################################### Moving Average Signal ##################################################### */
input group                                       "============  Moving Average Settings  ===============";
input bool                                         useMASignal = true; // Use Moving Average Signal
input ENUM_TIMEFRAMES                              MATimeFrame = PERIOD_M1; // Moving Average Timeframe
input int                                          fastMA = 1; // Fast Moving Average
input int                                          fastMAShift = 0; // Fast Moving Average Shift
input ENUM_MA_METHOD                               fastMAMethod = MODE_LWMA; // Fast Moving Average Method
input ENUM_APPLIED_PRICE                           fastMAAppliedPrice = PRICE_CLOSE; // Fast Moving Average Applied Price
input int                                          slowMA = 50; // Slow Moving Average
input int                                          slowMAShift = 0; // SLow Moving Average Shift
input ENUM_MA_METHOD                               slowMAMethod = MODE_LWMA; // Slow Moving Average Method
input ENUM_APPLIED_PRICE                           slowMAAppliedPrice = PRICE_LOW; // Slow Moving Average Applied Price
bool MABUY = false;
bool MASELL = false;
int FastMovingAverageHandle = iMA(_Symbol, MATimeFrame, fastMA, fastMAShift, fastMAMethod, fastMAAppliedPrice);
int SlowMovingAverageHandle = iMA(_Symbol, MATimeFrame, slowMA, slowMAShift, slowMAMethod, slowMAAppliedPrice);

bool ma_signal(marketSignal signal) {
    if(!useMASignal) { return true; }
    double FastMovingAverageArray[], SlowMovingAverageArray[];
    ArraySetAsSeries(FastMovingAverageArray, true);
    ArraySetAsSeries(SlowMovingAverageArray, true);
    CopyBuffer(FastMovingAverageHandle, 0, 0, 3, FastMovingAverageArray);
    CopyBuffer(SlowMovingAverageHandle, 0, 0, 3, SlowMovingAverageArray);
    if(signal == BUY && FastMovingAverageArray[0] > SlowMovingAverageArray[0] && !MABUY) {
        if(MASELL && closeOppositeTradeOnOppositeSignal) { 
            close_all_positions(); 
        }
        MABUY = true;
        MASELL = false;
        return true; 
    } 
    if(signal == SELL && FastMovingAverageArray[0] < SlowMovingAverageArray[0] && !MASELL) {
        if(MABUY && closeOppositeTradeOnOppositeSignal) { 
            close_all_positions(); 
        }
        MABUY = false;
        MASELL = true;
        return true; 
    }
    return false;
}

