#include <Trade\Trade.mqh>
CTrade trade;
CDealInfo m_deal;
enum ENUM_MARKET_ENTRY { MARKET_ENTRY_LONG, MARKET_ENTRY_SHORT };
enum ENUM_MARKET_SIGNAL { MARKET_SIGNAL_BUY, MARKET_SIGNAL_SELL };
enum ENUM_MARKET_DIRECTION { MARKET_DIRECTION_UP, MARKET_DIRECTION_DOWN };
enum ENUM_EXPERT_BEHAVIOUR { EXPERT_BEHAVIOUR_REGULAR, EXPERT_BEHAVIOUR_OPPOSITE };
enum ENUM_MARKET_TREND { MARKET_TREND_BULLISH, MARKET_TREND_BEARISH, MARKET_TREND_SIDEWAYS };

input group                                         "============  EA Settings  ===============";
input int                                           EXPERT_MAGIC = 555784; // Magic Number
input ENUM_EXPERT_BEHAVIOUR                         EXPERT_BEHAVIOUR = EXPERT_BEHAVIOUR_REGULAR; // Trading Behaviour
input group                                         "============  Money Management Settings ===============";
input double                                        InputLotSize = 1; // LotSize
input double                                        InputStopLoss = 100; // Stop loss
input double                                        InputTakeProfit = 100; // Take Profit in Pips
// input double                                        InputEntryPadding = 10; // Entry Padding in Pips
input int                                           InputMaxSpread = 10; // Max Spread to trade
input ENUM_TIMEFRAMES                               ExpertHigherTimeFrame = PERIOD_D1; // Higher Timeframe
input ENUM_TIMEFRAMES                               ExpertMiddleTimeFrame = PERIOD_H4; // Middle Timeframe
input ENUM_TIMEFRAMES                               ExpertLowerTimeFrame = PERIOD_M15; // Lower Timeframe
input group                                         "============  Scalp Settings ===============";
input bool                                          ExpertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          ExpertIsTakingSellTrade = false; // Take Sell Trade

double GapPrice;
double EntryPrice;
double TakeProfit;
double StopLoss;
bool GapLastDecision = false;

int OnInit() 
{
    Print("1 Samuel 30:8 King James Version");
    Print("And David inquired at the LORD, saying, Shall I pursue after this troop? shall I overtake them?");
    Print("And he answered him, Pursue: for thou shalt surely overtake them, and without fail recover all.");
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) 
{
    Print("1 Samuel 30:8 King James Version");
    Print("And David inquired at the LORD, saying, Shall I pursue after this troop? shall I overtake them?");
    Print("And he answered him, Pursue: for thou shalt surely overtake them, and without fail recover all.");
}


void OnTick() 
{
    
    if(!SpikeLatency()) { return; }

    if(RunAwayProfitTargetHit()) { return; }

    if(SpreadIsHigh()) { return; }

    StochasticSignal();

    if(MiddleTimeframeSignal(MARKET_ENTRY_LONG) && LowerTimeframeSignal(MARKET_ENTRY_SHORT) && HigherTimeframeSignal(MARKET_ENTRY_SHORT))
    {
        TakeTrade(MARKET_ENTRY_SHORT);
    }

    if(MiddleTimeframeSignal(MARKET_ENTRY_SHORT) && LowerTimeframeSignal(MARKET_ENTRY_LONG) && HigherTimeframeSignal(MARKET_ENTRY_LONG))
    {
        TakeTrade(MARKET_ENTRY_LONG);
    }

}

//+------------------------------------------------------------------+
//| Stochastic Function                                              |
//+------------------------------------------------------------------+
input group                                         "============  Stochastic Settings  ===============";
input int                                           StochKPeriod = 5; // % K Period
input int                                           StochDPeriod = 3; // % D Period
input int                                           StochSlowing = 3; // Slowing
input ENUM_STO_PRICE                                StochMode = STO_LOWHIGH;  // Price Field
input ENUM_MA_METHOD                                StochPrice = MODE_SMA; // Method
input int                                           StochOverBoughtLevel = 80;   // DSS Overbought Level
input int                                           StochOverSoldLevel = 20;     // DSS OverSold Level

