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

    if(cci_signal(BUY)) {
        close_all_positions();
        takeTrade(LONG);
    } 
    if(cci_signal(SELL)) {
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

input group                                       "============  Commondity Channel Index Settings  ===============";
input bool                                         cciFactor = true; // Use CCI 
input int                                          cciPeriod = 100; // CCI Period
input ENUM_APPLIED_PRICE                           cciAppliedPrice = PRICE_CLOSE; // CCI Applied Price
input int                                          cciOverBoughtLevel = 100; // CCI Overbought Level
input int                                          cciOverSoldLevel = -100; // CCI OverSold Level

bool cciSignalBuy = false;
bool cciSignalSell = false;

bool cciOverSoldSignalCrossUp = false;
bool cciOverSoldSignalCrossDown = false;

bool cciOverBoughtSignalCrossUp = false;
bool cciOverBoughtSignalCrossDown = false;

bool cciComingFromOverbought = false;
bool cciComingFromOversold = false;

bool cci_signal(marketSignal signal){
   if(!cciFactor) return true;
   int cciHandle = iCCI(Symbol(), Period(), cciPeriod, cciAppliedPrice);
   double cciArray[];
   ArraySetAsSeries(cciArray, true);
   CopyBuffer(cciHandle, 0, 0, 3, cciArray);
   double cciValue = cciArray[0];
   if(signal == BUY && cciValue > cciOverBoughtLevel && !cciOverBoughtSignalCrossUp)
    {
        cciOverBoughtSignalCrossUp = true;
        cciOverBoughtSignalCrossDown = false;

        return true;
    }
    if(signal == BUY && cciComingFromOversold && cciValue > cciOverSoldLevel && cciValue < cciOverBoughtLevel && !cciOverSoldSignalCrossUp)
    {
        cciOverSoldSignalCrossUp = true;
        cciOverSoldSignalCrossDown = false;
        
        cciComingFromOversold = false;
        cciComingFromOverbought = false;

        return true;
    }
    if(signal == SELL && cciValue < cciOverSoldLevel && !cciOverSoldSignalCrossDown)
    {
        cciOverSoldSignalCrossUp = false;
        cciOverSoldSignalCrossDown = true;

        return true;
    }
    if(signal == SELL && cciComingFromOverbought && cciValue > cciOverSoldLevel && cciValue < cciOverBoughtLevel && !cciOverBoughtSignalCrossDown)
    {
        cciOverBoughtSignalCrossUp = false;
        cciOverBoughtSignalCrossDown = true;

        cciComingFromOversold = false;
        cciComingFromOverbought = false;

        return true;
    }
    if(cciValue < cciOverSoldLevel)
    {
        cciComingFromOversold = true;
        cciComingFromOverbought = false;
    }
    if(cciValue > cciOverBoughtLevel)
    {
        cciComingFromOversold = false;
        cciComingFromOverbought = true;
    }
    return false;
}

