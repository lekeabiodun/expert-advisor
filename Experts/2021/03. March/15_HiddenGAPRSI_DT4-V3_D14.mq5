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
input double                                        LotSize = 1; // LotSize
input double                                        InputStopLoss = 100; // Stop loss
input double                                        InputTakeProfit = 100; // Take Profit in Pips
input double                                        EntryPadding = 10; // Entry Padding in Pips
input int                                           MinimalSpread = 10; // Minimal Spread to trade
input ENUM_TIMEFRAMES                               ExpertHigherTimeFrame = PERIOD_CURRENT; // Higher Timeframe
input ENUM_TIMEFRAMES                               ExpertLowerTimeFrame = PERIOD_CURRENT; // Lower Timeframe
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
    EventSetTimer(RSIResetter*60);
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) 
{
    Print("1 Samuel 30:8 King James Version");
    Print("And David inquired at the LORD, saying, Shall I pursue after this troop? shall I overtake them?");
    Print("And he answered him, Pursue: for thou shalt surely overtake them, and without fail recover all.");
    EventKillTimer();
}


void OnTick() 
{
    if(!SpikeLatency()) { return ; }

    if(runAwayProfitManager()) { return ; }

    double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
    double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
    double spread = (MathMax(ask, bid) - MathMin(bid, ask)) * MathPow(10, _Digits);

    if(spread > MinimalSpread) { return; }

    FindNewGAP();    

    if(iOpen(Symbol(), ExpertHigherTimeFrame, 0) < GapPrice)
    {

        if(RSI(MARKET_SIGNAL_SELL) && FindNewGAP())
        {
            TakeTrade(MARKET_ENTRY_SHORT);
        } 

    }

    if(iOpen(Symbol(), ExpertHigherTimeFrame, 0) > GapPrice)
    {

        if(RSI(MARKET_SIGNAL_BUY) && FindNewGAP())
        {
            TakeTrade(MARKET_ENTRY_LONG);
        }

    }

}

//+------------------------------------------------------------------+
//| RSI function                                        |
//+------------------------------------------------------------------+
input group                                       "============  RSI Settings  ===============";
input int                                          RSIPeriod = 9; // RSI Period
input ENUM_APPLIED_PRICE                           RSIAppliedPrice = PRICE_CLOSE; // RSI Applied Price
input int                                          RSIOverSoldLevel = 20; // RSI Oversold Level
input int                                          RSIOverBoughtLevel = 80; // RSI Overbought Level
input int                                          RSIResetter = 480;         // DSS Reset Timer in minutes

int RSIHandle = iRSI(Symbol(), ExpertLowerTimeFrame, RSIPeriod, RSIAppliedPrice);

bool UnlockBUY = true;
bool UnlockSELL = true;

bool RSI(ENUM_MARKET_SIGNAL Signal) 
{
    double RSIArray[];
    ArraySetAsSeries(RSIArray, true);
    CopyBuffer(RSIHandle, 0, 0, 23, RSIArray);
    double RSIValue0 = RSIArray[0];
    double RSIValue1 = RSIArray[1];

    if(Signal == MARKET_SIGNAL_BUY && RSIValue0 > RSIOverSoldLevel && RSIValue1 < RSIOverSoldLevel && UnlockBUY) 
    { 
        UnlockSELL = true;
        UnlockBUY = false;

        return true; 
    }
    if(Signal == MARKET_SIGNAL_SELL && RSIValue0 < RSIOverBoughtLevel && RSIValue1 > RSIOverBoughtLevel && UnlockSELL) 
    { 
        UnlockBUY = true;
        UnlockSELL = false;

        return true; 
    }
    return false;
}

input group                                         "============  WRB Hidden Gap Settings  ===============";
input bool                                          UseWholeBars = 3;                // UseWholeBars
input int                                           WRB_LookBackBarCount = 3;        // WRB_LookBackBarCount
input int                                           WRB_WingDingsSymbol = 115;       // WRB_WingDingsSymbol
input color                                         HGColor1 = clrDodgerBlue;        // HGColor1
input color                                         HGColor2 = clrBlue;              // HGColor2
input ENUM_LINE_STYLE                               HGStyle = STYLE_SOLID;           //HGStyle
input int                                           StartCalculationFromBar = 100;   // StartCalculationFromBar
input bool                                          HollowBoxes = false;             // HollowBoxes
input bool                                          DoAlerts = false;                //DoAlerts

int GapHandle = iCustom(NULL, ExpertHigherTimeFrame, "HiddenGap", UseWholeBars, WRB_LookBackBarCount, WRB_WingDingsSymbol, HGColor1, HGColor2, HGStyle, StartCalculationFromBar, HollowBoxes, DoAlerts);

int FindNewGAP()
{
    if(!SpikeLatencyGAP()) { return GapLastDecision; }

    double Array1[];

    ArraySetAsSeries(Array1, true);

    CopyBuffer(GapHandle, 0, 1, 2, Array1);

    GapPrice = Array1[0];

    if(Array1[0] != EMPTY_VALUE)
    {
        GapLastDecision = true;

        return true;
    }

    GapLastDecision = false;

    return false;

}

/* ##################################################### GAP Spike LATENCY ##################################################### */
input group                                         "===================== GAP Latency Settings =====================";
input bool                                          UseSpikeLatencyGAP = false; // Use Spike Latency
input ENUM_TIMEFRAMES                               ExpertLatencyTimeFrameGAP = PERIOD_CURRENT; // Timeframe

datetime tradeCandleTimeGAP;
static datetime tradeTimestampGAP;

bool SpikeLatencyGAP()
{
    if(!UseSpikeLatencyGAP) { return true; }

    tradeCandleTimeGAP = iTime(Symbol(), ExpertLatencyTimeFrameGAP, 0);
    
    if(tradeTimestampGAP != tradeCandleTimeGAP) 
    {

        tradeTimestampGAP = tradeCandleTimeGAP;

        return true;
    }

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
        trade.Buy(LotSize, Symbol(), ask, sl, tp);
    }

    if(Entry == MARKET_ENTRY_SHORT && ExpertIsTakingSellTrade) 
    {
        double bid                              = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        double sl                               = NormalizeDouble(bid + (InputStopLoss / MathPow(10, _Digits)), _Digits);
        double tp                               = NormalizeDouble(bid - (InputTakeProfit / MathPow(10, _Digits)), _Digits);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Sell(LotSize, Symbol(), bid, sl, tp);
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
//| Run Away function                                        |
//+------------------------------------------------------------------+
input group                                         "============  Run Away Profit Settings ===============";
input bool                                          ExpertIsUsingRunAwayProfitTarget = false; // Use Run Away Profit Target
input ENUM_TIMEFRAMES                               runAwayProfitFrequency = PERIOD_D1; // Frequency
input int                                           runAwayProfitTarget = 15; // Profit Target
input int                                           maxTradeTarget = 4; // Max Trade Target
datetime runAwayCandleTime = iTime(Symbol(), runAwayProfitFrequency, 0);

int profitPeriod = 0;
int lossPeriod = 0;
int tradePeriod = 0;
bool runAwayProfitManager()
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
//| OnTimer function                                        |
//+------------------------------------------------------------------+
void OnTimer() 
{
    UnlockBUY = true;
    UnlockSELL = true;
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