bool OverBoughtLevelCrossDown     = false;
bool OverBoughtLevelCrossUp       = false;
bool OverSoldLevelCrossDown       = false;
bool OverSoldLevelCrossUp         = false;

int StochasticHandle = iStochastic(Symbol(), ExpertMiddleTimeFrame, StochKPeriod, StochDPeriod, StochSlowing, StochPrice, StochMode);

bool StochasticSignal()
{
    if(!StochasticLatency()) { return false; }

    double KArray[];

    ArraySetAsSeries(KArray, true);

    CopyBuffer(StochasticHandle, 0, 0, 3, KArray);
    
    double StochValue0 = KArray[0];
    double StochValue1 = KArray[1];

    if(StochValue0 > StochOverSoldLevel && StochValue1 < StochOverSoldLevel) 
    { 
        OverBoughtLevelCrossDown = false;
        OverBoughtLevelCrossUp = false;

        OverSoldLevelCrossUp = true;
        OverSoldLevelCrossDown = false;
    }

    if(StochValue0 < StochOverSoldLevel && StochValue1 > StochOverSoldLevel) 
    { 
        OverBoughtLevelCrossDown = false;
        OverBoughtLevelCrossUp = false;

        OverSoldLevelCrossDown = true;
        OverSoldLevelCrossUp = false;
    }

    if(StochValue0 < StochOverBoughtLevel && StochValue1 > StochOverBoughtLevel) 
    { 
        OverBoughtLevelCrossDown = true;
        OverBoughtLevelCrossUp = false;

        OverSoldLevelCrossUp = false;
        OverSoldLevelCrossDown = false;
    }

    if(StochValue0 > StochOverBoughtLevel && StochValue1 < StochOverBoughtLevel) 
    { 
        OverBoughtLevelCrossUp = true;
        OverBoughtLevelCrossDown = false;

        OverSoldLevelCrossUp = false;
        OverSoldLevelCrossDown = false;
    }

    return false;
}

//+------------------------------------------------------------------+
//| QQE function                                                     |
//+------------------------------------------------------------------+
input group                                         "============  QQE Settings ===============";
input int                                           qqePeriod = 14; // QQE Period
input int                                           qqeSmothing = 5; // QQE Smothing Factor
input double                                        qqeFastPeriod = 2.618; // QQE Fast Period
input double                                        qqeSlowPeriod = 4.236; // QQE Slow Period
input ENUM_APPLIED_PRICE                            qqePrice = PRICE_CLOSE; // QQE Price

int qqeHandle = iCustom(NULL, ExpertLowerTimeFrame, "QQE", qqePeriod, qqeSmothing, qqeFastPeriod, qqeSlowPeriod, qqePrice);

bool MABUY = false;
bool MASELL = false;

bool QQE(ENUM_MARKET_ENTRY Signal) 
{
    double fastArray[], slowArray[], qqeArray[], colorArray[];

    ArraySetAsSeries(fastArray, true);
    ArraySetAsSeries(slowArray, true);
    ArraySetAsSeries(qqeArray, true);
    ArraySetAsSeries(colorArray, true);

    CopyBuffer(qqeHandle, 0, 0, 3, fastArray);
    CopyBuffer(qqeHandle, 1, 0, 3, slowArray);
    CopyBuffer(qqeHandle, 2, 0, 3, qqeArray);
    CopyBuffer(qqeHandle, 3, 0, 3, colorArray);

    // if(Signal == MARKET_ENTRY_LONG && colorArray[1] == 2 && colorArray[0] == 1 && !MABUY) 
    // if(Signal == MARKET_ENTRY_LONG && colorArray[0] == 1 && !MABUY) 
    if(Signal == MARKET_ENTRY_LONG && qqeArray[1] < slowArray[1] && qqeArray[0] > slowArray[0] && !MABUY) 
    // if(Signal == MARKET_ENTRY_LONG && qqeArray[1] < slowArray[1] && qqeArray[0] > slowArray[0]) 
    { 
        MABUY = true;
        MASELL = false;
        return true; 
    }
    
    // if(Signal == MARKET_ENTRY_SHORT && colorArray[1] == 1 && colorArray[0] == 2 && !MASELL) 
    // if(Signal == MARKET_ENTRY_SHORT && colorArray[0] == 2 && !MASELL) 
    if(Signal == MARKET_ENTRY_SHORT && qqeArray[1] > slowArray[1] && qqeArray[0] < slowArray[0] && !MASELL) 
    // if(Signal == MARKET_ENTRY_SHORT && qqeArray[1] > slowArray[1] && qqeArray[0] < slowArray[0]) 
    { 
        MABUY = false;
        MASELL = true;
        return true; 
    }
    
    // if(colorArray[0] == 1) { MASELL = false; }

    // if(colorArray[0] == 2) { MABUY = false; }

    return false;
}

