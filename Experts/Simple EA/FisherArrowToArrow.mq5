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
input group                                         "============  Scalp Settings ===============";
input bool                                          expertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          expertIsTakingSellTrade = false; // Take Sell Trade

void OnTick() 
{
    if(!spikeLatency()) { return ; }

    if(fisher_signal(BUY)) {
        close_all_positions();
        takeTrade(LONG);
    } 
    if(fisher_signal(SELL)) {
        close_all_positions();
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

input group                                       "============  Fisher Settings  ===============";
input bool                                         FisherFactor = true; // Use signal Fisher
input int                                          FisherPeriod = 10; // Fisher Period

bool FisherBUY = false;
bool FisherSELL = false;

int FisherHandle = iCustom(Symbol(), Period(), "Dump/Fisher", FisherPeriod);

bool fisher_signal(marketSignal signal)
{
    if(!FisherFactor) return true;
    double FisherArray[];
    ArraySetAsSeries(FisherArray, true);
    CopyBuffer(FisherHandle, 0, 0, 3, FisherArray);
    if(signal == BUY && FisherArray[0] > 0 && !FisherBUY)  { 
        FisherBUY = true;
        FisherSELL = false;
        return true; 
    }
    if(signal == SELL && FisherArray[0] < 0 && !FisherSELL) { 
        FisherBUY = false;
        FisherSELL = true;
        return true; 
    }
    return false;
}

