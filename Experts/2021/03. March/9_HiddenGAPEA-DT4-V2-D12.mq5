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
input int                                           MinimalSpread = 10; // Minimal Spread to trade
input ENUM_TIMEFRAMES                               ExpertHigherTimeFrame = PERIOD_CURRENT; // Higher Timeframe
input ENUM_TIMEFRAMES                               ExpertLowerTimeFrame = PERIOD_CURRENT; // Lower Timeframe
input group                                         "============  Scalp Settings ===============";
input bool                                          ExpertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          ExpertIsTakingSellTrade = false; // Take Sell Trade

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

bool   GapLastDecision = false;
double GapPrice;
double TakeProfit;
double StopLoss;

void OnTick() 
{

    if(!SpikeLatency()) { return ; }

    if(runAwayProfitManager()) { return ; }

    double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
    double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
    double spread = (MathMax(ask, bid) - MathMin(bid, ask)) * MathPow(10, _Digits);

    if(spread > MinimalSpread) { return; }

    if(iOpen(Symbol(), ExpertHigherTimeFrame, 0))
    {
        Print("sell entry");

        if(DSS(MARKET_SIGNAL_SELL))
        {
            Print("sell zignal");
            TakeTrade(MARKET_ENTRY_SHORT); 
        } 
    }

    if(iOpen(Symbol(), ExpertHigherTimeFrame, 0))
    {
        Print("buy entry");

        if(DSS(MARKET_SIGNAL_BUY))
        {
            Print("buy zignal");
           
            TakeTrade(MARKET_ENTRY_LONG);
        }
    }
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

input group                                         "============  DSS Settings ===============";
input int                                           stochasticPeriod = 55;     // Stochastic Period
input int                                           smoothingPeriod = 5;       // Smoothing Period
input int                                           signalPeriod = 5;          // Signal Period
input ENUM_APPLIED_PRICE                            DSSPrice = PRICE_CLOSE;    // DSS Price
input int                                           DSSOverBoughtLevel = 80;   // DSS Overbought Level
input int                                           DSSOverSoldLevel = 20;     // DSS OverSold Level

int DSSHandle = iCustom(NULL, ExpertLowerTimeFrame, "DSS", stochasticPeriod, smoothingPeriod, signalPeriod, DSSPrice);

bool MABUY = false;
bool MASELL = false;

bool DSS(ENUM_MARKET_SIGNAL Signal) 
{
    if(!SpikeLatencyDSS()) { return false; }

   double DSSArray[];
   ArraySetAsSeries(DSSArray, true);
   CopyBuffer(DSSHandle, 0, 0, 2, DSSArray);

   if(Signal == MARKET_SIGNAL_BUY && DSSArray[0] >= DSSOverSoldLevel && DSSArray[0] < DSSOverBoughtLevel && MABUY) 
    { 
        return true; 
    }
    if(Signal == MARKET_SIGNAL_SELL && DSSArray[0] <= DSSOverBoughtLevel && DSSArray[0] > DSSOverSoldLevel && MASELL) 
    { 
        return true; 
    }

    if(DSSArray[0] < DSSOverSoldLevel)
    {
        MABUY = true;
        MASELL = false;
    }
    if(DSSArray[0] > DSSOverBoughtLevel)
    {
        MABUY = false;
        MASELL = true;
    }
   return false;
}

/* ##################################################### DSS Spike LATENCY ##################################################### */
input group                                         "===================== DSS Latency Settings =====================";
input bool                                          UseSpikeLatencyDSS = false; // Use Spike Latency
input ENUM_TIMEFRAMES                               ExpertLatencyTimeFrameDSS = PERIOD_CURRENT; // Timeframe

datetime tradeCandleTimeDSS;
static datetime tradeTimestampDSS;

bool SpikeLatencyDSS()
{
    if(!UseSpikeLatencyDSS) { return true; }

    tradeCandleTimeDSS = iTime(Symbol(), ExpertLatencyTimeFrameDSS, 0);
    
    if(tradeTimestampDSS != tradeCandleTimeDSS) 
    {

        tradeTimestampDSS = tradeCandleTimeDSS;

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
        double ask                              = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        double sl                                = NormalizeDouble(ask - (InputStopLoss / MathPow(10, _Digits)), _Digits);
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

/* ##################################################### Spike LATENCY ##################################################### */
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


/* ##################################################### Run Away Profit ##################################################### */
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

            // Print("TP HIT");

        }
        else {
            if((ENUM_DEAL_REASON)reason==DEAL_REASON_TP) {

                // close_all_orders();
                // close_all_positions();


            }
        }
        if(m_deal.Entry() == DEAL_ENTRY_IN)
        {

            tradePeriod = tradePeriod + 1;
            
        }
    }
}

