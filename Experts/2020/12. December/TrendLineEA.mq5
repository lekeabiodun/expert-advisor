#include <Trade\Trade.mqh>
CTrade trade;
enum ENUM_MARKET_ENTRY { MARKET_ENTRY_LONG, MARKET_ENTRY_SHORT };
enum ENUM_MARKET_SIGNAL { MARKET_SIGNAL_BUY, MARKET_SIGNAL_SELL };
enum ENUM_MARKET_DIRECTION { MARKET_DIRECTION_UP, MARKET_DIRECTION_DOWN };
enum ENUM_EXPERT_BEHAVIOUR { EXPERT_BEHAVIOUR_REGULAR, EXPERT_BEHAVIOUR_OPPOSITE };
enum ENUM_MARKET_TREND { MARKET_TREND_BULLISH, MARKET_TREND_BEARISH, MARKET_TREND_SIDEWAYS };

input group                                         "============  EA Settings  ===============";
input int                                           EXPERT_MAGIC = 555784; // Magic Number
input ENUM_EXPERT_BEHAVIOUR                         EXPERT_BEHAVIOUR = EXPERT_BEHAVIOUR_REGULAR; // Trading Behaviour
input group                                         "============  Money Management Settings ===============";
input double                                        LotSize = 1; // Lot Size
input double                                        StopLoss = 0.0; // Stop Loss in Pips
input double                                        TakeProfit = 0.0; // Take Profit in Pips
input group                                         "============  Scalp Settings ===============";
input bool                                          ExpertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          ExpertIsTakingSellTrade = false; // Take Sell Trade

/*
NAME
Trend Line Trader.
DESCRIPTION
Expert Advisor is design to trade trend lines.

EXAMPLE
If market is fast approaching trend line
the expert advisor wait for a touch or a break
to make decision.

BEGIN
Current Price;
IF
Price Touch/Break Up Trend Line;
THEN
Buy
IF
Price Touch/Break Down Trend Line;
THEN
Seell
END

*/

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
    // if(!SpikeLatency()) { return ; }
    if(TrendLineSignal(MARKET_DIRECTION_UP))
    {
        Comment("UP");
    }
    
    if(TrendLineSignal(MARKET_DIRECTION_DOWN))
    {
        Comment("DOWN");
    }
    
}



input group                                         "============  Trendline Settings ===============";
// input int                                           qqePeriod = 14; // QQE Period
// input int                                           qqeSmothing = 5; // QQE Smothing Factor
// input double                                        qqeFastPeriod = 2.618; // QQE Fast Period
// input double                                        qqeSlowPeriod = 4.236; // QQE Period
// input ENUM_APPLIED_PRICE                            qqePrice = PRICE_CLOSE; // QQE Price

int TrendlineHandle = iCustom(NULL, 0, "autotrendlines");

bool MABUY = false;
bool MASELL = false;

bool TrendLineSignal(ENUM_MARKET_DIRECTION MARKET_DIRECTION)
{
    double fastArray[], slowArray[], qqeArray[], colorArray[];
    ArraySetAsSeries(fastArray, true);
    ArraySetAsSeries(slowArray, true);
    ArraySetAsSeries(qqeArray, true);
    ArraySetAsSeries(colorArray, true);
    CopyBuffer(TrendlineHandle, 0, 0, 3, fastArray);
    CopyBuffer(TrendlineHandle, 1, 0, 3, slowArray);
    CopyBuffer(TrendlineHandle, 2, 0, 3, qqeArray);
    CopyBuffer(TrendlineHandle, 3, 0, 3, colorArray);

    Print("QQE fast 0: ", fastArray[0], " QQE fast 1: ", fastArray[1]);
    Print("QQE 0: ", qqeArray[0], " QQE 1: ", qqeArray[1], " QQE 2: ", qqeArray[2]);
    Print("QQE slow 0: ", slowArray[0], " QQE slow 1: ", slowArray[1], " QQE slow 2: ", slowArray[2]);
    Print("QQE color 0: ", colorArray[0], " QQE color 1: ", colorArray[1]);
    Print("QQE 0: ", colorArray[0]);
    Print("QQE 1: ", colorArray[1]);

    // if(signal == BUY && qqeArray[1] < slowArray[1] && qqeArray[0] > slowArray[0] && !MABUY) 
    // { 
    //     MABUY = true;
    //     MASELL = false;
    //     return true; 
    // }

    // if(signal == SELL && qqeArray[1] > slowArray[1] && qqeArray[0] < slowArray[0] && !MASELL) 
    // { 
    //     MABUY = false;
    //     MASELL = true;
    //     return true; 
    // }
    return false;
}


void TakeTrade(ENUM_MARKET_ENTRY Entry) {

    if(Entry == MARKET_ENTRY_LONG && ExpertIsTakingBuyTrade && ExpertAllows(POSITION_TYPE_BUY)) {
        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        trade.Buy(LotSize, Symbol(), ask, 0, 0);
    }

    if(Entry == MARKET_ENTRY_SHORT && ExpertIsTakingSellTrade && ExpertAllows(POSITION_TYPE_SELL)) {
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        trade.Sell(LotSize, Symbol(), bid, 0, 0);
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

bool SpikeLatency()
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

void close_all_positions() {
    if(PositionsTotal() > 0) {
        for(int i = PositionsTotal()-1; i >= 0; i--) {
            ulong ticket = PositionGetTicket(i);
            trade.PositionClose(ticket);
        }
    }
}

void close_all_orders() {
    if(OrdersTotal() > 0) {
        for(int i=0; i < OrdersTotal()-1; i++) {
             ulong ticket = OrderGetTicket(i);
             trade.OrderDelete(ticket);
        }
    }
}


bool ExpertAllows(ENUM_POSITION_TYPE PositionType) 
{
    bool result = true;

    if(!PositionsTotal()) { return true; }

    for(int i = PositionsTotal()-1; i >= 0; i--) {
        PositionGetSymbol(i);
        if(PositionGetInteger(POSITION_TYPE) == PositionType) { 
            result = false; 
        }
    }

    return result;
}