void TakeTrade(ENUM_MARKET_ENTRY Entry) 
{
    if(EXPERT_BEHAVIOUR == EXPERT_BEHAVIOUR_OPPOSITE) 
    {
        if(Entry == MARKET_ENTRY_LONG) 
        {
            Entry = MARKET_ENTRY_SHORT;
        } 
        else if(Entry == MARKET_ENTRY_SHORT)
        {
            Entry = MARKET_ENTRY_LONG;
        }
    }

    if(Entry == MARKET_ENTRY_LONG && ExpertIsTakingBuyTrade) 
    {
        double ask                             = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        double sl                              = NormalizeDouble(ask - (InputStopLoss / MathPow(10, _Digits)), _Digits);
        double tp                              = NormalizeDouble(ask + (InputTakeProfit / MathPow(10, _Digits)), _Digits);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Buy(InputLotSize, Symbol(), ask, sl, tp);
    }

    if(Entry == MARKET_ENTRY_SHORT && ExpertIsTakingSellTrade) 
    {
        double bid                              = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        double sl                               = NormalizeDouble(bid + (InputStopLoss / MathPow(10, _Digits)), _Digits);
        double tp                               = NormalizeDouble(bid - (InputTakeProfit / MathPow(10, _Digits)), _Digits);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Sell(InputLotSize, Symbol(), bid, sl, tp);
    }

}

//+------------------------------------------------------------------+
//| Spike Latency function                                           |
//+------------------------------------------------------------------+
input group                                         "===================== Latency Settings =====================";
input bool                                          UseSpikeLatency = false; // Use Spike Latency
input ENUM_TIMEFRAMES                               ExpertLatencyTimeFrame = PERIOD_CURRENT; // Timeframe

datetime tradeCandleTime;
static datetime tradeTimestamp;

bool SpikeLatency()
{
    if(!UseSpikeLatency) { return true; }

    tradeCandleTime = iTime(Symbol(), ExpertLatencyTimeFrame, 0);
    
    if(tradeTimestamp != tradeCandleTime) 
    {

        tradeTimestamp = tradeCandleTime;

        return true;
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

//+------------------------------------------------------------------+
//| Run Away function                                                |
//+------------------------------------------------------------------+
input group                                         "============  Run Away Profit Settings ===============";
input bool                                          ExpertIsUsingRunAwayProfitTarget = false; // Use Run Away Profit Target
input ENUM_TIMEFRAMES                               runAwayProfitFrequency = PERIOD_D1; // Frequency
input int                                           runAwayProfitTarget = 15; // Profit Target
input int                                           maxTradeTarget = 4; // Max Trade Target

datetime runAwayCandleTime = iTime(Symbol(), runAwayProfitFrequency, 0);

int profitPeriod = 0;
int tradePeriod = 0;
int lossPeriod = 0;
bool RunAwayProfitTargetHit()
{
    if(!ExpertIsUsingRunAwayProfitTarget) { return false; }

    datetime freq = iTime(Symbol(), runAwayProfitFrequency, 0);

    if(freq != runAwayCandleTime) {
        runAwayCandleTime = freq;
        profitPeriod = 0;
        lossPeriod = 0;
        tradePeriod = 0;
        return false;
    }

    if(profitPeriod >= runAwayProfitTarget) { 
        close_all_positions(); 
        return true; 
    }

    if(tradePeriod >= maxTradeTarget) { 
        return true; 
    }
    
    
    return false;
}

//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans, const MqlTradeRequest& request, const MqlTradeResult& result) {

    ENUM_TRADE_TRANSACTION_TYPE type=trans.type;

    if(type==TRADE_TRANSACTION_DEAL_ADD)
    {
        if(HistoryDealSelect(trans.deal)) {
            m_deal.Ticket(trans.deal);
        }
        else {
            Print(__FILE__," ",__FUNCTION__,", ERROR: HistoryDealSelect(",trans.deal,")");
            return;
        }
        //---
        long reason=-1;
        if(!m_deal.InfoInteger(DEAL_REASON,reason))
        {
            Print(__FILE__," ",__FUNCTION__,", ERROR: InfoInteger(DEAL_REASON,reason)");
            return;
        }
        if((ENUM_DEAL_REASON)reason==DEAL_REASON_SL) {

        }
        else {
            if((ENUM_DEAL_REASON)reason==DEAL_REASON_TP) {

            }
        }
        if(m_deal.Entry() == DEAL_ENTRY_IN)
        {

            tradePeriod = tradePeriod + 1;
            
        }
    }
}

bool SpreadIsHigh()
{
    double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
    double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
    double spread = (MathMax(ask, bid) - MathMin(bid, ask)) * MathPow(10, _Digits);

    if(spread > InputMaxSpread) 
    {
        return true;
    }

    return false;
}

//+------------------------------------------------------------------+
//| HigherTimeframeSignal Function                                   |
//+------------------------------------------------------------------+
bool HigherTimeframeSignal(ENUM_MARKET_ENTRY Signal)
{
    if(Signal == MARKET_ENTRY_SHORT && iClose(Symbol(), ExpertHigherTimeFrame, 1) < iOpen(Symbol(), ExpertHigherTimeFrame, 1))
    {
        return true;
    }

    if(Signal == MARKET_ENTRY_LONG && iClose(Symbol(), ExpertHigherTimeFrame, 1) > iOpen(Symbol(), ExpertHigherTimeFrame, 1))
    {
        return true;
    }
    
    return false;
}


//+------------------------------------------------------------------+
//| Stochastic Latency function                                      |
//+------------------------------------------------------------------+
input group                                         "===================== Stochastic Latency Settings =====================";
input bool                                          UseStochasticLatency = false; // Use Stochastic Latency
input ENUM_TIMEFRAMES                               StochasticLatencyTimeFrame = PERIOD_CURRENT; // Stochastic Timeframe

datetime StochasticTradeCandleTime;

static datetime StochasticTradeTimestamp;

bool StochasticLatency()
{
    if(!UseStochasticLatency) { return true; }

    StochasticTradeCandleTime = iTime(Symbol(), StochasticLatencyTimeFrame, 0);
    
    if(StochasticTradeTimestamp != StochasticTradeCandleTime) 
    {

        StochasticTradeTimestamp = StochasticTradeCandleTime;

        return true;
    }

    return false;
}

//+------------------------------------------------------------------+
//| MiddleTimeframeSignal function                                        |
//+------------------------------------------------------------------+
bool MiddleTimeframeSignal(ENUM_MARKET_ENTRY Signal)
{

    if(Signal == MARKET_ENTRY_SHORT && (OverBoughtLevelCrossDown || OverSoldLevelCrossDown))
    {
        return true;
    }

    if(Signal == MARKET_ENTRY_LONG && (OverBoughtLevelCrossUp || OverSoldLevelCrossUp))
    {
        return true;
    }

    return false;
}

//+------------------------------------------------------------------+
//| LowerTimeframeSignal function                                    |
//+------------------------------------------------------------------+
bool LowerTimeframeSignal(ENUM_MARKET_ENTRY Signal)
{
    // Print("LowerTimeFrame");

    if(Signal == MARKET_ENTRY_SHORT && QQE(MARKET_ENTRY_SHORT))
    {
        return true;
    }

    if(Signal == MARKET_ENTRY_LONG && QQE(MARKET_ENTRY_LONG))
    {
        return true;
    }

    return false;
}

